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
    uint256 totalSupply = 100000000 * 10 ** 18;

    function setUp() public {
        testToken = new CrikeyToken("Crikey Token", "CRIKEY", 18);
        testLpToken = new CrikeyAmbientLpConduit(crocswap, address(0), 0xa6024a169C2fC6BFD0fEabEe150b86d268aAf4CE, 36000);
        testRewards = new CrikeyRewards(IERC20(address(testToken)), IERC20(address(testLpToken)));
    }

    function test_SetRewardParams() public {
        uint128 reward = 10000000;
        uint64 duration = 1000000;
        uint256 expectedRewardRate = reward / duration;

        testToken.transfer(address(testRewards), reward);
        testRewards.setRewardParams(reward, duration);
        assertEq(testRewards.rewardRate(), expectedRewardRate);
    }

    function test_RejectSetRewardsParamsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert("UNAUTHORIZED");
        testRewards.setRewardParams(10000000, 1000000);
    }

    function test_RejectSetRewardsParamsIfNotEnoughReward() public {
        testToken.transfer(address(testRewards), 1000);
        vm.expectRevert("Not enough tokens");
        testRewards.setRewardParams(10000000, 1000000);
    }

    function test_Stake() public {
        testToken.transfer(address(testRewards), 10000);
        testRewards.setRewardParams(10000, 100);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, 1000, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), 1000);
        testRewards.stake(1000);

        assertEq(testLpToken.balanceOf(user), 0);
        assertEq(testLpToken.balanceOf(address(testRewards)), 1000);
    }

    function test_StakeFor() public {
        address user2 = address(0x2);

        testToken.transfer(address(testRewards), 10000);
        testRewards.setRewardParams(10000, 100);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, 1000, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), 1000);
        testRewards.stakeFor(user2, 1000);

        vm.warp(51);
        assertEq(testLpToken.balanceOf(user), 0);
        assertEq(testLpToken.balanceOf(address(testRewards)), 1000);

        vm.startPrank(user2);
        testRewards.withdraw(1000);
        assertEq(testLpToken.balanceOf(user2), 1000);
        assertEq(testRewards.earned(user2), 5000);
    }

    function test_GetRewards() public {
        testToken.transfer(address(testRewards), 10000);
        testRewards.setRewardParams(10000, 100);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, 1000, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), 1000);
        testRewards.stake(1000);

        vm.warp(51);
        assertEq(testRewards.earned(user), 5000);
        assertEq(testToken.balanceOf(user), 0);
        
        testRewards.getReward();
        assertEq(testRewards.earned(user), 0);
        assertEq(testToken.balanceOf(user), 5000);

    }

    function test_Withdraw() public {
        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, 1000, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), 1000);
        testRewards.stake(1000);

        assertEq(testLpToken.balanceOf(user), 0);
        testRewards.withdraw(500);
        assertEq(testLpToken.balanceOf(user), 500);
        testRewards.withdraw(500);
        assertEq(testLpToken.balanceOf(user), 1000);
    }

    function test_Exit() public {
        testToken.transfer(address(testRewards), 10000);
        testRewards.setRewardParams(10000, 100);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, 1000, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), 1000);
        testRewards.stake(1000);

        vm.warp(51);
        testRewards.exit();

        assertEq(testToken.balanceOf(user), 5000);
        assertEq(testLpToken.balanceOf(user), 1000);
    }

    function test_Earned() public {
        testToken.transfer(address(testRewards), 10000);
        testRewards.setRewardParams(10000, 100);

        vm.prank(crocswap);
        testLpToken.depositCrocLiq(user, poolHash, 0, 0, 1000, 0);

        vm.startPrank(user);
        testLpToken.approve(address(testRewards), 1000);
        testRewards.stake(1000);

        assertEq(testRewards.earned(user), 0);
        vm.warp(51);
        assertEq(testRewards.earned(user), 5000);
        vm.warp(101);
        assertEq(testRewards.earned(user), 10000);
    }

    function test_RewardPerToken() public {

    }

    function test_LastTimeRewardApplicable() public {

    }
}
