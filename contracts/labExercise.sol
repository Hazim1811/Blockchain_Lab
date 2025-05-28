// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract labExercise {
    address public owner;
    uint public goal;
    uint public deadline;
    uint public amountRaised;
    uint public contributorCount;
    mapping(address => uint) public contributors;

    event FundReceived(address indexed contributor, uint amount);
    event GoalReached(uint totalAmount);
    event Refunded(address indexed contributor, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this.");
        _;
    }
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Deadline passed");
        _;
    }
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline not reached yet");
        _;
    }
    modifier goalNotReached() {
        require(amountRaised < goal, "Goal reached");
        _;
    }
    modifier goalReached() {
        require(amountRaised >= goal, "Goal not reached");
        _;
    }

    constructor(uint _goal, uint _durationInMinutes) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    function contribute() public payable beforeDeadline goalNotReached {
        require(msg.value > 0, "Contribution must be greater than 0");
        if (contributors[msg.sender] == 0) {
            contributorCount++;
        }
        contributors[msg.sender] += msg.value;
        amountRaised += msg.value;
        emit FundReceived(msg.sender, msg.value);
        if (amountRaised >= goal) {
            emit GoalReached(amountRaised);
        }
    }

    function checkBalance() public view returns (uint) {
        return amountRaised;
    }

    function withdraw() public onlyOwner goalReached afterDeadline {
        payable(owner).transfer(amountRaised);
        amountRaised = 0; // Optional: reset after withdraw
    }

    function refund() public afterDeadline goalNotReached {
        require(contributors[msg.sender] > 0, "No funds to refund");
        uint amount = contributors[msg.sender];
        contributors[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refunded(msg.sender, amount);
    }

    function getDetails() public view returns (
        uint _goal, uint _deadline, uint _amountRaised, uint _contributorCount
    ) {
        return (goal, deadline, amountRaised, contributorCount);
    }
}
