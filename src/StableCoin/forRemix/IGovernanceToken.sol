// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Interface of the Extended ERC-20 for RMAGovernanceToken
 */
interface IgovernanceToken {
    /**
     * @dev Mints `amount` tokens to the `to` address.
     */
    function safeMint(address to, uint256 amount) external;

    /**
     * @dev Get governance token balance of `user`
     */
    function getBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Get totalsupply of minted governance token
     */
    function getTotalSupply() external view returns (uint256);
}
