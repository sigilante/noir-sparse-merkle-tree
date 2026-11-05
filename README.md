# `sparse_merkle_tree`

**Status ~2026.11.5:  The code can be used but has not been vetted by a third party.**

Sparse Merkle Tree **inclusion** and **non-membership** verification for
[Noir](https://noir-lang.org), compatible with
[iden3](https://github.com/iden3)/[`circomlib`](https://github.com/iden3/circomlib)'s
`SMTVerifier`.

Roots built off-circuit by `circomlib`'s toolchain (`circomlibjs`, `smt.js`,
`newMemEmptyTrie`); the Poseidon hash is the
[`noir-lang/poseidon`](https://github.com/noir-lang/poseidon) crate, which is
bit-compatible with `circomlib` (verified against its published test vectors).

## Usage

```toml
# Nargo.toml
[dependencies]
sparse_merkle_tree = { git = "https://github.com/<owner>/noir-sparse-merkle-tree", tag = "v0.1.0" }
```

```noir
use sparse_merkle_tree::smt_verify;

// Inclusion of `key` (value `value`) in the tree rooted at `root`:
smt_verify(1, root, siblings, 0, 0, 0, key, value, 0 /* fnc = inclusion */);

// Non-membership of `key` (witness from circomlib's `find`):
smt_verify(1, root, siblings, old_key, old_value, is_old0, key, 0, 1 /* fnc */);
```

`enabled`, `is_old0` and `fnc` are field `0`/`1`. With `enabled = 1`, an invalid
proof is unsatisfiable. The witness fields (`siblings`, `old_key`, `old_value`,
`is_old0`) are exactly what circomlib's `SMTVerifier` consumes.

## Structure

The crate mirrors `circomlib`′s component decomposition, each independently
tested so it can be audited in isolation:

| module      | circomlib         | role                                    |
|-------------|-------------------|-----------------------------------------|
| `hash`      | SMTHash1/SMTHash2 | leaf `H(key,value,1)`, node `H(L,R)`    |
| `levins`    | SMTLevIns         | one-hot insertion level from siblings   |
| `sm`        | SMTVerifierSM     | per-level state machine                 |
| `level`     | SMTVerifierLevel  | per-level root contribution             |
| `verifier`  | SMTVerifier       | composes the above + the two assertions |

`verifier` also carries a differential test suite against `circomlib` vectors
(inclusion, both non-membership cases, and rejection of forged proofs).

## Compatibility

- Poseidon dependency pinned to `noir-lang/poseidon` `v0.2.6`, which compiles
  on `nargo 1.0.0-beta.19`. Bump alongside the toolchain.
- Tree depth is the const generic `N` (circomlib `nLevels`; ZeroKAD uses 32).

## Provenance and license

This implements the **iden3/circomlib `SMTVerifier` algorithm**. It is an
independent Noir implementation written from the circuit's public
specification, not a translation of circomlib's source (circomlib is GPLv3; an
algorithm is not itself copyrightable, and none of its source text is copied).

Dual-licensed for use and distribution under either of

- [MIT license](LICENSE-MIT), or
- [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

at your option. Copyright (c) 2026 Sigilante/N. E. Davis for ZeroAttest.
