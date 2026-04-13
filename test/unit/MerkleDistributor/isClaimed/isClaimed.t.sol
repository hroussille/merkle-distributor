// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {MintableERC20} from "contracts/test/MintableERC20.sol";
import {MerkleDistributor} from "contracts/MerkleDistributor.sol";
import {TestMerkleTree} from "../../../utils/TestMerkleTree.sol";

contract MerkleDistributorIsClaimedTest is Test, TestMerkleTree {

    event Claimed(uint256 index, address account, uint256 amount);

    address token;
    bytes32 root;
    Claim claim;

    MerkleDistributor distributor;

    function setUp() external {
        MintableERC20 tokenContract = new MintableERC20("Test Token", "TTK");
        token = address(tokenContract);
        root = MERKLE_ROOT;
        distributor = new MerkleDistributor(token, root);
        tokenContract.mint(address(distributor), type(uint256).max);
        claim = claims[0];
    }

    function test_WhenTheLeafHasNotBeenClaimed() external view {
        // It should return False
        vm.assertEq(distributor.isClaimed(claim.index), false);
    }

    function test_WhenTheLeafHasBeenClaimed() external {
        distributor.claim(claim.index, claim.account, claim.amount, claim.proof);
        vm.assertEq(distributor.isClaimed(claim.index), true);

        // It should return True
        vm.assertEq(distributor.isClaimed(claim.index), true);
    }
}