//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

contract CrikeyRewards is Owned {
    IERC20 public rewardToken;
    IERC20 public stakedToken;

    uint64 public lastUpdateTime;
    uint64 public periodFinish;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public totalStaked;

    struct UserRewards {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    mapping(address => uint256) public stakedBalance;
    mapping(address => UserRewards) public userRewards;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken) Owned(msg.sender) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
    }

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

    function stake(uint256 _amount) external {
        stakeFor(msg.sender, _amount);
    }

    function stakeFor(address forWhom, uint256 _amount) public updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        require(stakedToken.transferFrom(msg.sender, address(this), _amount), "Insufficient balance");
        unchecked {
            totalStaked += _amount;
            stakedBalance[forWhom] += _amount;
        }
        emit Staked(forWhom, _amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function withdraw(uint256 _amount) public updateReward(msg.sender) {
        require(_amount <= stakedBalance[msg.sender], "withdraw: balance is lower");
        unchecked {
            stakedBalance[msg.sender] -= _amount;
            totalStaked = totalStaked - _amount;
        }
        require(stakedToken.transfer(msg.sender, _amount), "Error transfering reward balance");
        emit Withdrawn(msg.sender, _amount);
    }

    function exit() external {
        getReward();
        withdraw(stakedBalance[msg.sender]);
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

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: YFIRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/
