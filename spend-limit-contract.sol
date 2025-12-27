// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AllowanceWallet {

    address public owner;
    //Pause/unpause system acts as an emergency brake in case of
    //  bugs/exploits by restricting calls to functions
    bool public paused;

    mapping(address => uint256) public allowance;

    // EVENTS
    event Deposit(address indexed from, uint256 amount);
    event AllowanceSet(address indexed spender, uint256 amount);
    event Spent(address indexed spender, uint256 amount);
    event EmergencyWithdraw(address indexed owner, uint256 amount);
    event Paused();
    event Unpaused();

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    //modifier for the pause/unpause system
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    //toggle functions for pause/unpause boolean
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    //In Solidity, a function can be marked as payable to receive Ether.
    //  If the function body is empty, it simply accepts the Ether sent
    //  to it without any additional logic. Right below, no special logic
    //  but the emission of the deposit event.
    function deposit() public payable whenNotPaused {
        emit Deposit(msg.sender, msg.value);
    }

    function setAllowance(address _spender, uint256 _amount)
        public
        onlyOwner
    {
        allowance[_spender] = _amount;
        emit AllowanceSet(_spender, _amount);
    }

    function spend(uint256 _amount) public whenNotPaused {
        require(allowance[msg.sender] >= _amount, "Allowance exceeded");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        allowance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Spent(msg.sender, _amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

     //emergency ETH withdrawal by owner. Typically used when
     // paused == true (but not required). Note: In production,
     // protocols often restrict emergency withdraw to paused
     // state only or add a timelock or require multisig approval
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance");

        payable(owner).transfer(_amount);
        emit EmergencyWithdraw(owner, _amount);
    }

    // emergency withdraw ALL ETH
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        payable(owner).transfer(balance);
        emit EmergencyWithdraw(owner, balance);
    }
}

//Modern, safe replacement for .transfer() is call{value: ...}
//  with reentrancy protection + CEI pattern. I forgot to use
//  this