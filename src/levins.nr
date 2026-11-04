//! SMTLevIns (circomlib): locate the level where the old insertion sits.
//!
//! `lev_ins` is a one-hot vector: `lev_ins[i] == 1` at the single level `i`
//! whose own and deeper siblings are all zero while its parent's sibling is
//! non-zero (the root level is treated as having a non-zero parent sibling).
//! Siblings run root-first: `siblings[0]` is nearest the root.

/// Compute the one-hot insertion level from the siblings. When `enabled` is 1,
/// asserts the deepest sibling is zero (a well-formed SMT proof).
pub fn lev_ins<let N: u32>(enabled: Field, siblings: [Field; N]) -> [Field; N] {
    let mut is_zero: [Field; N] = [0; N];
    for i in 0..N {
        is_zero[i] = (siblings[i] == 0) as Field;
    }

    // A valid proof has a zero deepest sibling when enabled.
    assert((is_zero[N - 1] - 1) * enabled == 0);

    let mut out: [Field; N] = [0; N];
    let mut done: [Field; N] = [0; N];
    out[N - 1] = 1 - is_zero[N - 2];
    done[N - 2] = out[N - 1];
    for k in 0..(N - 2) {
        let i = N - 2 - k; // N-2 down to 1
        out[i] = (1 - done[i]) * (1 - is_zero[i - 1]);
        done[i - 1] = out[i] + done[i];
    }
    out[0] = 1 - done[0];
    out
}

// Vetting: siblings = [0, X, 0, 0] (X != 0) -> the insertion sits at level 2,
// the deepest level whose parent sibling (siblings[1]) is non-zero.
#[test]
fn one_hot_insertion_level() {
    let siblings: [Field; 4] = [0, 99, 0, 0];
    let got = lev_ins(1, siblings);
    assert(got == [0, 0, 1, 0]);
}

// All-zero siblings -> insertion at the root level.
#[test]
fn empty_tree_inserts_at_root() {
    let siblings: [Field; 4] = [0, 0, 0, 0];
    let got = lev_ins(1, siblings);
    assert(got == [1, 0, 0, 0]);
}
