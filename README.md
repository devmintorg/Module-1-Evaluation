# Module 1 Evaluation

This is the evaluation for Module 1 of the devMint Course. To initialize this repository, please run the following command:

`npm install`

You should then be able to run the following code:

`npx hardhat run ./scripts/deploy_base.sol`

... and it should complete without error.

Please clone this repository to your github, and then for each of the scenarios, create a new solidity file (for example `Scenario_1.sol`, `Scenario_2.sol`, ect.).

You are expected to complete as much of these scenario's as possible. If you have specific question, please reach out to your instructor. Once you have completed this evaluation, please push the code to your private repository (do not share this with your peers) and send it to the typeScript. Upon completion, you will be sent the answers.

## **Scenario One:** Flexible Exchange Rate and Times
How would you update this contract so that the person who deployed this contract (aka the owner) could set the locked time and exchange rate to different values?

Some considerations when writing this contract:
* You can write the contract to make your own owner, but is there a library you could access to make the work easier?
* Can you use a modifier to help simplify your code so that your new functions can only be run by the owner?

## **Scenario Two:** Multiple Token Rewards
How would you update this contract to be able to support multiple token rewards? For an example, create the stake contract to be able to reward two different tokens with independent exchange rates to reward to stakers??

Some considerations when writing this contract:
* When withdrawing rewards, can you write it in such a way that both rewards have to succeed sending before the transaction goes through?
* Do you need to create multiple versions of the token contract? Or can you re-use code to make it work?
* Do your events need to be re-written in order to notify users of the different rewards being sent? If so, how?

## **Scenario Three:** De-escalating Rewards (Challenging)
How would you update this contract to de-escalate the amount of rewards people got after a certain time? For example, let's say that for anyone that stakes in the first week the exchange rate is 100, but for the second week it's 50, the third it's 25 and it remains 10 after three weeks? The exchange rate should be defined at the time of staking, not at the time of pulling the reward.

Some considerations when writing this contract:
* You'll have to consider how you wish for your exchange rate and time data to be added to the contract. You may pull inspiration from the dustsweeper contract.
* Consider how you are going to track time in your contract. Are there any new state variables or constructs you need to add?
* How are you going to consistently track time over the contract in order to figure out what time is 'now'? (This is not so much a solidity problem as it is a general coding problem)
