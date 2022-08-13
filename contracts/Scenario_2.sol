//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Scenario2 {

    uint256 lockedTimeMinutes;
    /// Number of whole tokens to 1 ETH
    uint256 exchangeRate;
    uint256 tokenListLength;

    mapping (IERC20 => uint256) private tokensAndExchangeRates;
    IERC20[] private tokenList;
    mapping (address => mapping (IERC20 => uint256)) private addressAndStakeRewardsPerToken;

    struct userStake {
        bool cannotStake;
        uint256 etherStaked;
        uint256 stakeRewardTotal; // for checking that the stakeReward is greater than 0
        uint256 unlockTime;
    }
    mapping(address => userStake) currentStakes;

    event userStaked(address indexed _user, uint256 etherStakes);
    event userWithdrawStake(address indexed _user, uint256 etherStakes);
    event userWithdrawReward(address indexed _user, uint256 stakeReward);

    constructor (IERC20[] memory _tokens, uint256[] memory _exchangeRates, uint256 _lockedTimeMinutes) {
        require(_tokens.length == _exchangeRates.length, "you need your tokens to correspond with your exchange rates!");
        for(uint i = 0; i < _tokens.length; i++) {
            tokensAndExchangeRates[_tokens[i]] = _exchangeRates[i];
            tokenList.push(_tokens[i]);
            tokenListLength += 1;
        }
        lockedTimeMinutes = _lockedTimeMinutes * 1 minutes;
    }

    modifier checkRestake {
        _;
        if(currentStakes[msg.sender].etherStaked == 0 && currentStakes[msg.sender].stakeRewardTotal == 0) {
            currentStakes[msg.sender].cannotStake = false;
        }
    }

    // User Stakes Token in Smart Contract
    function stake() payable external {
        //Require that the can stake
        require(currentStakes[msg.sender].cannotStake == false, "You cannot stake!");

        // Require ETH is between 1 and 100 ETH
        require(msg.value >= 1 ether, "Sent Too Little ETH. Minimum 1 ETH");
        require(msg.value <= 100 ether, "Sent Too Much ETH. Maximum 100 ETH");

        // Create new userStake value
        userStake memory nextStake;

        nextStake.cannotStake = true;
        nextStake.etherStaked = msg.value;
        for(uint i = 0; i < tokenListLength; i++) {
            exchangeRate = tokensAndExchangeRates[tokenList[i]];
            addressAndStakeRewardsPerToken[msg.sender][tokenList[i]] = msg.value * exchangeRate;
        }
        nextStake.stakeRewardTotal = tokenListLength;
        nextStake.unlockTime = block.timestamp + lockedTimeMinutes;

        currentStakes[msg.sender] = nextStake;

        // Emit Staking Event
        emit userStaked(msg.sender, msg.value);
    }

    //User withdraws full stake from contract
    function withdrawStake() payable external checkRestake {
        //Check Time Requirement
        require(block.timestamp >= currentStakes[msg.sender].unlockTime, "Cannot Withdraw Yet");
        require(currentStakes[msg.sender].etherStaked > 0, "No Value to Unstake");

        uint256 userStakedAmount = currentStakes[msg.sender].etherStaked;
        currentStakes[msg.sender].etherStaked = 0;

        (bool success, ) = msg.sender.call{value: userStakedAmount}("");
        require(success, "Call Failed");

        //Emit Withdraw Event
        emit userWithdrawStake(msg.sender, userStakedAmount);
    }

    //User withdraws full stake reward from contract
    function withdrawReward() external checkRestake {
        //Check Time Requirement
        require(block.timestamp >= currentStakes[msg.sender].unlockTime, "Cannot Withdraw Yet");
        require(currentStakes[msg.sender].stakeRewardTotal > 0, "No Stake Reward to Claim");

        uint256 givenStakeReward = currentStakes[msg.sender].stakeRewardTotal;
        
        for(uint i = 0; i < tokenListLength; i++) {
            uint256 userRewardAmount = addressAndStakeRewardsPerToken[msg.sender][tokenList[i]];
            tokenList[i].transfer(msg.sender, userRewardAmount);
        }

        currentStakes[msg.sender].stakeRewardTotal = 0;

        //Emit Withdraw Event
        emit userWithdrawReward(msg.sender, givenStakeReward);
    }

}
