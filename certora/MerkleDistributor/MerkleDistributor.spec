using ERC20 as token;

// The MerkleDistributor specification
methods {
    function token() external returns (address) envfree;
    function merkleRoot() external returns (bytes32) envfree;
    function isClaimed(uint256 index) external returns (bool) envfree;
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
    function MerkleProof.verify(bytes32[] memory, bytes32, bytes32) internal returns (bool) => _verifyResult;
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.allowance(address, address) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
}

// Ghost to mock the verification return value of the MerkleProof library
// We make it persistent to avoid it being havoc'ed in case of reverting call.
persistent ghost bool _verifyResult;

// Ghost to track the claimed status of indices in a bitmap form
ghost mapping(mathint => mapping(mathint => bool)) _bitmap {
    init_state axiom forall uint256 wordIndex. forall uint256 bitIndex. _bitmap[wordIndex][bitIndex] == false;
}

hook Sstore claimedBitMap[KEY uint256 wordIndex] uint256 newValue (uint256 oldValue) {
    uint256 bitIndex;

    // Note: in CVL ^ is exponentiation, not XOR. Use xor keyword for bitwise XOR.
    // TODO: PR to include it in the language sytanx highlighting ?
    require (newValue == oldValue) || (newValue xor oldValue) == (1 << bitIndex);
    require bitIndex < 256;

    if (newValue != oldValue) {
        _bitmap[wordIndex][bitIndex] = true;
    }
}

// Helper function to compute the word index and bit index for a given claim index
function ghostIsClaimed(uint256 index) returns bool {
    return _bitmap[index / 256][index % 256];
}

// Invariant to ensure that the ghost bitmap accurately reflects the claimed status of indices
invariant bitmap_reflects_claimed_status(uint256 index)
    isClaimed(index) == ghostIsClaimed(index);

// 1) Monotinicity of isClaimed: if isClaimed(index) == true, then isClaimed(index) == true for all future calls with the same index
rule monotonicity_of_isClaimed(method f) {

    // Snapshot isClaimed before performing the call for index
    uint256 index;

    // Ensure that the invariant holds before the call is performed
    requireInvariant bitmap_reflects_claimed_status(index);
    bool isClaimedBefore = isClaimed(index);

    // Perform a call to potentially change the state of isClaimed for a specific index
    env e;
    calldataarg args;
    f(e, args);

    // Ensure that the invariant holds after the call is performed
    requireInvariant bitmap_reflects_claimed_status(index);

    // Assert that if isClaimed was true before, it remains true after the call
    assert isClaimedBefore => isClaimed(index);
}

// 2) Double claim : if isClaimed(index) == true, then claim(index, account, amount, merkleProof) should revert
rule no_double_claims() {
    uint256 index;
    env e;

    requireInvariant bitmap_reflects_claimed_status(index); // Ensure the invariant holds for the index
    require isClaimed(index); // Assume index is claimed for the sake of the rule

    // Attempt to claim the same index again, which should revert

    address account;
    uint256 amount;
    bytes32[] merkleProof;
    claim@withrevert(e, index, account, amount, merkleProof);

    assert lastReverted;
}

// 3) Claim : only claim can decrease the contract balance & increase the account balance
rule claim_effect_on_balances(method f) filtered { f -> f.contract != token } {
    env e;

    require token.allowance(e, currentContract, e.msg.sender) == 0;
    require e.msg.sender != currentContract;

    uint256 balanceBefore = token.balanceOf(e, currentContract);

    calldataarg args;
    f(e, args);

    uint256 balanceAfter = token.balanceOf(e, currentContract);

    assert balanceAfter < balanceBefore => f.selector == sig:claim(uint256, address, uint256, bytes32[]).selector;
}

// 4) Claim validity : successful claims should only be possible if the merkle proof is valid
rule claim_validity() {
    env e;
    calldataarg args;

    claim@withrevert(e, args);

    assert !_verifyResult => lastReverted;
}

// 5) Claim transfers the correct amount of tokens from the contract to the claimant
rule claim_transfers_correct_amount() {
    env e;
    uint256 index;
    address account;
    uint256 amount;
    bytes32[] merkleProof;

    require e.msg.sender != account;
    require account != currentContract;
    require account != 0;
    require amount > 0;

    uint256 accountBefore = token.balanceOf(e, account);
    uint256 contractBefore = token.balanceOf(e, currentContract);

    claim(e, index, account, amount, merkleProof);

    assert token.balanceOf(e, account) == accountBefore + amount;
    assert token.balanceOf(e, currentContract) == contractBefore - amount;
}

// 6) Bitmap is correctly set upon claiming
rule bitmap_correctly_set(uint256 index) {
    env e;
    address account;
    uint256 amount;
    bytes32[] merkleProof;

    claim(e, index, account, amount, merkleProof);

    assert _bitmap[index / 256][index % 256] == true;
}
