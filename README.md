# crikeyooo

/scripts - local run scripts to test contract
/sample - sample contracts for quick reference, to be deleted

## init

for proof of concept scripts to run, need config.json with the following. both accounts need eth on goerli
```
{
  "mainnetRpc": "...",
  "goerliRpc": "...",
  "user1": {
    "address": "...",
    "pkey": "...",
  },
  "user2": {
    "address": "...",
    "pkey": "...",
  }
}
```

## TODO
- Proof of Concept Scripts -- IN PROGRESS
  - Need to see if LP are transferable on mint/burn
  - If not, team is working on a way to trasfer
  - Possibility of using "permissioned pools"
- Crikey Token Contract
  - Deploy to Goerli and and test LP on Goerli CrocSwap

- Ambient Crikey/Eth Staking Rewards Contract -- Awaiting PoC + Team Response
  - IF LP CAN BE TRANSFERRED VIA ERC20
    - The simple scenario, follows the same pattern as every uniV2/sushiswap liquidity mining program. Ideal, as user interacts directly with CrocSwap contracts on mint and burn, increasing airdrop reward qualifications.
  - IF LP CAN BE TRANSFERRED ON MINT/BURN VIA LPCONDUIT
    - Users can LP from our frontend which has a custom call to CrocSwap LP mint function (hardcoded lpConduit field to send LP to the staking contract). User calls "stake" function on StakingContract, which confirms that it has received the LP from the user, and user begins accuring rewards.
      - !!IT MAY NOT BE POSSIBLE TO CONFIRM THAT A USER HAS SENT AN LP!!
    - User calls "unstake" to StakingContract which then calls LP burn to crocswap, and returns the underlying collateral to the user along with any accrued rewards
    - This is slightly less ideal as the user only interacts with CrocSwap once on mint, potentially decreasing airdrop reward activity
  - IF LP CANNOT BE TRANSFERRED, CrikeyStaking Contract can wrap the CrocSwap mint/burn function.
    - "stake" function, which takes collateral from user and mints a new ambient Crikey/Eth CrocSwap LP. User becomes eligible for staking rewards
    - "unstake" function, which calls CrocSwap burn and returns underlying collateral along with any remaining staking rewards
    - This is the least ideal scenario as the end user does not interact directly with CrocSwap contracts, potentially excluding them from airdrop rewards
- Concentrated Liq Crikey/Eth Staking Rewards Contract
  - Same as above, but for concentrated liqudity positions
- "Zap" Eth -> Crikey/Eth LP Contract/function
  - Wrapper contract/function that takes raw ETH from user, buys Crikey with half, and then mints an ambient LP
- Vesting Rewards Contract
  - Simple contract to vest team token rewards over a period of time
- Frontend

## lpConduit
- Does not seem functional via PoC