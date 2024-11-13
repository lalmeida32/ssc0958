// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Dao {

    struct Voter {
        bool voted;
        uint vote;
    }

    struct Proposal {
        uint id;
        address proposer;
        string description;
        uint voteCount;
        bool open;
    }

    mapping(uint => Proposal) public proposals;
    mapping(address => Voter) public voters;
    
    uint public proposalCount;
    address public owner;
    address[] public voterAddresses;

    event ProposalCreated(uint proposalId, address proposer, string description);
    event ProposalsClosed(uint[] mostVotedProposals, uint highestVoteCount);

    constructor() {
        owner = msg.sender;
        proposalCount = 0;
    }

    function propose(string memory _description) public {
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            voteCount: 0,
            open: true
        });

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function vote(uint proposalId) external {
        require(proposals[proposalId].open == true, "Proposal must be open.");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposalId;

        proposals[proposalId].voteCount++;
        voterAddresses.push(msg.sender);
    }

    function closeProposals() public returns (uint[] memory) {
        require(owner == msg.sender, "You are not the contract owner.");
        uint highestVoteCount = 0;
        uint[] memory topProposals = new uint[](proposalCount);
        uint topProposalCount = 0;

        for (uint i = 0; i < proposalCount; i++) {
            if (proposals[i].open) {
                proposals[i].open = false;

                if (proposals[i].voteCount > highestVoteCount)
                {
                    highestVoteCount = proposals[i].voteCount;
                    topProposalCount = 1;
                    topProposals[0] = i;
                }
                else if (proposals[i].voteCount == highestVoteCount)
                {
                    topProposals[topProposalCount++] = i;
                }
            }
        }

        uint[] memory mostVotedProposals = new uint[](topProposalCount);
        for (uint j = 0; j < topProposalCount; j++) {
            mostVotedProposals[j] = topProposals[j];
        }
        
        for (uint k = 0; k < voterAddresses.length; k++) {
            voters[voterAddresses[k]].voted = false;
            voters[voterAddresses[k]].vote = 0;
        }
        while (voterAddresses.length != 0) {
            voterAddresses.pop();
        }

        emit ProposalsClosed(mostVotedProposals, highestVoteCount);
        return mostVotedProposals;
    }
}