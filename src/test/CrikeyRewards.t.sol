// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {CrikeyRewards, IERC20} from "../CrikeyRewards.sol";
import {CrikeyAmbientLpConduit} from "../CrikeyAmbientLpConduit.sol";
import {CrikeyToken} from "../CrikeyToken.sol";

contract CrikeyRewardsTest is Test {
    CrikeyToken testToken;
    CrikeyAmbientLpConduit testLpToken;
    CrikeyRewards testRewards;
    address deployer = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address crocswap = address(0xBEEF);
    address user = address(0x1);
    bytes32 poolHash = 0xf14b97521d2ba8399ee7b9be53ec1eb470416373ed113505baff7e5a63825ced;
    uint128 reward = 1000e18;
    uint128 lpTokens = 1000e18;
    uint64 duration = 3000000;

    function setUp() public {
        testToken = new CrikeyToken("Crikey Token", "CRIKEY", 18);
        testLpToken =
            new CrikeyAmbientLpConduit(crocswap, address(0), 0xa6024a169C2fC6BFD0fEabEe150b86d268aAf4CE, 36000);
        testRewards = new CrikeyRewards(IERC20(address(testToken)), IERC20(address(testLpToken)));
    }

    function test_SetRewardParams() public {
        uint256 expectedRewardRate = reward / duration;

        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);
        assertEq(testRewards.rewardRate(), expectedRewardRate);
        assertEq(testRewards.periodFinish(), duration + 1);
    }

    function test_RejectSetRewardsParamsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert("UNAUTHORIZED");
        testRewards.setRewardParams(reward, duration);
    }

    function test_RejectSetRewardsParamsIfNotEnoughReward() public {
        testToken.transfer(address(testRewards), 1000);
        vm.expectRevert("Not enough tokens");
        testRewards.setRewardParams(reward, duration);
    }

    function test_Stake() public {
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        assertEq(testLpToken.balanceOf(user), 0);
        assertEq(testRewards.totalStaked(), lpTokens);
        assertEq(testLpToken.balanceOf(address(testRewards)), lpTokens);
    }

    function test_StakeFor() public {
        address user2 = address(0x2);

        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stakeFor(user2, lpTokens);

        vm.warp(duration / 2 + 1);
        assertEq(testLpToken.balanceOf(user), 0);
        assertEq(testLpToken.balanceOf(address(testRewards)), lpTokens);

        vm.startPrank(user2);
        testRewards.exit();
        assertEq(testLpToken.balanceOf(user2), lpTokens);
        assertApproxEqRel(testToken.balanceOf(user2), reward / 2, 0.01e18);
    }

    function test_GetRewards() public {
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        vm.warp(duration / 2 + 1);
        assertApproxEqRel(testRewards.earned(user), reward / 2, 0.01e18);
        assertEq(testToken.balanceOf(user), 0);

        testRewards.getReward();
        assertEq(testRewards.earned(user), 0);
        assertApproxEqRel(testToken.balanceOf(user), reward / 2, 0.01e18);
    }

    function test_Withdraw() public {
        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        assertEq(testLpToken.balanceOf(user), 0);
        testRewards.withdraw(lpTokens / 2);
        assertEq(testLpToken.balanceOf(user), lpTokens / 2);
        testRewards.withdraw(lpTokens / 2);
        assertEq(testLpToken.balanceOf(user), lpTokens);
    }

    function test_Exit() public {
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        vm.warp(duration / 2 + 1);
        testRewards.exit();

        assertApproxEqRel(testToken.balanceOf(user), reward / 2, 0.01e18);
        assertEq(testLpToken.balanceOf(user), lpTokens);
    }

    function test_FuzzExit(uint120 amount) public {
        vm.assume(amount > 0);
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, amount, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), amount);
        testRewards.stake(amount);

        vm.warp(duration / 2 + 1);
        testRewards.exit();

        assertApproxEqRel(testToken.balanceOf(user), reward / 2, 0.01e18);
        assertEq(testLpToken.balanceOf(user), amount);
    }

    function test_Earned() public {
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        assertEq(testRewards.earned(user), 0);
        vm.warp(duration / 2 + 1);
        assertApproxEqRel(testRewards.earned(user), reward / 2, 0.01e18);
        vm.warp(duration + 1);
        assertApproxEqRel(testRewards.earned(user), reward, 0.01e18);
    }

    function test_LastTimeRewardApplicable() public {
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        assertEq(testRewards.lastTimeRewardApplicable(), 1);
        vm.warp(51);
        assertEq(testRewards.lastTimeRewardApplicable(), 51);
        vm.warp(duration);
        assertEq(testRewards.lastTimeRewardApplicable(), duration);
        vm.warp(duration + 100);
        assertEq(testRewards.lastTimeRewardApplicable(), duration + 1);
    }

    function test_RewardPerToken() public {
        assertEq(testRewards.rewardPerToken(), 0);

        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        assertEq(testRewards.rewardPerToken(), 0);
        vm.warp(duration / 2 + 1);
        testRewards.getReward();
        assertApproxEqRel(testRewards.rewardPerToken(), 5e17, 0.01e18);
        vm.warp(duration + 1);
        testRewards.getReward();
        assertApproxEqRel(testRewards.rewardPerToken(), 10e17, 0.01e18);
    }

    function test_StakedBalance() public {
        address user2 = address(0x2);
        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);

        vm.startPrank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, lpTokens, 0);
        testLpToken.depositCrocLiq(user2, poolHash, 0, 0, 500e18, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), lpTokens);
        testRewards.stake(lpTokens);

        vm.startPrank(user2);
        testLpToken.approve(address(testRewards), 500e18);
        testRewards.stake(500e18);

        assertEq(testRewards.stakedBalance(user), lpTokens);
        assertEq(testRewards.stakedBalance(user2), 500e18);
        assertEq(testRewards.totalStaked(), lpTokens + 500e18);
    }
}
