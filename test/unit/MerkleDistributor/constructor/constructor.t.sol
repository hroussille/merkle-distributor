// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {MerkleDistributor} from "contracts/MerkleDistributor.sol";

contract MerkleDistributorConstructorTest is Test {

    address token;
    bytes32 root;

    MerkleDistributor distributor;

    function setUp() external {
        token = makeAddr("Token");
        root = keccak256(abi.encodePacked("merkle root"));
        distributor = new MerkleDistributor(token, root);
    }

    function test_ShouldSetTheTokenToTheProvidedAddress() external view {
        // It should set the token to the provided address
        vm.assertEq(distributor.token(), token);
    }

    function test_ShouldSetTheMerkleRootToTheGivenRoot() external view {
        // It should set the merkle root to the given root
        vm.assertEq(distributor.merkleRoot(), root);
    }
}
