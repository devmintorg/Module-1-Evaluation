//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staker2 {
    uint256 lockedTimeMinutes;

    struct tokenStruct {
        uint256 exchangeRate;
        IERC20 token;
    }

    mapping(uint256 => tokenStruct) rewards;

    uint256 numTokens;

    struct userStake {
        bool cannotStake;
        uint256 etherStaked;
        uint256[] stakeRewardAmounts;
        uint256 unlockTime;
    }
    mapping(address => userStake) currentStakes;

    event userStaked(address indexed _user, uint256 etherStakes);
    event userWithdrawStake(address indexed _user, uint256 etherStakes);
    event userWithdrawReward(
        address indexed _user,
        uint256[] stakeRewardAmounts
    );

    constructor(
        uint256 _numTokens,
        tokenStruct[] memory _tokensObjects,
        uint256 _lockedTimeMinutes
    ) {
        lockedTimeMinutes = _lockedTimeMinutes;
        numTokens = _numTokens;

        for (uint256 i = 0; i < _numTokens; i++) {
            rewards[i].exchangeRate = _tokensObjects[i].exchangeRate;
            rewards[i].token = _tokensObjects[i].token;
        }
    }

    modifier checkRestake() {
        _;
        if (
            currentStakes[msg.sender].etherStaked == 0 &&
            currentStakes[msg.sender].stakeRewardAmounts.length == 0
        ) {
            currentStakes[msg.sender].cannotStake = false;
        }
    }

    // User Stakes Token in Smart Contract
    function stake() external payable {
        //Require that the can stake
        require(
            currentStakes[msg.sender].cannotStake == false,
            "You cannot stake!"
        );

        // Require ETH is between 1 and 100 ETH
        require(msg.value >= 1 ether, "Sent Too Little ETH. Minimum 1 ETH");
        require(msg.value <= 100 ether, "Sent Too Much ETH. Maximum 100 ETH");

        // Create new userStake value
        userStake memory nextStake;

        nextStake.cannotStake = true;
        nextStake.etherStaked = msg.value;
        nextStake.unlockTime = block.timestamp + lockedTimeMinutes;
        for (uint256 i = 0; i < numTokens; i++) {
            nextStake.stakeRewardAmounts.push(
                msg.value * rewards[i].exchangeRate
            );
        }

        currentStakes[msg.sender] = nextStake;

        // Emit Staking Event
        emit userStaked(msg.sender, msg.value);
    }

    //User withdraws full stake from contract
    function withdrawStake() external payable checkRestake {
        //Check Time Requirement
        require(
            block.timestamp >= currentStakes[msg.sender].unlockTime,
            "Cannot Withdraw Yet"
        );
        require(
            currentStakes[msg.sender].etherStaked > 0,
            "No Value to Unstake"
        );

        uint256 userStakedAmount = currentStakes[msg.sender].etherStaked;
        currentStakes[msg.sender].etherStaked = 0;

        (bool success, ) = msg.sender.call{value: userStakedAmount}("");
        require(success, "Call Failed");

        //Emit Withdraw Event
        emit userWithdrawStake(msg.sender, userStakedAmount);
    }

    //User withdraws full stake reward from contract
    function withdrawReward() external checkRestake {
        require(
            block.timestamp >= currentStakes[msg.sender].unlockTime,
            "Cannot Withdraw Yet"
        );
        require(
            currentStakes[msg.sender].stakeRewardAmounts.length == 0,
            "No Stake Reward to Claim"
        );

        uint256[] memory userRewardAmount = currentStakes[msg.sender]
            .stakeRewardAmounts;
        for (uint256 i = 0; i < numTokens; i++) {
            currentStakes[msg.sender].stakeRewardAmounts.pop();
        }
        for (uint256 j = 0; j < numTokens; j++) {
            rewards[j].token.transfer(msg.sender, userRewardAmount[j]);
        }

        //Emit Withdraw Event
        emit userWithdrawReward(msg.sender, userRewardAmount);
    }
}
