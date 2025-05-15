// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SimpleContract – starter example for Lab 6 (owner‑only counter + deposits)
contract SimpleContract {

    // ──────────── State ────────────
    address public owner;          // Owner of the contract (set once in constructor)
    uint    public count;          // Simple counter variable
    mapping(address => uint) public balances;  // Tracks each user’s deposited Ether

    // ───────── Constructor ─────────
    constructor() {
        owner = msg.sender;        // Deployer becomes the owner
    }

    // ──────── Modifier ────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // ──────────── Events ────────────
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event TransferBetween(address indexed from, address indexed to, uint amount);
    event CountReset(address indexed owner);

    // ──────────── Logic ────────────

    /// Owner can set any value for `count`
    function setCount(uint _count) public onlyOwner {
        count = _count;
    }

    /// Anyone can read the current counter
    function getCount() public view returns (uint) {
        return count;
    }

    /// Anyone can deposit Ether; value is added to their balance
    function deposit() public payable {
        require(msg.value > 0, "Must send Ether");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// Read the deposited balance of a given address
    function checkBalance(address _user) public view returns (uint) {
        return balances[_user];
    }

    /// Withdraw up to the caller’s own deposited amount
    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// Transfer deposited balance from caller to another user without withdrawing
    function transferBetween(address to, uint amount) public {
        require(to != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit TransferBetween(msg.sender, to, amount);
    }

    /// Owner can reset the count to zero
    function resetCount() public onlyOwner {
        count = 0;
        emit CountReset(msg.sender);
    }
}
