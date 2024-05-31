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
    mapping(address => uint256) ethLiquidationPrice;
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
        /// To Be Deleted
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
        /// To Be Deleted
        ETHUSD = _ETHUSD;
        minimumCollateralizationRatio = _minimumCollateralizationRatio;
        liquidation_ratio = _liquidation_ratio;
        liqudateFeePercent = _liqudateFeePercent;
        rmaAdmin = msg.sender;
    }

    /**
     * @dev Mints stablecoins by sending ETH as collateral.
     * @notice This function allows users to mint stablecoins by depositing ETH.
     * It calculates the amount of stablecoins to mint and new liquidation price.
     * @return the new(or updated) liquidatePrice of the user.
     */
    function mintByEth() public payable returns (uint256) {
        require(
            msg.value > 0,
            "StableCoin: you have to send ETH to mint Stable Coin"
        );

        uint256 weiAmount = msg.value;

        /// Get latest ETH/USD price using chainlink datafeed.
        uint256 latestETHUSD = uint256(getLatestETHUSD());

        /// Update `ETHUSD`
        ETHUSD = latestETHUSD;

        /// Truncate the decimals
        uint256 truncateETHUSD = truncateETHUSDDecimals(ETHUSD);

        uint256 weiToUsd = ((weiAmount * truncateETHUSD) / 1e18);

        /// Calculate the amount of stable coin to mint
        /// based on `minimumCollateralizationRatio`
        uint256 amountToMint = (weiToUsd * 100) / minimumCollateralizationRatio;

        /// Set the `liquidatePrice` of user.
        uint256 liquidatePrice = (truncateETHUSD * 100) / liquidation_ratio;

        /// @dev If user has minted stablecoin already,
        /// `liquidatePrice` MUST be recalculated again.
        if (userCollateralWei[msg.sender] > 0) {
            uint256 collateral = userCollateralWei[msg.sender];

            /// Recalculate liquidation price based on existing and new collateral
            liquidatePrice =
                ((collateral * ethLiquidationPrice[msg.sender]) +
                    (weiAmount * liquidatePrice)) /
                (collateral + weiAmount);
        }

        /// Update all data involved.
        participantAddresses.push(msg.sender);
        ethLiquidationPrice[msg.sender] = liquidatePrice;
        userCollateralWei[msg.sender] += msg.value;
        mintedStablecoins[msg.sender] += amountToMint;

        // Mint Stablecoin to user.
        _mint(msg.sender, amountToMint);

        return liquidatePrice;
    }

    /**
     * @dev You MUST target `autoEthLiqudate` for chainlink automation.
     * Since there is currently no available service to `sell collateral`,
     * we proceed with the assumption that it is sold at its current value.
     *
     * @notice This function gets the latest ETH/USD price, and iterates through
     * the collateral liquidation prices of users who minted stable coins,
     * and liquidates the collateral for those who `liquidation price` > ETH/USD price.
     * After collateral liquidation, debt repayment, and fee deduction,
     * the remaining balance is returned to the user in ETH.
     *
     */
    function autoEthLiqudate() public payable returns (bool) {
        /// `getLatestETHUSD()` and Truncate the decimals
        uint256 latestETHUSD = truncateETHUSDDecimals(
            uint256(getLatestETHUSD())
        );

        /// Iterate over users who have participated
        /// (who have Deposit Collateral and Issued Stablecoins)
        for (uint256 i = 0; i < participantAddresses.length; i++) {
            /// If `ethLiquidationPrice` of user is higher than `latestETHUSD`,
            /// Liquidation begins.
            if (ethLiquidationPrice[participantAddresses[i]] > latestETHUSD) {
                address payable user = payable(participantAddresses[i]);

                /// Current value($) of the collateralized Wei deposited by the user
                uint256 currentCollateralValue = (userCollateralWei[user] *
                    latestETHUSD) / 1e18;

                /// Fee incurred during the liquidation process initiated by RMA
                /// `liquidatationFee` can be adjusted through governance.
                uint256 liquidatationFee = (currentCollateralValue *
                    liqudateFeePercent) / 100;

                /// Remaining funds after collateral liquidation are returned to the use.
                uint256 refundAmountDollar = currentCollateralValue -
                    mintedStablecoins[user] -
                    liquidatationFee;

                /// `refundAmountDollar`(dollar) => `netRefundAmoutWei`(wei)
                uint256 netRefundAmoutWei = (refundAmountDollar * 1 ether) /
                    latestETHUSD;

                /// Transfer `refundAmountWei` to User
                user.transfer(netRefundAmoutWei);

                /// Clear all data
                ethLiquidationPrice[user] = 0;
                userCollateralWei[user] = 0;

                /// Emit Event {CollateralLiquidated}
                emit CollateralLiquidated(
                    user,
                    netRefundAmoutWei,
                    "Your Collateral is liqudated and Transferred net refund"
                );
            }
        }

        return true;
    }

    /// External or Public Functions

    /**
     * @dev This function allows a user to redeem their collateral and burn the corresponding stablecoins.
     * It transfers the user's collateral back to their address, burns all stablecoins minted by the user,
     * and resets the user's collateral and stablecoin data.
     */
    function redeemCollateralAndBurn() public payable returns (bool) {
        address payable user = payable(msg.sender);

        require(
            userCollateralWei[user] > 0,
            "Stable Coin : No Collateral available to redeem."
        );

        uint256 collateralAmount = userCollateralWei[user];

        /// Redeem Collateral ETH to User
        user.transfer(collateralAmount);

        /// Burn all Stable coins User minted
        _burn(msg.sender, mintedStablecoins[user]);

        /// Reset All data
        userCollateralWei[user] = 0;
        ethLiquidationPrice[user] = 0;
        mintedStablecoins[user] = 0;

        /// Emit Event {CollateralRedeemed}
        emit CollateralRedeemed(
            user,
            collateralAmount,
            mintedStablecoins[user],
            "Collateral Redeemed and Stablecoin Burned"
        );

        return true;
    }

    /**
     * @dev This function MUST be called as a result of a governance decision.
     */
    function setLiquadation_ratio(
        uint256 _liquidation_ratio
    ) external onlyOwner returns (bool) {
        liquidation_ratio = _liquidation_ratio;
        return true;
    }

    /**
     * @dev This function MUST be called as a result of a governance decision.
     */
    function setLiqudationFeePercent(
        uint256 _liqudateFeePercent
    ) external onlyOwner returns (bool) {
        liqudateFeePercent = _liqudateFeePercent;
        return true;
    }

    /**
     * @dev This function MUST be called as a result of a governance decision.
     */
    function setMinimumCollateralizationRatio(
        uint256 _minimumCollateralizationRatio
    ) external onlyOwner returns (bool) {
        minimumCollateralizationRatio = _minimumCollateralizationRatio;
        return true;
    }

    /// To Be Deleted... For Test Only
    function setETHUSD(uint256 _ETHUSD) public returns (uint256) {
        ETHUSD = _ETHUSD;
        return ETHUSD;
    }

    receive() external payable {}

    fallback() external payable {}

    /// Internal or Private Functions

    /// View or Pure Functions

    /**
     * @dev This function truncates the ETH/USD price to remove the 8 decimal places.
     * This is necessary because the Chainlink Data Feed returns the value with 8 decimal places,
     * and this function converts it to an uint256 for easier use.
     *
     * @param ethUsd The ETH/USD price with 8 decimal places from the Chainlink Data Feed.
     * @return the truncated ETH/USD price as an uint256.
     */
    function truncateETHUSDDecimals(
        uint256 ethUsd
    ) public pure returns (uint256) {
        return ethUsd / 1e8;
    }

    /**
     * @notice This function calls contract for getting latest ETH/USD price provided by chainlink datafeed.
     * @dev BE AWARE that the returned value is not an integer, but a value with 8 decimal places.
     * @return an integer value scaled to 8 decimal places
     */
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

    /**
     * @notice total collateral value in dollar SHOULD be same amount as minted stable coins.
     * HOWEVER, there is currently no service to sell collateral, we leave it as it is.
     * So total collateral value might be higher than minted stable coins.
     * @return the total collateral balance in wei.
     */
    function getTotalCollateralBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice total collateral balance in wei of each participants.
     * @return the collateral balance of the participant in wei.
     */
    function getCollateralBalance() public view returns (uint256) {
        return userCollateralWei[msg.sender];
    }

    /**
     * @return the liquidation price of the participant in dollars.
     */
    function getEthLiquidationPrice() public view returns (uint256) {
        return ethLiquidationPrice[msg.sender];
    }

    /**
     * @return the amounts of the stable coin user has minted.
     */
    function getStablecoinBalance() public view returns (uint256) {
        return mintedStablecoins[msg.sender];
    }

    /// To be Deleted.... For testOnly
    function reset() public payable returns (bool) {
        address payable tothe = payable(rmaAdmin);
        uint256 total = address(this).balance;
        tothe.transfer(total);
        return true;
    }
}
