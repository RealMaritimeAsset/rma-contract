// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

/**
 * @title DLT token receiver interface
 * @dev Interface for any contract that wants to supprot safeTransfers
 * from DLT asset contracts.
 */
interface IDLTReceiver {
    /**
     * @notice Handle the receipt of a single DLT token type.
     * @dev Whenever an {DLT} 'subId' token is transferred to this contract via {IDLT-safeTransferFrom}
     * by `operator` from `sender`, this function is called.
     * MUST return its Solidity selector to confirm the token transfer.
     * MUST revert if any other value is returned or the interface is not implemented by the recipient.
     * The selector can be obtained in Solidity with `IDLTReceiver.onDLTReceived.selector`.
     * @param operator is the address which initiated the transfer
     * @param from is the address which previously owned the token
     * @param mainId is the main token type ID being transferred
     * @param subId subId is the token subtype ID being transferred
     * @param amount is the amount of tokens being transferred
     * @param data is additional data with no specified format
     * @return `IDLTReceiver.onDLTReceived.selector`
     */
    function onDLTReceived(
        address operator,
        address from,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipts of a DLT token type array.
     * @dev Whenever an {DLT} `subIds` token is transferred to this contract via {IDLT-safeTransferFrom}
     * by `operator` from `sender`, this function is called.
     * MUST return its Solidity selector to confirm the token transfers.
     * MUST revert if any other value is returned or the interface is not implemented by the recipient.
     * The selector can be obtained in Solidity with `IDLTReceiver.onDLTReceived.selector`.
     * @param operator is the address which initiated the transfer
     * @param from is the address which previously owned the token
     * @param mainIds is the main token type ID being transferred
     * @param subIds subId is the token subtype ID being transferred
     * @param amounts is the amount of tokens being transferred
     * @param data is additional data with no specified format
     * @return `IDLTReceiver.onDLTReceived.selector`
     */
    function onDLTBatchReceived(
        address operator,
        address from,
        uint256[] calldata mainIds,
        uint256[] calldata subIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}
