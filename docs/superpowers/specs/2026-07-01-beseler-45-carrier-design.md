# Beseler 45 Negative Carrier — Design Spec

**Date:** 2026-07-01
**Status:** Implemented

## Goal

Add a fully working `beseler-45` carrier type to the DarkroomSCAD generator,
replacing the current "not yet implemented" placeholder. The Beseler 45 is a
round, hinged clamshell carrier for the Beseler 45-series (4×5) enlargers. Our
printed version reproduces it as **two separate peg-mated boards** (no hinge).

The implementation follows the existing `beseler-23c` carrier as its template:
round body + protruding handle + handle-mounted text + the shared universal
assembly pipeline. The Beseler 45 adds one thing the 23c does not have: a
second, fixed peg system for enlarger alignment / board stacking.

## Reference dimensions

From `negative-carriers/beseler-45-dimensions.md` and scans of the physical
top/bottom boards:

- Body diameter: **210 mm** (radius 105)
- Handle: **29 mm** wide × **50.5 mm** long
- Board thickness (each half): **2.5 mm** (all other carriers are 2 mm)
- Corner align/stack pegs: **Ø4.6 mm**, **119.7 mm** center-to-center square
  (so each peg sits at ±59.85 mm on X and Y)
- Corner peg holes in the top board: **Ø6 mm**

## Decisions (resolved during brainstorming)

1. **Two peg systems, both modeled:**
   - *Film pegs* — the existing film-format-driven registration pegs (same code
     path as omega/lpl/23c). They register the film and mate the two halves.
     Honor the `Printed_or_Heat_Set_Pegs` option as usual.
   - *Corner align/stack pegs* — new, fixed 119.7 mm square, Ø4.6 mm. The
     **bottom** board carries pegs that protrude **down** (seat into the
     enlarger) **and up** (into the top board). The **top** board gets Ø6 mm
     through-holes to receive them. Always present, independent of the film-peg
     style.
2. **No alignment board.** The corner pegs are the enlarger alignment; the
   `beseler-45` dispatch forces `Alignment_Board = false` and skips the
   omega/lpl screw-footprint holes. The 4 corner rivets on the real part are
   construction fasteners and are not modeled.
3. **No hinge.** Top and bottom print as two separate pieces, mated by pegs.
4. **No hang hole; solid handle** (matches the 23c).
5. **Handle text** — owner/type etch on the **top (+Y)** handle. Same idea as the
   23c but positioned on the top handle instead of the 23c's −X handle, so it
   needs its own positioning branch (see below).
   - **As implemented:** `get_text_rotation` uses `[0, 0, 90]`, as planned. But
     since `universal-carrier-assembly.scad` applies the transforms as
     `rotate(rotation) translate(position)` — i.e. rotation is the *outer*
     transform — the pre-rotation position tuple in `calculate_text_position`
     had to be swapped to `[handle_mid_y, -x_base, z_position]` (rather than
     `[x_base, handle_mid_y, z_position]`) so that `R(90°) * [a, b] = [-b, a]`
     lands the text at the intended world position on the top handle. Verified
     by the 4×5 renders in Task 4: text sits correctly on the top handle with
     no rotation-composition drift.
6. **4×5 is landscape-only.** For the Beseler 45, 4×5 must render landscape —
   the 5″ (long) edge parallel to the bottom hinge line (i.e. the long edges on
   the top and bottom), hinge at the bottom, handle at the top. This is already
   the effective behavior: 4×5 is globally forced to the code's `"vertical"`
   effective orientation, which yields `cuboid([120, 95])` = 120 mm along X ×
   95 mm along Y = landscape with the long edges horizontal, and the Orientation
   control is ignored for 4×5. So **no orientation-logic change is required** —
   the requirement is satisfied by placing the handle at the top (decision 5/
   base shape) and must be **confirmed visually** during validation.

## Architecture

The Beseler 45 slots into the existing modular pipeline exactly like the 23c,
with a single carrier-type-gated addition for the corner pegs.

### New file: `src/beseler-45-base-shape.scad`

Pure geometry generator, mirroring `beseler-23c-base-shape.scad`:

- `module beseler_45_base_shape(config, top_or_bottom)`
- Uses shared constants `BESELER_45_DIAMETER` (210) and
  `BESELER_45_HANDLE_WIDTH` (29); handle length 50.5 mm.
- Round body via `cyl(h=CARRIER_HEIGHT, r=DIAMETER/2, rounding=.5, $fn=72)`.
- Handle via a rounded `cuboid`. **Handle placed at the top (+Y)**, NOT on the
  −X side like the 23c. This makes the handle define "top" and the opposite edge
  (−Y) the conceptual hinge/bottom, so the 4×5 landscape opening's long edges
  land on the top/bottom. No hang hole.
- Carrier height comes from `get_carrier_height("beseler-45")` = 2.5.

### `src/carrier-configs.scad`

- **Fix bug:** `BESELER_45_DIAMETER = 105` → **`210`** (the base-shape convention
  is `r = DIAMETER/2`; 105 would produce a half-size disc).
- `get_carrier_height`: return `BESELER_45_THICKNESS` (2.5) for `beseler-45`
  (currently everything returns the universal 2). Verify no downstream
  calculation assumes a 2 mm height for this carrier.
- `get_top_peg_hole_z_offset`: give `beseler-45` a value (mirror the 23c's `1`
  unless testing shows otherwise).
- Text: add `beseler-45` to `_get_text_settings` and add a `beseler-45` branch in
  `calculate_text_position` that mounts the text on the **top (+Y)** handle
  (owner/type stacked along the handle's Y length, centered in X), plus a
  `get_text_rotation` case (horizontal text reading left-to-right across the top
  handle). This differs from the 23c branch, which mounts text on the −X handle.
  Ensure the text-feature gate (`_is_full_feature_carrier` /
  `carrier_supports_multi_material_text`) allows beseler-45 text without
  re-enabling alignment-board support.
- Add new constants for the corner pegs:
  - `BESELER_45_ALIGN_PEG_SPACING = 119.7` (center-to-center)
  - `BESELER_45_ALIGN_PEG_DIAMETER = 4.6`
  - `BESELER_45_ALIGN_PEG_HOLE_DIAMETER = 6`
  - up/down protrusion heights (sane defaults, ~4 mm each), tunable.

### `src/common/universal-carrier-assembly.scad`

- `include <../beseler-45-base-shape.scad>`.
- Add a `beseler-45` branch in `generate_universal_base_shape`.
- New module (e.g. `generate_beseler45_corner_pegs()`), gated to
  `carrier_type == "beseler-45"`:
  - **Bottom** assembly: union the 4 corner pegs (protrude down + up).
  - **Top** assembly: subtract the 4 Ø6 mm corner holes.
  - Placed inside the assembly modules so it inherits the
    `Flip_Bottom_For_Printing` rotation. Independent of the film-peg z logic —
    the corner peg needs explicit down/up protrusion, not the film-peg offset.

### `carrier.scad`

- `include <src/beseler-45-base-shape.scad>`.
- Replace the placeholder `assert` branch (currently ~lines 216–218) with a real
  dispatch. Reuse `dispatch_to_universal_assembly` but force
  `_alignment_board = false` and `_alignment_board_type = "none"`, so the corner
  pegs are the only alignment feature. Add `beseler-45` to the standard-carrier
  branch or give it its own branch.

## Component boundaries

- **Base shape** (`beseler-45-base-shape.scad`): knows only the disc + handle
  outline. No openings, no pegs. Depends on the shared diameter/handle
  constants.
- **Corner pegs** (in the assembly layer): a self-contained feature that adds
  pegs (bottom) or holes (top) at fixed positions. Depends only on the corner
  peg constants and `top_or_bottom`.
- **Film pegs / opening / text / dispatch**: unchanged shared machinery; the
  Beseler 45 is just another carrier type flowing through it.

## Testing / validation

- Open `carrier.scad` in OpenSCAD, set `Carrier_Type = "beseler-45"`.
- Render **top** and **bottom** for several formats (35mm, 6x6, 6x9, 4x5) in
  both orientations. Verify:
  - Disc is 210 mm across, 2.5 mm thick, handle 29 mm wide, handle at the top.
  - Film pegs track the format and mate top↔bottom.
  - Bottom board shows 4 corner pegs (down + up); top board shows 4 Ø6 mm holes
    at the matching 119.7 mm square. Corner pegs clear the opening at every
    format including 4×5.
  - **4×5 renders landscape** — long (120 mm) edges on the top and bottom
    (parallel to the −Y hinge line), handle at the top; the Orientation control
    does not change 4×5.
  - No alignment-board geometry or screw-footprint holes appear.
  - Handle text etches correctly (owner + type) on the top handle.
  - `Flip_Bottom_For_Printing` flips the bottom board with its corner pegs.
- Confirm the other carrier types (omega-d, lpl, 23c, test frame) still render
  unchanged.

## Deferred / out of scope

- Hinge, hang hole, and the 4 construction rivets are intentionally not modeled.

## Resolved non-issues

- **Corner pegs vs. 4×5 opening:** no collision. The pegs sit on the diagonal
  corners at (±59.85, ±59.85); the largest opening (4×5 landscape) reaches only
  (60, 47.5). A peg would clip the opening only if both its X and Y ranges
  crossed the opening, but at 4×5 the peg's Y (59.85) clears the opening's
  47.5 mm half-height by ~10 mm. Clears at every format.
