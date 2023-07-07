# run commands individually

forge create CrikeyToken --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args "Crikey" "CRIKEY" 18

export CRIKEY_TOKEN_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
export USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 # deployer
export CROCSWAP_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 # user 2

forge create CrikeyAmbientLpConduit --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args $CROCSWAP_ADDRESS 0x0000000000000000000000000000000000000000 $CRIKEY_TOKEN_ADDRESS 36000

export CRIKEY_AMBIENT_LP_TOKEN_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

# cast send $CRIKEY_AMBIENT_LP_TOKEN_ADDRESS --private-key=$PRIVATE_KEY "setCrocswap(address)" $CROCSWAP_ADDRESS

forge create CrikeyRewards --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args $CRIKEY_TOKEN_ADDRESS $CRIKEY_AMBIENT_LP_TOKEN_ADDRESS

export CRIKEY_AMBIENT_REWARDS_ADDRESS=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

forge create LinearVester --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args $CRIKEY_TOKEN_ADDRESS

export LINEAR_VESTER_ADDRESS=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

cast call $CRIKEY_TOKEN_ADDRESS "balanceOf(address)" $USER_ADDRESS
cast send $CRIKEY_TOKEN_ADDRESS --private-key=$PRIVATE_KEY "transfer(address, uint256)" $CRIKEY_AMBIENT_REWARDS_ADDRESS 50000000000000000000000000

cast send $CRIKEY_AMBIENT_REWARDS_ADDRESS --private-key=$PRIVATE_KEY "setRewardParams(uint256, uint64)" 50000000000000000000000000 604800

cast call $CRIKEY_AMBIENT_LP_TOKEN_ADDRESS "poolHash()"
cast send $CRIKEY_AMBIENT_LP_TOKEN_ADDRESS --private-key=$PRIVATE_KEY2 "depositCrocLiq(address,bytes32,int24,int24,uint128,uint64)" $USER_ADDRESS 0x4fc5f54c05ae2a288f293307f6b12973c7c8e16a68c1bd06346e60bcee9dd1d7 0 0 10000000000000000000 0
cast call $CRIKEY_AMBIENT_LP_TOKEN_ADDRESS "balanceOf(address)" $USER_ADDRESS
cast send $CRIKEY_AMBIENT_LP_TOKEN_ADDRESS --private-key=$PRIVATE_KEY "approve(address, uint256)" $CRIKEY_AMBIENT_REWARDS_ADDRESS 10000000000000000000

cast send $CRIKEY_AMBIENT_REWARDS_ADDRESS --private-key=$PRIVATE_KEY "stake(uint256)" 10000000000000000000

cast call $CRIKEY_AMBIENT_REWARDS_ADDRESS "stakedBalance(address)" $USER_ADDRESS
cast call $CRIKEY_AMBIENT_REWARDS_ADDRESS "earned(address)" $USER_ADDRESS

# forge create CrikeyRangeLpConduit --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args 0x0000000000000000000000000000000000000000 $CRIKEY_TOKEN_ADDRESS 36000
# forge create CrikeyRewards --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args $CRIKEY_TOKEN_ADDRESS $CRIKEY_RANGE_LP_TOKEN_ADDRESS