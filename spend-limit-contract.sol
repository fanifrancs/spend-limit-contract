// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AllowanceWallet {

    address public owner;

    mapping(address => uint256) public allowance;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    //In Solidity, a function can be marked as payable to receive Ether.
    //  If the function body is empty, it simply accepts the Ether sent
    //  to it without any additional logic.
    function deposit() public payable {}

    function setAllowance(address _spender, uint256 _amount)
        public
        onlyOwner
    {
        allowance[_spender] = _amount;
    }

    function spend(uint256 _amount) public {
        require(allowance[msg.sender] >= _amount, "Allowance exceeded");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        allowance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
