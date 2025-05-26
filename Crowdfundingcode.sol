// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdfundingCampaign {
    address public owner;
    uint public goal;
    uint public deadline;
    uint public totalContributed;
    bool public goalReached;
    bool public withdrawn;

    mapping(address => uint) public contributions;

    event ContributionReceived(address contributor, uint amount);
    event GoalReached(uint totalAmount);
    event FundsWithdrawn(address owner, uint amount);
    event RefundIssued(address contributor, uint amount);

    constructor(uint _goalInWei, uint _durationInDays) {
        owner = msg.sender;
        goal = _goalInWei;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only campaign owner can do this.");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Deadline has passed.");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline not yet reached.");
        _;
    }

    function contribute() public payable beforeDeadline {
        require(msg.value > 0, "Contribution must be greater than zero.");

        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;

        emit ContributionReceived(msg.sender, msg.value);

        if (totalContributed >= goal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalContributed);
        }
    }

    function withdrawFunds() public onlyOwner afterDeadline {
        require(goalReached, "Funding goal not reached.");
        require(!withdrawn, "Funds already withdrawn.");

        withdrawn = true;
        payable(owner).transfer(address(this).balance);

        emit FundsWithdrawn(owner, address(this).balance);
    }

    function claimRefund() public afterDeadline {
        require(!goalReached, "Goal was met, refunds not available.");
        uint amount = contributions[msg.sender];
        require(amount > 0, "No contributions found for refund.");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit RefundIssued(msg.sender, amount);
    }

    function getTimeRemaining() public view returns (uint) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    function getContribution(address _contributor) public view returns (uint) {
        return contributions[_contributor];
    }
}

