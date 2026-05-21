import "../MerkleDistributor/MerkleDistributor.spec";

use rule monotonicity_of_isClaimed;
use rule no_double_claims;
use rule claim_validity;
use rule bitmap_correctly_set;
use invariant bitmap_reflects_claimed_status;

// The MerkleDistributor specification
methods {
    function endTime() external returns (uint256) envfree;
    function owner() external returns (address) envfree;
}

// 3') Claim : only claim can decrease the contract balance pre-expiry , only withdraw can decrease the contract balance post-expiry
rule claim_effect_on_balances(method f) filtered { f -> f.contract != token } {
    env e;

    uint256 balanceBefore = token.balanceOf(e, currentContract);

    calldataarg args;
    f(e, args);

    uint256 balanceAfter = token.balanceOf(e, currentContract);

    assert balanceAfter < balanceBefore => ((f.selector == sig:claim(uint256, address, uint256, bytes32[]).selector && e.block.timestamp <= endTime()) || (f.selector == sig:withdraw().selector && e.block.timestamp >= endTime() && e.msg.sender == owner() && balanceAfter == 0));
}

// 5') Claim transfers the correct amount of tokens from the contract to the claimant pre-expiry, Withdraw transfers the full balance to the owner post-expiry
rule claim_transfers_correct_amount() {
    env e;
    uint256 index;
    address account;
    uint256 amount;
    bytes32[] merkleProof;

    require account != currentContract;
    require account != 0;

    uint256 accountBefore = token.balanceOf(e, account);
    uint256 contractBefore = token.balanceOf(e, currentContract);

    claim(e, index, account, amount, merkleProof);

    assert token.balanceOf(e, account) == accountBefore + amount;
    assert token.balanceOf(e, currentContract) == contractBefore - amount;
}

rule claim_liveness_pre_expiry() {
    env e;
    uint256 index;
    address account;
    uint256 amount;
    bytes32[] merkleProof;

    bool isClaimedBefore = isClaimed(index);

    // The claim is not already clamed and the proof is valid pre-expiry
    require isClaimed(index) == false;
    require _verifyResult == true;
    require e.block.timestamp < endTime();

    // The tx has no value and the MerkleDistributor contract has enough balance to transfer the claimed amount
    require e.msg.value == 0;
    require token.balanceOf(e, currentContract) >= amount;

    // The recipient account is not the zero address and not the contract itself
    require account != 0;

    claim@withrevert(e, index, account, amount, merkleProof);

    // If the claim is valid and not already claimed, it never revert
    assert !lastReverted;
}

// 7) claim should not be possible after the deadline
rule no_claim_after_expiry() {
    env e;

    require e.block.timestamp > endTime();

    uint256 index;
    address account;
    uint256 amount;
    bytes32[] proof;

    claim@withrevert(e, index, account, amount, proof);

    assert lastReverted;
}

// 8) Withdraw should not be possible before the deadline
rule no_withdraw_before_expiry() {
    env e;

    require e.block.timestamp < endTime();

    withdraw@withrevert(e);

    assert lastReverted;
}

// 9) Withdraw should only be possible by the owner after the deadline
rule withdraw_succeeds_after_expiry() {
    env e;

    require e.msg.value == 0;
    require currentContract.owner() != 0 && currentContract.owner() != currentContract;
    require e.msg.sender == owner();
    require e.block.timestamp >= endTime();

    withdraw@withrevert(e);

    assert !lastReverted;
}

// 10) Withdraw should transfer the full balance to the owner
rule withdraw_transfers_full_balance() {
    env e;

    require owner() != 0 && owner() != currentContract;

    uint256 contractBalanceBefore = token.balanceOf(e, currentContract);
    uint256 ownerBalanceBefore = token.balanceOf(e, owner());

    withdraw(e);

    assert token.balanceOf(e, currentContract) == 0;
    assert token.balanceOf(e, owner()) == ownerBalanceBefore + contractBalanceBefore;
}
