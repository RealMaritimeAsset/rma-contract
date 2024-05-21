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
        uint256 weiAmount = msg.value;
        uint256 amountToMint = (weiAmount * ETHUSD) / 1e18;
        uint256 coinAmount = amountToMint / 1e8;
        uint256 liqudatePrice = ((ETHUSD / 1e8) * 100) / liquidation_ratio;
        //for (i )

        return liqudatePrice;
    }
}
