// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/IGovernanceToken.sol";

/// @title RMAGovernanceToken
/// @dev Governance token for RMA platform, supporting minting, voting, and permit functionalities.
contract RMAGovernance {
    address public admin;
    uint256 public tokenThreshold;
    uint256 public quorum;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        uint256 proposalTime;
        bool executed;
    }

    /// GovernanceToken Interface;
    IgovernanceToken public governanceToken;

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public votes;

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

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can call this function.");
        _;
    }

    modifier meetsTokenThreshold() {
        require(
            _getGovernanceTokenBalance() >= tokenThreshold,
            "Governance : "
        );
        _;
    }

    function propose(
        string calldata _description
    ) public meetsTokenThreshold returns (bool) {
        proposals.push(
            Proposal({
                id: proposals.length,
                proposer: msg.sender,
                description: _description,
                voteCount: 0,
                proposalTime: block.timestamp,
                executed: false
            })
        );

        return true;
    }

    function setTokenThreshold(uint256 _tokenThreshold) public onlyAdmin {
        tokenThreshold = _tokenThreshold;
    }

    function setQuorum(uint256 _quorum) public onlyAdmin {
        require(_quorum <= 100, "Quorum cannot exceed 100%");
        quorum = _quorum;
    }

    function vote(uint256 _proposalId) public {
        require(_proposalId < proposals.length, "Invalid proposal ID.");
        require(!votes[_proposalId][msg.sender], "You have already voted.");

        uint256 governanceTokenBalance = _getGovernanceTokenBalance();

        proposals[_proposalId].voteCount += governanceTokenBalance;

        votes[_proposalId][msg.sender] = true;
    }

    function _getGovernanceTokenBalance() internal view returns (uint256) {
        uint256 governanceTokenBalance = governanceToken.getBalanceOf(
            msg.sender
        );

        return governanceTokenBalance;
    }

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

    function isExecuted(uint256 _proposalId) public view returns (bool) {
        require(
            _proposalId < proposals.length,
            "Governance : Invalid proposal ID."
        );
        Proposal storage proposal = proposals[_proposalId];
        return proposal.executed;
    }

    function _meetsQuorum(
        uint256 _voteCount
    ) internal view returns (bool, uint256) {
        uint256 totalSupply = governanceToken.getTotalSupply();
        uint256 votePercent = (_voteCount * 100) / totalSupply;
        require(votePercent >= quorum, "Governance : Quorum not met");
        return (true, votePercent);
    }
}
