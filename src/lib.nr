//! Sparse Merkle Tree verification for Noir, compatible with iden3/circomlib.
//!
//! Verifies **inclusion** and **non-membership** proofs against a Poseidon
//! Sparse Merkle Tree whose roots are produced by circomlib's `SMTVerifier`
//! toolchain (e.g. `circomlibjs`' `newMemEmptyTrie`). Poseidon is the
//! `noir-lang/poseidon` crate, which is bit-compatible with circomlib, so
//! trees built off-circuit verify here unchanged.
//!
//! The crate is split into the same independent components as circomlib, each
//! separately testable:
//!   - [`hash`]     leaf `H(key, value, 1)` and node `H(L, R)`
//!   - [`levins`]   the one-hot "insertion level" derived from the siblings
//!   - [`sm`]       the per-level verifier state machine
//!   - [`level`]    the per-level root (hash up / leaf / zero)
//!   - [`verifier`] [`verifier::smt_verify`], which composes the above
//!
//! Algorithm: iden3/circomlib `SMTVerifier` (see circomlib `circuits/smt`).
//! This is an independent Noir implementation of that algorithm.

pub mod hash;
pub mod levins;
pub mod sm;
pub mod level;
pub mod verifier;

pub use verifier::smt_verify;
