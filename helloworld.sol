//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HelloWorld{
    string public greeting = "Hello, World of Blockchain";

    function setGreeting(string memory _newGreeting) public {
        greeting = _newGreeting;
    }
}
