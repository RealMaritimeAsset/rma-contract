function _redeemCollateralAndBurn(
    uint256 valutAmount
) internal payable returns (bool) {
    // Redeem Collateral ETH to User
    user.transfer(valutAmount);

    // Burn all Stable coins User minted
    _burn(msg.sender, mintedStablecoins[user]);

    // Reset All data
    weiValut[user] = 0;
    ethLiqudatePrice[user] = 0;
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



        uint256 latestETHUSD = uint256(getLatestETHUSDPrice());

        uint256 truncatedETHUSD = truncateETHUSDDecimals(latestETHUSD);


        uint256 truncatedETHUSD = truncateETHUSDDecimals(latestETHUSD);




