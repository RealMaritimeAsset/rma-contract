// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

/**
 * @title DLT token standard interface
 * @dev Interface for any contract that wants to implement the DLT standard
 */

interface IDLT {
    /**
     * @dev Must emit when subId token is transffered form 'sender' to 'recipient'
     * @param sender is the address of previous holder whose balance is decre
     * @param recipient is the address of new holder whose bal is inc
     * @param mainId is the main token type ID to be transffered
     * @param subId is the token subtype ID to be transffered
     * @param amount is the amount to be transferred of the token subtype
     */
    event Transfer(
        address indexed sender,
        address indexed recipient,
        uint256 indexed mainId,
        uint256 subId,
        uint256 amount
    );

    /**
     * @dev Must emit when 'subIds' token array is transferred from 'sender' to 'recipient'
     * @param sender is the address of previous holder
     * @param recipient is the address of new holder
     * @param mainIds is the main token type ID array to be transferred
     * @param subIds is the token subtype ID array to be transferred
     * @param amounts is the amount array to be transferred of the token subtype
     */
    event TransferBatch(
        address indexed spender,
        address indexed sender,
        address indexed recipient,
        uint256[] mainIds,
        uint256[] subIds,
        uint256[] amounts
    );

    /**
     * @dev Must emit when owner enables operator to mange the 'subId' token
     * @param owner is the address of token owner
     * @param operator is the authorized address to manage all tokens for owner
     * @param mainId is the main token type ID to be approved
     * @param subId is the token subtype ID
     * @param amount is the amount to be approved of the token subtype
     */
    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    );

    /**
     * @dev Must emit when owner enables or disables 'operator' to manage all of its assets
     * @param owner is the address of token owner
     * @param operator is the authorized address to manage all tokens for owner
     * @param approved true if the operator is approved, false to revoke approval
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Must emit when the URI is updated for a main token type ID
     * URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "DLT Metadata URI JSON Schema".
     * @param oldValue is the old URI value
     * @param newValue is the old URI value
     * @param mainId is the main token type ID
     */
    event URI(string oldValue, string newValue, uint256 indexed mainId);

    /**
     * @dev Approve or remove 'operator' as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any SubId owned by the caller.
     * The 'operator' MUST NOT be the caller.
     * MUST emit an {ApprovalForAll} event.
     * @param operator is the authorized address to manage all tokens
     * @param approved true if the operator is approved, false to revoke approval
     */
    function SetApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Moves 'amount' tokens form 'sender' to 'recipient' using the allowance mechanism.
     * amount is then deducted from callers allowance.
     * MUST revert if 'sender' or 'recipient' is zero addr.
     * MUST revert if balance of holder for token 'subId' is lower than 'amount'
     * MUST emit a {Transfer} event.
     * @param sender is the address of the previous holder whose balance is decreased
     * @param recipient is the address of the new holder whose balance is increased
     * @param mainId is the main token type ID to be transferred
     * @param subId is the token subtype ID to be transferred
     * @param amount is the amount to be transferred of the token subtype
     * @param data is additional data with no specified format
     * @return True if the operation succeeded, false if operation failed.
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Sets 'amount' as the allownace of 'spender' over the caller's tokens.
     * The 'operator' MUST NOT be the caller.
     * MUST revert if 'operator' is the zero addr.
     * MUST emit an {Approval} event.
     * @param operator is the authorized address to manage tokens for an owner address
     * @param mainId is the main token type ID to be approved
     * @param subId is the token subtype ID to be approved
     * @param amount is the amount to be approved of the token subtype
     * @return True if the operation succeeded, false if operation failed
     */

    function approve(
        address operator,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Get the token with a particular subId balance of an 'account'
     * @param account is the address of the token holder
     * @param mainId is the main token type ID
     * @param subId is the token subtype ID
     * @return The amount of tokens owned by `account` in subId
     */
    function subBalanceOf(
        address account,
        uint256 mainId,
        uint256 subId
    ) external view returns (uint256);

    /**
     * @notice Get the tokens with a particular subIds balance of an 'accounts' array
     * @param accounts is the address array of the token holder
     * @param mainIds is the main token type ID array
     * @param subIds is the token subtype ID array
     * @return The amount of tokens owned by `accounts` in subIds
     */

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata mainIds,
        uint256[] calldata subIds
    ) external view returns (uint256[] calldata);

    /**
     * @notice Get the allowance allocated to an 'operator'
     * @dev This value changes when {approve} or {transferFrom} are called
     * @param owner is the address of the token owner
     * @param operator is the authorized address to manage assets for an owner address
     * @param mainId is the main token type ID
     * @param subId is the token subtype ID
     * @return The remaining number of tokens that `operator` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     */
    function allowance(
        address owner,
        address operator,
        uint256 mainId,
        uint256 subId
    ) external view returns (uint256);

    /**
     * @notice Get the approval status of an 'operator' to manage assets
     * @param owner is the address of the token owner
     * @param operator is the authorized address to manage assets for an owner address
     * @return True if the 'operator' is allowed to manage all of the assets of 'owner', false if approval is revoekd.
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}
