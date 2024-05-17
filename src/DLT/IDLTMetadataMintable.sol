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
     * @param subId is the token subtype ID being minted
     * @param amounts is the amounts of token being minted
     * @param tokenURI is IPFS URI for metadata of the token
     * @return boolean
     */
    function mintWithTokenURI(
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amounts,
        string calldata tokenURI
    ) external returns (bool);
}
