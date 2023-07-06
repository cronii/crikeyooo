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
    uint256 totalSupply = 100000000 * 10 ** 18;

    function setUp() public {
        testToken = new CrikeyToken("Crikey Token", "CRIKEY", 18);
        testLpToken = new CrikeyAmbientLpConduit(address(0xBEEF), address(0), 0xa6024a169C2fC6BFD0fEabEe150b86d268aAf4CE, 36000);
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
        vm.prank(address(0xBEEF));
        vm.expectRevert("UNAUTHORIZED");
        testRewards.setRewardParams(10000000, 1000000);
    }

    function test_RejectSetRewardsParamsIfNotEnoughReward() public {
        testToken.transfer(address(testRewards), 1000);
        vm.expectRevert("Not enough tokens");
        testRewards.setRewardParams(10000000, 1000000);
    }

    function test_WithdrawRewards() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert("UNAUTHORIZED");
        testRewards.withdrawReward();
    }

    function test_RejectWithdrawRewardsIfNotOwner() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert("UNAUTHORIZED");
        testRewards.withdrawReward();
    }

    function test_GetRewards() public {
        
    }

    function test_Exit() public {

    }

    function test_Stake() public {

    }

    function test_StakeFor() public {

    }

    function test_Withdraw() public {
        
    }

    function test_Earned() public {

    }

    function test_RewardPerToken() public {

    }

    function test_LastTimeRewardApplicable() public {

    }
}
