//! SMTVerifierLevel (circomlib): the root contribution of one level.
//!
//! Depending on the level's state the root is the hash of the child with the
//! sibling (`top`), the old leaf (`iold`), the new leaf (`inew`), or zero
//! (`i0` / `na`).

use crate::hash::hash_node;

/// Order `(child, sibling)` by the key's path bit, mirroring circomlib's
/// `Switcher`: bit 0 keeps `(child, sibling)`, bit 1 swaps to
/// `(sibling, child)`. `bit` is a field 0/1.
pub fn switch(child: Field, sibling: Field, bit: Field) -> (Field, Field) {
    let left = child + bit * (sibling - child);
    let right = sibling + bit * (child - sibling);
    (left, right)
}

/// The root at this level given its state flags, the two candidate leaves, the
/// sibling, the path bit, and the child root from the level below.
pub fn root(
    st_top: Field,
    st_iold: Field,
    st_inew: Field,
    old_leaf: Field,
    new_leaf: Field,
    sibling: Field,
    bit: Field,
    child: Field,
) -> Field {
    let (left, right) = switch(child, sibling, bit);
    let hashed = hash_node(left, right);
    hashed * st_top + old_leaf * st_iold + new_leaf * st_inew
}

#[test]
fn switch_keeps_on_zero_bit() {
    let (l, r) = switch(10, 20, 0);
    assert((l == 10) & (r == 20));
}

#[test]
fn switch_swaps_on_one_bit() {
    let (l, r) = switch(10, 20, 1);
    assert((l == 20) & (r == 10));
}

// In the `top` state the level is the hash of the ordered pair.
#[test]
fn top_state_hashes_up() {
    let got = root(1, 0, 0, 111, 222, 20, 0, 10);
    assert(got == crate::hash::hash_node(10, 20));
}

// In the `inew` state the level is the new leaf (inclusion).
#[test]
fn inew_state_is_new_leaf() {
    let got = root(0, 0, 1, 111, 222, 20, 0, 10);
    assert(got == 222);
}
