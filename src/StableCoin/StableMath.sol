// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract StableMath {
    uint256 public minimum_collateralization_ratio;
    uint256 public liquidation_ratio;
    uint256 public ETHUSD;
    mapping(address => uint256) ethLiqudatePrice;
    mapping(address => uint256) weiValut;
    mapping(address => uint256) mintedStablecoins;
    address[] ethMintedAddress;
    uint256 public liqudateFeePercent;

    event EtherReceived(address indexed user, uint256 amount, string message);

    constructor(
        uint256 _ETHUSD,
        uint256 _minimum_collateralization_ratio,
        uint256 _liquidation_ratio,
        uint256 _liqudateFeePercent
    ) {
        ETHUSD = _ETHUSD;
        minimum_collateralization_ratio = _minimum_collateralization_ratio;
        liquidation_ratio = _liquidation_ratio;
        liqudateFeePercent = _liqudateFeePercent;
    }

    receive() external payable {}
    fallback() external payable {}

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

        // 유저에게 토큰 전송 로직

        return liqudatePrice;
    }

    function autoEthLiqudate(
        uint256 nowPrice
    ) public payable returns (uint256) {
        // 현재 가격 계산
        // 200008417972
        ETHUSD = nowPrice;
        // 2000
        uint256 truncateETHUSD = truncate(nowPrice);

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
            // stableCoin 받고
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
}
