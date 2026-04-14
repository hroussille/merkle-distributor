# Merkle Claim Distributor

A minimal, auditable implementation of a Merkle-based token claim distributor heavily based on Uniswap's [merkle-distributor](https://github.com/Uniswap/merkle-distributor/tree/master), formally verified with Certora and fully tested with Foundry.

This repository provides two contract variants:

- **`MerkleDistributor`** : permissionless, no expiry. Any address with a valid Merkle proof can claim once.
- **`MerkleDistributorWithDeadline`** : extends the base with a deadline and an owner-only `withdraw()` function to recover unclaimed tokens after expiry.

Both variants implement double-hashed leaf nodes to prevent [second preimage attacks](https://rareskills.io/post/merkle-tree-second-preimage-attack). Anyone modifying the leaf format should preserve this property.

**Test coverage:** 100% line, branch, and function coverage on contract code (`forge coverage`). All mutation mutants caught (`certoraMutate`).

## Dependencies

- Node.js >= 18
- [Foundry](https://github.com/foundry-rs/foundry)
- [Certora](https://docs.certora.com/en/latest/docs/user-guide/install.html)
- [Gambit](https://docs.certora.com/en/latest/docs/gambit/index.html)
- lcov
- genhtml

## Formal Verification (Certora)

### Verified properties

#### `MerkleDistributor`

| #   | Property                         | Kind      | Description                                                                                               |
| --- | -------------------------------- | --------- | --------------------------------------------------------------------------------------------------------- |
| 1   | `monotonicity_of_isClaimed`      | Rule      | Once an index is marked claimed, it can never be unclaimed. Verified parametrically across all functions. |
| 2   | `no_double_claims`               | Rule      | If `isClaimed(index)` is true, any call to `claim` for that index reverts.                                |
| 3   | `claim_effect_on_balances`       | Rule      | Only `claim` can decrease the contract's token balance. Verified across all distributor functions.        |
| 4   | `claim_validity`                 | Rule      | A successful `claim` call requires `MerkleProof.verify` to have returned true.                            |
| 5   | `claim_transfers_correct_amount` | Rule      | `claim` transfers the correct amount of tokens from the contract to the claimant                          |
| 6   | `bitmap_reflects_claimed_status` | Invariant | The ghost mirror of the claimed bitmap is consistent with `isClaimed()` at all times.                     |

#### `MerkleDistributorWithDeadline` (extends above)

| #   | Property                          | Kind | Description                                                                                                                                                    |
| --- | --------------------------------- | ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3′  | `claim_effect_on_balances`        | Rule | Before expiry, only `claim` can decrease the balance. After expiry, only `withdraw` can, the caller must be the owner, and the post-call balance must be zero. |
| 5′  | `claim_transfers_correct_amount`  | Rule | Before expiry, `claim` transfers the correct amount of tokens from the contract to the claimant                                                                |
| 7   | `no_claim_after_expiry`           | Rule | After expiry, `claim` will always revert.                                                                                                                      |
| 8   | `no_withdraw_before_expiry`       | Rule | Before expiry, `withdraw` will always revert.                                                                                                                  |
| 9   | `withdraw_succeeds_after_expiry`  | Rule | After expiry, `withdraw` will always succeed as long as the caller is the owner.                                                                               |
| 10  | `withdraw_transfers_full_balance` | Rule | A successful `withdraw` call always leaves the contract balance at zero.                                                                                       |

### Design notes and verification assumptions

- **Merkle proof:** `MerkleProof.verify` is summarized as a persistent ghost boolean. The specs verify state machine correctness, not cryptographic soundness.
- **Bitmap:** The packed bitmap is mirrored via a ghost mapping and `Sstore` hooks. `precise_bitwise_ops` is required to avoid SMT bitvector imprecision on `BWOr` operations.
- **ERC20:** All ERC20 calls are dispatched to a linked OZ ERC20 implementation. Non-standard tokens (fee-on-transfer, rebasing) are out of scope.

### Running formal verification

```bash
certoraRun certora/MerkleDistributor/MerkleDistributor.conf
certoraRun certora/MerkleDistributorWithDeadline/MerkleDistributorWithDeadline.conf
```

Requires a valid `CERTORAKEY` environment variable.

### Running mutation testing

Manual mutants are committed under `certora/MerkleDistributor/mutants/` and `certora/MerkleDistributorWithDeadline/mutants/`. All mutants are caught by the Certora specs.

```bash
certoraMutate certora/MerkleDistributor/MerkleDistributor.conf
certoraMutate certora/MerkleDistributorWithDeadline/MerkleDistributorWithDeadline.conf
```

Mutants were generated with [Gambit](https://docs.certora.com/en/latest/docs/gambit/index.html) and cover bitmap arithmetic, expiry boundary conditions, and transfer logic. The committed mutants are a point-in-time snapshot for the current contract version.

## Testing

**Coverage:** 100% line, branch, and function coverage on contract code. Tests are written using [BTT](https://github.com/PaulRBerg/btt-examples) description and [bulloak](https://github.com/alexfertel/bulloak) scaffolding.

### Running tests

```bash
forge test
```

## Security notes

This repository is provided for educational and research purposes. Formal verification covers the properties listed above under the stated assumptions, in particular, it does not cover cryptographic soundness of the Merkle proof, ERC20 implementation correctness, or properties outside the verified scope.

**Do not deploy to mainnet without an independent audit.**

## License

GPL-3.0-or-later
