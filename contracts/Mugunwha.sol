// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mugungwha is IERC20, ReentrancyGuard, Ownable {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Mugungwha";
    string public symbol = "MGW";
    uint8 public decimals = 18;

    uint256 public storeBalance = 0;
    uint256 public payoutMileStone1 = 3 ether;
    uint256 public mileStone1Reward = 2 ether;
    uint256 public finalMileStone = 10 ether;
    uint256 public finalReward = 5 ether;

    mapping(address => uint256) redeemableMGW;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor() {}

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function mintForReward(uint256 value) private {
        balanceOf[address(this)] += value;
    }

    function withdraw(uint256 wad) public payable nonReentrant onlyOwner {
        address payable payableSender = payable(msg.sender);
        payableSender.transfer(wad);

        emit Withdrawal(msg.sender, wad);
    }

    function play(uint256 value) external payable {
        require(msg.value == 0.5 ether);

        uint256 currentBalance = storeBalance + value;

        require(currentBalance <= finalMileStone);

        if (currentBalance == payoutMileStone1) {
            redeemableMGW[msg.sender] += mileStone1Reward;
            mintForReward(mileStone1Reward);
        } else if (currentBalance == finalMileStone) {
            redeemableMGW[msg.sender] += finalReward;
            mintForReward(finalReward);
        }

        IERC20(address(this)).transfer(address(this), value);
    }

    function claimReward() public {
        // ensure the game is complete
        require(storeBalance == finalMileStone);
        // ensure there is a reward to give
        require(redeemableMGW[msg.sender] > 0);
        uint256 transferValue = redeemableMGW[msg.sender];
        redeemableMGW[msg.sender] = 0;
        IERC20(address(this)).transferFrom(
            address(this),
            msg.sender,
            transferValue
        );
    }
}
