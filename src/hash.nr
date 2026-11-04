//! SMT node and leaf hashes (circomlib `SMTHash1` / `SMTHash2`).

use poseidon::poseidon::bn254::{hash_2, hash_3};

/// Leaf hash: `Poseidon(key, value, 1)`. The trailing `1` is circomlib's
/// domain tag distinguishing a leaf from an internal node.
pub fn hash_leaf(key: Field, value: Field) -> Field {
    hash_3([key, value, 1])
}

/// Internal node hash: `Poseidon(left, right)`.
pub fn hash_node(left: Field, right: Field) -> Field {
    hash_2([left, right])
}

// Vetting: values from circomlibjs buildPoseidon() over BN254.
#[test]
fn leaf_matches_circomlib() {
    // Poseidon([7, 42, 1]) -- a leaf with key=7, value=42.
    assert(
        hash_leaf(7, 42)
            == 4493311589133745460420407419122258968806385426256609347893411899715800193259,
    );
}

#[test]
fn node_matches_circomlib() {
    // Poseidon([1, 2]) -- the canonical circomlib 2-input test vector.
    assert(
        hash_node(1, 2)
            == 7853200120776062878684798364095072458815029376092732009249414926327459813530,
    );
}
