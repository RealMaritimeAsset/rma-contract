// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/IGovernanceToken.sol";

/**
 * @title  RMAGovernance for RMA ecosystem.
 * @author Dreamboys
 * @dev You MUST deploy `RMAGovernanceToken.sol` in advance.
 * @notice This contract is for governance in RMA ecosystem.
 *
 * This contract provides voting, executing(recording), and proposing about...
 * 1. Adjusting `liquidationFeePercent`, `liquidationRatio`,
 *    `minimumCollateralizationRatio` in {RMAStablecoin} contract.
 * 2. Adjusting the issuance ratio of `governance tokens` to `stable coin`.
 * 3. Adjusting `tokenThreshold`, `quorum` in {RMAGovernance} contract.
 *
 */
contract RMAGovernance {
    /// @dev GovernanceToken Interface;
    IgovernanceToken public governanceToken;

    address public admin;

    /// @dev The minimum number of governance tokens required to propose
    uint256 public tokenThreshold;

    /// @dev The required percentage of total supply needed to meet quorum
    uint256 public quorum;

    struct Proposal {
        uint256 id; /// @dev Unique identifier for the proposal
        address proposer;
        string description;
        uint256 voteCount; /// @dev Number of votes the proposal has received
        uint256 proposalTime; /// @dev Timestamp when the proposal was created
        bool executed; /// @dev Whether the proposal has been executed
    }

    /// @dev Array storing all proposals made in the governance system
    Proposal[] public proposals;

    /// @dev Nested mapping to track whether an address has voted on a specific proposal
    mapping(uint256 => mapping(address => bool)) public votes;

    /// Events
    event QuorumChanged(uint256 oldValue, uint256 newValue, string message);
    event TokenThresholdChanged(
        uint256 oldValue,
        uint256 newValue,
        string message
    );
    event ProposalExecuted(
        uint256 proposalId,
        uint256 votePercent,
        string message
    );

    constructor(
        address _governanceTokenAddress,
        uint256 _initialTokenThreshold,
        uint256 _initialQuorum
    ) {
        admin = msg.sender;
        governanceToken = IgovernanceToken(_governanceTokenAddress);
        tokenThreshold = _initialTokenThreshold;
        quorum = _initialQuorum;
    }

    /// Modifiers

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can call this function.");
        _;
    }

    /// @dev To ensure the caller has at least the minimum number of governance tokens required to propose
    modifier meetsTokenThreshold() {
        require(
            _getGovernanceTokenBalance() >= tokenThreshold,
            "Governance : "
        );
        _;
    }

    /// External or Public Functions

    /// @dev Allows a user to create a new proposal if they meet the token threshold
    /// @param _description is the description of the proposal
    /// @return bool Returns true if the proposal is successfully created
    function propose(
        string calldata _description
    ) public meetsTokenThreshold returns (bool) {
        /// If user meets tokenThreshold,
        /// Push his proposal to `proposals`
        proposals.push(
            Proposal({
                id: proposals.length, /// unique identifier
                proposer: msg.sender,
                description: _description,
                voteCount: 0,
                proposalTime: block.timestamp, /// now
                executed: false
            })
        );

        return true;
    }

    /// @dev Sets the minimum number of tokens required to create a proposal
    /// @param _tokenThreshold is the new token threshold
    function setTokenThreshold(uint256 _tokenThreshold) public onlyAdmin {
        tokenThreshold = _tokenThreshold;
    }

    /// @dev Sets the quorum percentage required for a proposal to be accepted
    /// @param _quorum is the new quorum percentage (equal or less than 100)
    function setQuorum(uint256 _quorum) public onlyAdmin {
        require(_quorum <= 100, "Quorum cannot exceed 100%");
        quorum = _quorum;
    }

    /// @dev Casts a vote for a given proposal
    /// @notice 1 vote is equal to 1 `governanceToken`.
    /// @param _proposalId is the ID of the proposal to vote on
    function vote(uint256 _proposalId) public {
        require(
            _proposalId < proposals.length,
            "Governance : Invalid proposal ID."
        );
        require(
            !votes[_proposalId][msg.sender],
            "Governance : You have already voted."
        );

        uint256 governanceTokenBalance = _getGovernanceTokenBalance();

        proposals[_proposalId].voteCount += governanceTokenBalance;

        votes[_proposalId][msg.sender] = true;
    }

    /// @dev Executes a proposal if it meets the quorum requirements
    /// @param _proposalId is the ID of the proposal to execute
    /// @return bool returns true if the proposal is successfully executed
    function execute(uint256 _proposalId) public onlyAdmin returns (bool) {
        require(
            _proposalId < proposals.length,
            "Governance : Invalid proposal ID."
        );

        Proposal storage proposal = proposals[_proposalId];

        require(
            !proposal.executed,
            "Governance : Proposal has already been executed."
        );

        uint256 voteCount = proposal.voteCount;

        /// check if it meets quorum
        (bool result, uint256 votePercent) = _meetsQuorum(voteCount);

        if (result) {
            proposal.executed = true;
            emit ProposalExecuted(
                proposal.id,
                votePercent,
                proposal.description
            );
            return true;
        }

        return false;
    }

    /// Internal or Private Functions

    function _getGovernanceTokenBalance() internal view returns (uint256) {
        uint256 governanceTokenBalance = governanceToken.getBalanceOf(
            msg.sender
        );
        return governanceTokenBalance;
    }

    function _meetsQuorum(
        uint256 _voteCount
    ) internal view returns (bool, uint256) {
        uint256 totalSupply = governanceToken.getTotalSupply();
        uint256 votePercent = (_voteCount * 100) / totalSupply;
        require(votePercent >= quorum, "Governance : Quorum not met");
        return (true, votePercent);
    }

    /// View or Pure Functions

    function isExecuted(uint256 _proposalId) public view returns (bool) {
        require(
            _proposalId < proposals.length,
            "Governance : Invalid proposal ID."
        );
        Proposal storage proposal = proposals[_proposalId];
        return proposal.executed;
    }
}
