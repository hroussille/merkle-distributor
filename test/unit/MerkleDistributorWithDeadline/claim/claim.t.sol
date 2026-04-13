// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {MintableERC20} from "contracts/test/MintableERC20.sol";
import {IMerkleDistributor} from "contracts/interfaces/IMerkleDistributor.sol";
import {MerkleDistributorWithDeadline} from "contracts/MerkleDistributorWithDeadline.sol";
import {TestMerkleTree} from "../../../utils/TestMerkleTree.sol";

contract MerkleDistributorWithDeadlineClaimTest is Test, TestMerkleTree {

    event Claimed(uint256 index, address account, uint256 amount);

    address token;
    bytes32 root;
    Claim claim;

    MerkleDistributorWithDeadline distributor;

    function setUp() external {
        MintableERC20 tokenContract = new MintableERC20("Test Token", "TTK");
        token = address(tokenContract);
        root = MERKLE_ROOT;
        distributor = new MerkleDistributorWithDeadline(token, root, block.timestamp + 1 days);
        tokenContract.mint(address(distributor), type(uint256).max);
        claim = claims[0];
    }

    function test_RevertWhen_TheDeadlineHasPassed() external {
        vm.warp(distributor.endTime() + 1);

        // It should revert
        vm.expectRevert(IMerkleDistributor.ClaimWindowFinished.selector);
        distributor.claim(claim.index, claim.account, claim.amount, claim.proof);
    }

    modifier whenTheDeadlineHasNotPassed() {
        _;
    }

    modifier whenTheLeafHasNotBeenClaimed() {
        vm.assertEq(distributor.isClaimed(claim.index), false);
        _;
    }

    function test_RevertWhen_TheProofIsInvalid() external whenTheDeadlineHasNotPassed whenTheLeafHasNotBeenClaimed {
        // It should revert
        vm.assertEq(distributor.isClaimed(claim.index), false);
        vm.expectRevert(IMerkleDistributor.InvalidProof.selector);
        distributor.claim(claim.index, claim.account, claim.amount, new bytes32[](0));
    }

    function test_WhenTheProofIsValid() external whenTheDeadlineHasNotPassed whenTheLeafHasNotBeenClaimed {
        vm.assertEq(distributor.isClaimed(0), false);
        vm.assertEq(claim.index, 0);

        // It should emit a Claimed event
        vm.expectEmit(true, true, true, true, address(distributor));
        emit Claimed(claim.index, claim.account, claim.amount);

        distributor.claim(claim.index, claim.account, claim.amount, claim.proof);

        // It should mark the leaf as claimed
        vm.assertEq(distributor.isClaimed(0), true);

        // It should transfer the specified amount to the claimant
        vm.assertEq(MintableERC20(distributor.token()).balanceOf(claim.account), claim.amount);
    }

    modifier whenTheLeafHasBeenClaimed() {
        distributor.claim(claim.index, claim.account, claim.amount, claim.proof);
        vm.assertEq(distributor.isClaimed(claim.index), true);
        _;
    }

    function test_RevertWhen_TheLeafHasBeenClaimed() external whenTheDeadlineHasNotPassed whenTheLeafHasBeenClaimed {
        // It should revert
        vm.expectRevert(IMerkleDistributor.AlreadyClaimed.selector);
        distributor.claim(claim.index, claim.account, claim.amount, claim.proof);
    }
}
