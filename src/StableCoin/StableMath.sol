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
    uint256 immutable ETHUSD = 312608417972;
    mapping(address => uint256) ethLiqudatePrice;
    mapping(address => uint256) ethValut;
    mapping(address => uint256) mintedStablecoins;
    address[] ethMintedAddress;

    constructor(
        uint256 _minimum_collateralization_ratio,
        uint256 _liquidation_ratio
    ) {
        minimum_collateralization_ratio = _minimum_collateralization_ratio;
        liquidation_ratio = _liquidation_ratio;
    }

    receive() external payable {}
    fallback() external payable {}

    function mintByEth() public payable returns (uint256) {
        // 사전 검증

        // 청산가, 스테이블 코인 발행량 계산
        uint256 weiAmount = msg.value;
        uint256 amountToMint = (weiAmount * ETHUSD) / 1e18;
        uint256 coinAmount = amountToMint / 1e8;
        uint256 liqudatePrice = ((ETHUSD / 1e8) * 100) / liquidation_ratio;

        // 저장 : 발행인 등록, 청산가, 담보 액수, 달러 발행 액수
        ethMintedAddress.push(msg.sender);
        ethLiqudatePrice[msg.sender] = liqudatePrice;
        ethValut[msg.sender] = msg.value;
        mintedStablecoins[msg.sender] = amountToMint;

        // 유저에게 토큰 전송 로직

        return liqudatePrice;
    }

    function autoEthLiqudate() public payable returns (bool) {
        // 현재 가격 계산
        uint256 ethUsdNow = ETHUSD;

        // 전체 순회
        for (uint256 i = 0; i < ethMintedAddress.length; i++) {
            // 청산가가 현재 가격보다 높으면 청산
            if (ethLiqudatePrice[ethMintedAddress[i]] > ethUsdNow) {
                address user = ethMintedAddress[i];

                //현재 가격으로 팔았다고 치고 차액만큼 돌려주기
                uint256 valutEth = ethValut[user];
                uint256 amountToMint = (valutEth * ETHUSD) / 1e18;
                uint256 nowCollateralPrice = amountToMint / 1e8;
                uint256 goToUser = mintedStablecoins[user] - nowCollateralPrice;

                // 유저에게 차액 전송 + 알림

                // 수정 : 청산가 = 0 , 담보 액수 = 0으로 등록
                ethLiqudatePrice[user] = 0;
                ethValut[user] = 0;
            }
        }

        // 청산가 보다 낮으면 청산

        // 파는 대신 락을 걸고, 현재가격으로 팔았다고 치고 유저 금액을 빼서 차액 돌려주기

        // 알려주기

        return true;
    }

    function getEthValutBalance() public view returns (uint256) {
        return 1;
    }

    function getLinkValutBalance() public view returns (uint256) {
        return 1;
    }
}
