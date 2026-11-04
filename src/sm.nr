//! SMTVerifierSM (circomlib): the per-level verifier state machine.
//!
//! Walking root-first, each level is in exactly one state:
//!   - `top`  : above the insertion level -- hash the child with the sibling
//!   - `inew` : the insertion level, inclusion -- the new leaf
//!   - `iold` : the insertion level, non-membership with a different old leaf
//!   - `i0`   : the insertion level, non-membership with an empty slot
//!   - `na`   : below the insertion level -- contributes nothing
//!
//! `fnc = 0` verifies inclusion, `fnc = 1` non-membership; `is_old0 = 1` marks
//! the empty-slot non-membership case.

/// The five per-level state flags, each a field 0/1, for all `N` levels.
pub struct LevelStates<let N: u32> {
    pub top: [Field; N],
    pub i0: [Field; N],
    pub iold: [Field; N],
    pub inew: [Field; N],
    pub na: [Field; N],
}

/// Run the state machine over every level given the one-hot `lev_ins`.
pub fn run<let N: u32>(
    enabled: Field,
    is_old0: Field,
    fnc: Field,
    lev_ins: [Field; N],
) -> LevelStates<N> {
    let mut s = LevelStates {
        top: [0; N],
        i0: [0; N],
        iold: [0; N],
        inew: [0; N],
        na: [0; N],
    };
    for i in 0..N {
        // Seed at the root level: top = enabled, na = 1 - enabled.
        let p_top = if i == 0 { enabled } else { s.top[i - 1] };
        let p_i0 = if i == 0 { 0 } else { s.i0[i - 1] };
        let p_iold = if i == 0 { 0 } else { s.iold[i - 1] };
        let p_inew = if i == 0 { 0 } else { s.inew[i - 1] };
        let p_na = if i == 0 { 1 - enabled } else { s.na[i - 1] };

        let ptli = p_top * lev_ins[i];
        let ptli_fnc = ptli * fnc;
        s.top[i] = p_top - ptli;
        s.inew[i] = ptli - ptli_fnc;
        s.iold[i] = ptli_fnc * (1 - is_old0);
        s.i0[i] = ptli * is_old0;
        s.na[i] = p_na + p_inew + p_iold + p_i0;
    }
    s
}

/// Assert the walk terminates in a non-`top` state on the deepest level.
pub fn assert_terminates<let N: u32>(s: LevelStates<N>) {
    assert(s.na[N - 1] + s.iold[N - 1] + s.inew[N - 1] + s.i0[N - 1] == 1);
}

// Vetting: insertion at level 2 (one-hot), inclusion (fnc=0). Expect `top`
// above it, `inew` at it, `na` below it.
#[test]
fn inclusion_states() {
    let lev_ins: [Field; 4] = [0, 0, 1, 0];
    let s = run(1, 0, 0, lev_ins);
    assert(s.top == [1, 1, 0, 0]);
    assert(s.inew == [0, 0, 1, 0]);
    assert(s.iold == [0, 0, 0, 0]);
    assert(s.i0 == [0, 0, 0, 0]);
    assert(s.na == [0, 0, 0, 1]);
    assert_terminates(s);
}

// Non-membership, empty slot (fnc=1, is_old0=1): the insertion level is `i0`.
#[test]
fn nonmembership_empty_states() {
    let lev_ins: [Field; 4] = [0, 0, 1, 0];
    let s = run(1, 1, 1, lev_ins);
    assert(s.inew == [0, 0, 0, 0]);
    assert(s.iold == [0, 0, 0, 0]);
    assert(s.i0 == [0, 0, 1, 0]);
    assert_terminates(s);
}

// Non-membership, different old leaf (fnc=1, is_old0=0): the level is `iold`.
#[test]
fn nonmembership_other_states() {
    let lev_ins: [Field; 4] = [0, 0, 1, 0];
    let s = run(1, 0, 1, lev_ins);
    assert(s.inew == [0, 0, 0, 0]);
    assert(s.iold == [0, 0, 1, 0]);
    assert(s.i0 == [0, 0, 0, 0]);
    assert_terminates(s);
}
