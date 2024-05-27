// SPDX-License-Identifier: RMA
pragma solidity 0.8.19;

/**
 * @title DLT token mintable with metadata interface
 * @dev Interface for any contract that wants to supprot metadatamintable DLT
 * from DLT asset contracts.
 */
interface IDLTMetadataMintable {
    /**
     * @notice Handle the mint of token with metadata
     * @dev Whenever an {DLT} 'subId' token is minted to this contract
     * by contract deployer, this function is called.
     * MUST return boolean to show mint is well done.
     * MUST check if `mainId` or `subId` is already used before mint.
     * @param recipient is the address which is address of the token.
     * @param mainId is the main token type ID being minted
     * @param subIdAmounts are sub token type amounts.
     * @param tokenAmounts are the amounts of sub token being minted
     * @param tokenURIs are IPFS URI for metadata of the token
     * @return boolean
     */
    function mintWithTokenURI(
        address recipient,
        uint256 mainId,
        uint256 subIdAmounts,
        uint256 tokenAmounts,
        string[] calldata tokenURIs
    ) external returns (bool);
}
