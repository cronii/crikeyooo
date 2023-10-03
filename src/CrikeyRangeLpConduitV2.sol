// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PoolSpecs} from "CrocSwap-protocol/libraries/PoolSpecs.sol";
import {ICrocLpConduit} from "CrocSwap-protocol/interfaces/ICrocLpConduit.sol";
import "CrocSwap-protocol/lens/CrocQuery.sol";
import {Owned} from "solmate/auth/Owned.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CrikeyRangeLpConduit is Owned, ICrocLpConduit {
    address public crocLpContract;
    address public crocQueryContract;

    bytes32 public immutable poolHash;
    address public immutable baseToken;
    address public immutable quoteToken;
    uint256 public immutable poolType;

    IERC20 public rewardToken;
    uint256 public totalStaked;

    uint64 public lastUpdateTime;
    uint64 public periodFinish;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;

    struct UserRewards {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    struct RangeLP {
        int24 lowerTick;
        int24 upperTick;
    }

    // mapping of user's initial liquidity of ETH at a given tick range
    mapping(address => mapping(bytes32 => uint256)) public rangeLPs;
    mapping(address => uint256) public stakedBalance;
    mapping(address => UserRewards) public userRewards;

    constructor(address _crocLpContract, address _crocQueryContract, address base, address quote, uint256 poolIdx, IERC20 _rewardToken) Owned(msg.sender) {
        require(quote != address(0) && base != quote && quote > base, "Invalid Token Pair");

        crocLpContract = _crocLpContract;
        crocQueryContract = _crocQueryContract;
        baseToken = base;
        quoteToken = quote;
        poolType = poolIdx;
        poolHash = PoolSpecs.encodeKey(base, quote, poolIdx);
        rewardToken = _rewardToken;
    }

    modifier onlyCrocswap() {
        require(msg.sender == crocLpContract, "UNAUTHORIZED");

        _;
    }

    function setCrocswap(address _crocLpContract) public onlyOwner {
        crocLpContract = _crocLpContract;
    }

    function setCrocswapQuery(address _crocQueryContract) public onlyOwner {
        crocQueryContract = _crocQueryContract;
    }

    function depositCrocLiq(address sender, bytes32 pool, int24 lowerTick, int24 upperTick, uint128 seeds, uint64)
        public
        override
        onlyCrocswap
        returns (bool)
    {
        int256 tickRange = abs(upperTick - lowerTick);
        bytes32 tickHash = keccak256(abi.encode(lowerTick, upperTick));
        require(pool == poolHash, "Wrong pool");
        require(tickRange > 0, "Non-Range LP Deposit");
        
        // only accept out of range LP's to accurately credit initial ETH value supplied
        int24 curveTick = CrocQuery(crocQueryContract).queryCurveTick(baseToken, quoteToken, poolType);
        require(curveTick > upperTick, "LP must be out of range");
        rangeLPs[sender][tickHash] += seeds;
        stakedBalance[sender] += seeds;
        totalStaked += seeds;
        return true;
    }

    function withdrawCrocLiq(address sender, bytes32 pool, int24 lowerTick, int24 upperTick, uint128 seeds, uint64)
        public
        override
        onlyCrocswap
        returns (bool)
    {
        int256 tickRange = abs(upperTick - lowerTick);
        bytes32 tickHash = keccak256(abi.encode(lowerTick, upperTick));
        require(pool == poolHash, "Wrong pool");
        require(tickRange > 0, "Non-Range LP Deposit");
        // get ratio of (seeds to withdraw / total liquidity) and then apply to eth balance
        // liquidityBalance[sender] -= seeds;
        // require();
        uint128 reductionRate = seeds / 1000;
        rangeLPs[sender][tickHash] -= reductionRate;
        stakedBalance[sender] -= seeds;
        totalStaked -= seeds;
        return true;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - lastUpdateTime) * 1e18) / totalStaked;
    }

    function earned(address _account) public view returns (uint256) {
        return ((stakedBalance[_account] * (rewardPerToken() - userRewards[_account].userRewardPerTokenPaid)) / 1e18)
            + userRewards[_account].rewards;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        userRewards[_account].rewards  = earned(_account);
        userRewards[_account].userRewardPerTokenPaid = rewardPerTokenStored;

        _;
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setRewardParams(uint256 _reward, uint64 _duration) external onlyOwner {
        unchecked {
            require(_reward > 0);
            rewardPerTokenStored = rewardPerToken();
            uint64 blockTimestamp = uint64(block.timestamp);
            uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
            uint256 leftover = 0;
            if (blockTimestamp >= periodFinish) {
                rewardRate = _reward / _duration;
            } else {
                uint256 remaining = periodFinish - blockTimestamp;
                leftover = remaining * rewardRate;
                rewardRate = (_reward + leftover) / _duration;
            }
            require(_reward + leftover <= maxRewardSupply, "Not enough tokens");
            lastUpdateTime = blockTimestamp;
            periodFinish = blockTimestamp + _duration;
            emit RewardAdded(_reward);
        }
    }

    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        require(rewardToken.transfer(msg.sender, rewardSupply));
        rewardRate = 0;
        periodFinish = uint64(block.timestamp);
    }
}
