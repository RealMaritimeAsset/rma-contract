// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DLT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    IERC20 public erc20Token;
    DLT public dltToken;
    address public owner;
    uint256 public exchangeRate; // Number of ERC-20 tokens given per DLT token

    event Swap(address indexed user, uint256 dltAmount, uint256 erc20Amount);

    constructor(address _erc20Token, address _dltToken, uint256 _exchangeRate) {
        erc20Token = IERC20(_erc20Token);
        dltToken = DLT(_dltToken);
        owner = msg.sender;
        exchangeRate = _exchangeRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function setExchangeRate(uint256 _exchangeRate) public onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function swap(uint256 mainId, uint256 subId, uint256 dltAmount) public {
        uint256 erc20Amount = dltAmount * exchangeRate;

        // Check if the contract has enough ERC-20 tokens
        require(
            erc20Token.balanceOf(address(this)) >= erc20Amount,
            "Not enough ERC-20 tokens in the contract"
        );

        // Transfer DLT tokens from the user to the contract
        require(
            dltToken.transferFrom(msg.sender, address(this), mainId, subId, dltAmount),
            "DLT token transfer failed"
        );

        // Transfer ERC-20 tokens to the user
        erc20Token.transfer(msg.sender, erc20Amount);

        emit Swap(msg.sender, dltAmount, erc20Amount);
    }

    function withdrawERC20(uint256 amount) public onlyOwner {
        erc20Token.transfer(owner, amount);
    }

    function withdrawDLT(uint256 mainId, uint256 subId, uint256 amount) public onlyOwner {
        dltToken.transferFrom(address(this), owner, mainId, subId, amount);
    }
}
