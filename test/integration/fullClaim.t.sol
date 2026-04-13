// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {MintableERC20} from "../../contracts/test/MintableERC20.sol";
import {IMerkleDistributor} from "../../contracts/interfaces/IMerkleDistributor.sol";
import {MerkleDistributor} from "../../contracts/MerkleDistributor.sol";
import {TestMerkleTree} from "../utils/TestMerkleTree.sol";

contract MerkleDistributorClaimTest is Test, TestMerkleTree {

    event Claimed(uint256 index, address account, uint256 amount);

    address token;
    bytes32 root;

    MerkleDistributor distributor;

    function setUp() external {
        MintableERC20 tokenContract = new MintableERC20("Test Token", "TTK");
        token = address(tokenContract);
        root = MERKLE_ROOT;
        distributor = new MerkleDistributor(token, root);

        uint256 toMint = 0;

        for (uint256 i = 0 ;; i++) {
            if (claims[i].proof.length == 0) {
                break;
            }

            toMint += claims[i].amount;
        }

        vm.assertGt(toMint, 0);
        
        tokenContract.mint(address(distributor), toMint);
    }

    function testFullClaim() external {
        for (uint256 i = 0;; i++) {
            Claim memory claim = claims[i];

            if (claim.proof.length == 0) {
                break;
            }

            vm.expectEmit(true, true, true, true, address(distributor));
            emit Claimed(claim.index, claim.account, claim.amount);

            distributor.claim(claim.index, claim.account, claim.amount, claim.proof);

            // It should mark the leaf as claimed
            vm.assertEq(distributor.isClaimed(claim.index), true);

            // It should transfer the specified amount to the claimant
            vm.assertEq(MintableERC20(distributor.token()).balanceOf(claim.account), claim.amount);
        }

        // The distributor should have zero balance
        vm.assertEq(MintableERC20(distributor.token()).balanceOf(address(distributor)), 0);
    }

    
}
