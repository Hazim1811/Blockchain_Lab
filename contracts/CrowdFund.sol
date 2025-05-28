// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CrowdFund {
    /* ──────────────────── Configuration ──────────────────── */
    address public immutable owner;      // campaign creator
    uint256 public immutable goal;       // funding goal in wei
    uint256 public immutable deadline;   // unix time (seconds)

    /* ──────────────────── State ──────────────────── */
    mapping(address => uint256) public contributions;
    uint256 public amountRaised;
    uint256 public contributorCount;

    /* ──────────────────── Events ──────────────────── */
    event FundReceived(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalRaised);
    event Refunded(address indexed contributor, uint256 amount);

    /* ──────────────────── Modifiers ──────────────────── */
    modifier onlyOwner() {
        require(msg.sender == owner, "CrowdFund: caller is not owner");
        _;
    }
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "CrowdFund: funding period over");
        _;
    }
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "CrowdFund: funding still active");
        _;
    }

    /* ──────────────────── Constructor ──────────────────── */
    constructor(uint256 _goalWei, uint256 _durationSec) {
        require(_goalWei > 0,          "CrowdFund: goal must be > 0");
        require(_durationSec > 0,      "CrowdFund: duration must be > 0");
        owner    = msg.sender;
        goal     = _goalWei;
        deadline = block.timestamp + _durationSec;
    }

    /* ──────────────────── Internal core ──────────────────── */
    function _contribute() internal beforeDeadline {
        require(msg.value >= 0.01 ether, "CrowdFund: min 0.01 ETH");
        if (contributions[msg.sender] == 0) ++contributorCount;
        contributions[msg.sender] += msg.value;
        amountRaised              += msg.value;

        emit FundReceived(msg.sender, msg.value);
        if (amountRaised >= goal) emit GoalReached(amountRaised);
    }

    /* ──────────────────── Public / External API ──────────────────── */
    function contribute() external payable {
        _contribute();
    }

    function checkBalance() external view returns (uint256 currentBalance) {
        return amountRaised;
    }

    function getDetails()
        external
        view
        returns (
            uint256 goalWei,
            uint256 deadlineTs,
            uint256 raisedWei,
            uint256 numContributors
        )
    {
        return (goal, deadline, amountRaised, contributorCount);
    }

    function withdraw() external onlyOwner {
        require(amountRaised >= goal, "CrowdFund: goal not reached");
        uint256 balance = amountRaised;
        amountRaised = 0;                      
        (bool ok, ) = owner.call{value: balance}("");
        require(ok, "CrowdFund: withdraw failed");
    }

    function refund() external afterDeadline {
        require(amountRaised < goal, "CrowdFund: goal met; no refunds");
        uint256 donated = contributions[msg.sender];
        require(donated > 0, "CrowdFund: nothing to refund");

        contributions[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: donated}("");
        require(ok, "CrowdFund: refund failed");

        emit Refunded(msg.sender, donated);
    }

    /* ──────────────────── ETH Receive Hooks ──────────────────── */
    receive() external payable {
        _contribute();
    }

    fallback() external payable {
        _contribute();
    }
}