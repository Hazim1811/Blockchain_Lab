// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {
    // State
    address public owner;
    uint public goal;
    uint public deadline;
    uint public raised;
    mapping(address => uint) public contributions;
    address[] public backers;

    // Events
    event FundReceived(address indexed contributor, uint amount);
    event GoalReached(uint totalRaised);
    event Refunded(address indexed contributor, uint amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Past deadline");
        _;
    }
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Too early");
        _;
    }

    // Constructor: set goal and deadline (in seconds from now)
    constructor(uint _goalWei, uint _durationMinutes) {
        owner = msg.sender;
        goal = _goalWei;
        deadline = block.timestamp + (_durationMinutes * 1 minutes);
    }

    // 1. contribute() – accepts Ether from contributors
    function contribute() external payable beforeDeadline {
        require(msg.value > 0, "Must send ETH");
        if (contributions[msg.sender] == 0) {
            backers.push(msg.sender);
        }
        contributions[msg.sender] += msg.value;
        raised += msg.value;
        emit FundReceived(msg.sender, msg.value);

        if (raised >= goal) {
            emit GoalReached(raised);
        }
    }

    // 2. checkBalance() – view the current funds raised
    function checkBalance() external view returns (uint) {
        return raised;
    }

    // 3. withdraw() – Only the owner can withdraw if the target is reached
    function withdraw() external onlyOwner {
        require(raised >= goal, "Goal not reached");
        uint amount = raised;
        raised = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // 4. refund() – Contributors can request a refund if the goal is not met by the deadline
    function refund() external afterDeadline {
        require(raised < goal, "Goal was met");
        uint contributed = contributions[msg.sender];
        require(contributed > 0, "No contributions");
        contributions[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: contributed}("");
        require(success, "Refund failed");
        emit Refunded(msg.sender, contributed);
    }

    // 5. getDetails() – returns goal, deadline, amount raised, and contributor count
    function getDetails()
        external
        view
        returns (
            uint _goal,
            uint _deadline,
            uint _raised,
            uint _numContributors
        )
    {
        return (goal, deadline, raised, backers.length);
    }
}