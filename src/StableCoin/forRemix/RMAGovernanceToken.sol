// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "contracts/IGovernanceToken.sol";

/// @title RMAGovernanceToken
/// @dev Governance token for RMA platform, supporting minting, voting, and permit functionalities.
contract RMAGovernanceToken is
    ERC20,
    Ownable,
    ERC20Permit,
    ERC20Votes,
    IgovernanceToken
{
    /// @dev Mapping to keep track of minter addresses.
    mapping(address => bool) public isMinter;

    constructor(
        address initialOwner
    )
        ERC20("RMAGovernanceToken", "RMAG")
        Ownable(initialOwner)
        ERC20Permit("RMAGovernanceToken")
    {
        isMinter[msg.sender] = true;
    }

    /// @dev Modifier to restrict functions to only minters.
    modifier onlyMinter() {
        require(isMinter[msg.sender], "Not Minter");
        _;
    }

    /// @dev Function to add a new minter.
    /// @param _newMinter The address to be added as a new minter.
    function addMinter(address _newMinter) public onlyOwner {
        isMinter[_newMinter] = true;
    }

    /// @dev Function to safely mint new tokens.
    /// @param to The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function safeMint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    /// @param user is the address of governance token holder.
    /// @return the amount of governance tokens user holds.
    function getBalanceOf(address user) public view returns (uint256) {
        uint256 balance = balanceOf(user);
        return balance;
    }

    /// @dev Function to get totalsupply of governance tokens.
    /// @return the total amount of governance tokens.
    function getTotalSupply() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        return totalSupply;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
