//! SMTVerifier (circomlib): compose the components into a full proof check.

use crate::hash::hash_leaf;
use crate::levins::lev_ins;
use crate::level;
use crate::sm;

/// Verify an inclusion (`fnc = 0`) or non-membership (`fnc = 1`) proof of
/// `key` against the Poseidon Sparse Merkle Tree with the given `root`. `N` is
/// the tree depth (circomlib nLevels). When `enabled = 1` an invalid proof is
/// unsatisfiable (the circuit cannot be witnessed). `enabled`, `is_old0` and
/// `fnc` are field 0/1.
///
/// For inclusion, pass the member's `value` with `old_key = old_value =
/// is_old0 = 0`. For non-membership, pass `value = 0` and the witness
/// `(old_key, old_value, is_old0)`: either an empty slot (`is_old0 = 1`) or a
/// different leaf already at the key's path (`is_old0 = 0`).
pub fn smt_verify<let N: u32>(
    enabled: Field,
    root: Field,
    siblings: [Field; N],
    old_key: Field,
    old_value: Field,
    is_old0: Field,
    key: Field,
    value: Field,
    fnc: Field,
) {
    let old_leaf = hash_leaf(old_key, old_value);
    let new_leaf = hash_leaf(key, value);

    // Path bits, LSB first: level i splits on bit i of the key (circomlib uses
    // Num2Bits_strict; we decompose the full field element and take the low N).
    let key_bits: [u1; 254] = key.to_le_bits();

    let levins = lev_ins(enabled, siblings);
    let states = sm::run(enabled, is_old0, fnc, levins);
    sm::assert_terminates(states);

    // Levels bottom-up: the deepest child is zero; level 0 holds the root.
    let mut child = 0;
    let mut root0 = 0;
    for k in 0..N {
        let i = N - 1 - k; // N-1 down to 0
        let root_i = level::root(
            states.top[i],
            states.iold[i],
            states.inew[i],
            old_leaf,
            new_leaf,
            siblings[i],
            key_bits[i] as Field,
            child,
        );
        child = root_i;
        if i == 0 {
            root0 = root_i;
        }
    }

    // A non-empty non-membership proof must present a DIFFERENT leaf at the
    // slot: forbid fnc=1 & is_old0=0 & old_key==key & enabled.
    let keys_equal = (old_key == key) as Field;
    assert(fnc * (1 - is_old0) * keys_equal * enabled == 0);

    // The computed root must match when enabled.
    assert((root0 - root) * enabled == 0);
}

// ---------------------------------------------------------------------------
// Differential vs circomlib. Vectors from circomlibjs / circomlib's smt.js
// over the set {10, 20, 30} (DEPTH = 32, each member's value = 1):
//   root R; inclusion sibling S at level 1; empty-slot sibling T at level 0.
// ---------------------------------------------------------------------------
global R: Field = 16490996925805354524998157033955433819826672179087606710914254506106631754855;
global S: Field = 593382814535871979539121013061061032004597063407752488118744339187840713149;
global T: Field = 20079429386645613298288910500439838614888580267536166221957075387362631137245;

// Inclusion: key=20 is in the set.
#[test]
fn inclusion() {
    let mut sib: [Field; 32] = [0; 32];
    sib[1] = S;
    smt_verify(1, R, sib, 0, 0, 0, 20, 1, 0);
}

// Non-membership, empty slot: key=25 (is_old0 = 1).
#[test]
fn nonmembership_empty_slot() {
    let mut sib: [Field; 32] = [0; 32];
    sib[0] = T;
    smt_verify(1, R, sib, 25, 0, 1, 25, 0, 1);
}

// Non-membership, different leaf: key=52 reaches key=20's leaf
// (old_key = 20, old_value = 1, is_old0 = 0).
#[test]
fn nonmembership_other_leaf() {
    let mut sib: [Field; 32] = [0; 32];
    sib[1] = S;
    smt_verify(1, R, sib, 20, 1, 0, 52, 0, 1);
}

// A wrong root is unsatisfiable.
#[test(should_fail)]
fn rejects_wrong_root() {
    let mut sib: [Field; 32] = [0; 32];
    sib[1] = S;
    smt_verify(1, R + 1, sib, 0, 0, 0, 20, 1, 0);
}

// Claiming inclusion of a non-member is unsatisfiable.
#[test(should_fail)]
fn rejects_false_inclusion() {
    let mut sib: [Field; 32] = [0; 32];
    sib[0] = T;
    smt_verify(1, R, sib, 0, 0, 0, 25, 1, 0);
}

// `enabled = 0` disables all checks (a disabled gadget always passes).
#[test]
fn disabled_is_vacuous() {
    let sib: [Field; 32] = [0; 32];
    smt_verify(0, R, sib, 0, 0, 0, 999, 7, 0);
}
