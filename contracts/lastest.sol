// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract lastest {
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public amountRaised;
    uint256 public contributorCount;

    mapping(address => uint256) public contributions;
    bool public goalReached;
    bool public withdrawn;

    // Events
    event FundReceived(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event Refunded(address indexed contributor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Deadline has passed");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline not reached");
        _;
    }

    constructor(uint256 _goal, uint256 _durationMinutes) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + (_durationMinutes * 1 minutes);
    }

    // 1. Contribute
    function contribute() external payable beforeDeadline {
        require(msg.value > 0, "Must send Ether");
        if (contributions[msg.sender] == 0) contributorCount += 1;
        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;
        emit FundReceived(msg.sender, msg.value);
        if (amountRaised >= goal && !goalReached) {
            goalReached = true;
            emit GoalReached(amountRaised);
        }
    }

    // 2. View balance
    function checkBalance() external view returns (uint256) {
        return amountRaised;
    }

    // 3. Withdraw (owner only, after goal & before refund)
    function withdraw() external onlyOwner {
        require(goalReached, "Goal not reached");
        require(!withdrawn, "Already withdrawn");
        withdrawn = true;
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }

    // 4. Refund (if deadline passed & goal not met)
    function refund() external afterDeadline {
        require(amountRaised < goal, "Goal was reached, cannot refund");
        uint256 contributed = contributions[msg.sender];
        require(contributed > 0, "Nothing to refund");
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributed);
        emit Refunded(msg.sender, contributed);
    }

    // 5. Get campaign details
    function getDetails()
        external
        view
        returns (
            uint256 _goal,
            uint256 _deadline,
            uint256 _amountRaised,
            uint256 _contributorCount,
            address _owner,
            bool _goalReached
        )
    {
        return (
            goal,
            deadline,
            amountRaised,
            contributorCount,
            owner,
            goalReached
        );
    }

    // 6. This is to get to know the time left for the transaction
    function getTimeLeft() public view returns (uint) {
    if (block.timestamp >= deadline) {
        return 0;
    } else {
        return deadline - block.timestamp;
    }
}

}