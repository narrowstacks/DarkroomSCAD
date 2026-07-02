# Beseler 45 Carrier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fully working `beseler-45` carrier type — round Ø210 mm body, top handle, film-format pegs, a fixed corner alignment/stacking peg system, and handle text — replacing the current "not yet implemented" placeholder.

**Architecture:** The Beseler 45 flows through the existing universal carrier assembly like the Beseler 23C (round base shape + handle + shared film opening / pegs / text), with three carrier-specific additions: 2.5 mm board thickness, a new fixed 4-corner alignment/stacking peg system (bottom board = pegs protruding down+up, top board = Ø6 mm holes), and top-handle text. No alignment board (the corner pegs are the enlarger alignment).

**Tech Stack:** OpenSCAD (2025.05.02, nightly-style features), BOSL2 library. No unit-test framework — verification is headless CLI renders (must exit 0 and produce a non-empty STL) plus top-view PNG snapshots and explicit visual checks.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-07-01-beseler-45-carrier-design.md` (authoritative).
- **Body diameter:** 210 mm (radius 105). **Handle:** 29 mm wide × 50.5 mm protruding, at the **top (+Y)**. **Board thickness:** 2.5 mm each half.
- **Corner align/stack pegs:** Ø4.6 mm pegs, **119.7 mm** center-to-center square (±59.85), **Ø6 mm** holes in the top board.
- **No alignment board, no hinge, no hang hole, solid handle.** 4×5 is landscape-only (long edges on top/bottom), guaranteed by the global 4×5 forced orientation + handle-at-top.
- **BOSL2 include stays only at the entry point** (`carrier.scad`); sub-files must NOT `include <BOSL2/std.scad>` (only the commented "uncomment to preview alone" line, matching sibling files).
- **OpenSCAD binary (for all verification commands):**
  `OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"`
- **All render commands run from the `negative-carriers/` directory** (so `carrier.scad` and its relative includes resolve; BOSL2 resolves from the user library path).
- **Do not commit** the scratchpad render outputs. Write them under
  `/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad` (referred to below as `$OUT`).
- **Not in scope / no change needed:** `carrier-baked.scad` (the fast-preview path) intentionally covers only omega-d / lpl / beseler-23c and routes every other carrier to the exact parametric path, so beseler-45 needs no baked wiring.

---

## File Structure

- **Create** `negative-carriers/src/beseler-45-base-shape.scad` — pure geometry: round body + top handle. One responsibility: the Beseler 45 outline. Mirrors `beseler-23c-base-shape.scad`.
- **Modify** `negative-carriers/src/carrier-configs.scad` — fix the diameter constant, add per-carrier height/peg-z, add corner-peg constants, add beseler-45 text-position/rotation.
- **Modify** `negative-carriers/src/common/universal-carrier-assembly.scad` — include the new base shape, dispatch to it, and add the corner-peg feature modules + gated calls.
- **Modify** `negative-carriers/carrier.scad` — include the new base shape, replace the placeholder assert with a real dispatch (board forced off).

---

## Task 1: Renderable Beseler 45 body (config + base shape + dispatch)

**Deliverable:** `Carrier_Type="beseler-45"` renders a round Ø210 mm carrier with a top handle, film opening, and format-driven film pegs — top and bottom halves — without error. (Corner pegs and custom text come in later tasks.)

**Files:**
- Create: `negative-carriers/src/beseler-45-base-shape.scad`
- Modify: `negative-carriers/src/carrier-configs.scad` (diameter fix, height, top-peg z-offset)
- Modify: `negative-carriers/src/common/universal-carrier-assembly.scad` (include + base-shape dispatch)
- Modify: `negative-carriers/carrier.scad` (include + dispatch branch)

**Interfaces:**
- Produces: `module beseler_45_base_shape(config, top_or_bottom)` — round body (Ø `BESELER_45_DIAMETER`) + handle at +Y; used by `generate_universal_base_shape`.
- Produces: `get_carrier_height("beseler-45") == 2.5` (= `BESELER_45_THICKNESS`), consumed by the assembly and by Task 2's corner-peg modules.
- Consumes: existing `BESELER_45_DIAMETER`, `BESELER_45_HANDLE_WIDTH`, `BESELER_45_THICKNESS` constants (already present in `carrier-configs.scad`).

- [ ] **Step 1: Confirm the current placeholder fails (RED)**

Run (from `negative-carriers/`):
```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
"$OSC" -o "$OUT/b45-top.stl" -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D 'Top_or_Bottom="top"' carrier.scad 2>&1 | grep -i "not yet implemented"
```
Expected: prints the `CARRIER TYPE ERROR: 'beseler-45' is not yet implemented...` assert message; no STL produced.

- [ ] **Step 2: Fix the diameter bug and add per-carrier height + peg-z in `carrier-configs.scad`**

Change `BESELER_45_DIAMETER = 105;` (line ~79) to:
```openscad
BESELER_45_DIAMETER = 210;
```

Replace `get_carrier_height` (lines ~32) with:
```openscad
function get_carrier_height(carrier_type) =
    (carrier_type == "beseler-45") ? BESELER_45_THICKNESS
    : UNIVERSAL_CARRIER_HEIGHT;
```

Replace `get_top_peg_hole_z_offset` (lines ~39-42) with:
```openscad
function get_top_peg_hole_z_offset(carrier_type) =
    (carrier_type == "omega-d") ? 2
    : (carrier_type == "beseler-23c") ? 1
    : (carrier_type == "beseler-45") ? 1
    : 2;
```

- [ ] **Step 3: Create `src/beseler-45-base-shape.scad`**

```openscad
// Beseler 45 Base Shape Generator
// Pure geometry generator for Beseler 45 enlarger carrier base shapes
// Handles only the physical shape and handle

// BOSL2 is included once at the entry point (carrier.scad) — OpenSCAD re-parses
// every include with no dedup, so re-including the ~80k-line library here would
// add seconds per render. Uncomment to render/preview this file by itself:
// include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * Beseler 45 base shape module
 * Generates the round Beseler 45 carrier body with a handle at the top (+Y).
 * The handle sits opposite the (conceptual) hinge edge so the 4x5 landscape
 * opening's long edges land on the top/bottom. Uses shared BESELER_45_DIAMETER
 * and BESELER_45_HANDLE_WIDTH from carrier-configs.scad.
 *
 * @param config - Configuration array (currently unused; reserved for future overrides)
 * @param top_or_bottom - "top" or "bottom" (no geometric difference; kept for interface consistency)
 */
module beseler_45_base_shape(config, top_or_bottom) {
    CARRIER_HEIGHT = get_carrier_height("beseler-45");

    CARRIER_DIAMETER = BESELER_45_DIAMETER;   // 210
    HANDLE_WIDTH = BESELER_45_HANDLE_WIDTH;   // 29
    HANDLE_LENGTH = 50.5;                     // protruding length beyond the disc edge

    // Handle at the top (+Y). The cuboid is 2*HANDLE_LENGTH long and centred on
    // the disc edge, so it protrudes exactly HANDLE_LENGTH and overlaps the disc
    // by the same amount for a clean manifold union.
    module handle() {
        translate([0, CARRIER_DIAMETER / 2, 0])
            cuboid([HANDLE_WIDTH, HANDLE_LENGTH * 2, CARRIER_HEIGHT], anchor=CENTER, rounding=.5);
    }

    // $fn=72 on a 210mm circle gives ~9mm segments, well below visible thresholds.
    BODY_FN = 72;

    module base_geometry() {
        cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, center=true, rounding=.5, $fn=BODY_FN);
    }

    // render() caches geometry for faster subsequent previews
    render() union() {
        base_geometry();
        handle();
    }
}
```

- [ ] **Step 4: Wire the base shape into `src/common/universal-carrier-assembly.scad`**

After the existing base-shape includes (after `include <../beseler-23c-base-shape.scad>`, line ~19) add:
```openscad
include <../beseler-45-base-shape.scad>
```

In `generate_universal_base_shape` (lines ~292-305), add a branch before the fallback `else`:
```openscad
        } else if (carrier_type == "beseler-45") {
            beseler_45_base_shape(config, top_or_bottom);
        } else if (is_test_frame_type(carrier_type)) {
```
(i.e. insert the `beseler-45` branch immediately before the existing `is_test_frame_type` branch.)

- [ ] **Step 5: Wire the include + dispatch into `carrier.scad`**

After `include <src/beseler-23c-base-shape.scad>` (line ~28) add:
```openscad
include <src/beseler-45-base-shape.scad>
```

Replace the placeholder branch (lines ~216-218):
```openscad
} else if (Carrier_Type == "beseler-45") {
    // Future implementation placeholder
    assert(false, str("CARRIER TYPE ERROR: '", Carrier_Type, "' is not yet implemented. Use one of: omega-d, lpl-saunders-45xx, beseler-23c"));
}
```
with a real dispatch that forces the alignment board off (the corner pegs are the enlarger alignment):
```openscad
} else if (Carrier_Type == "beseler-45") {
    // Beseler 45: no alignment board — the fixed corner pegs align it in the enlarger.
    dispatch_to_universal_assembly(
        _alignment_board=false,
        _alignment_board_type="none"
    );
}
```

- [ ] **Step 6: Render top + bottom (text off) to verify it builds (GREEN)**

Run (from `negative-carriers/`):
```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
for tb in top bottom; do
  "$OSC" -o "$OUT/b45-$tb.stl" -D 'Render_Quality="preview"' \
    -D 'Carrier_Type="beseler-45"' -D "Top_or_Bottom=\"$tb\"" \
    -D 'Enable_Owner_Name_Etch=false' -D 'Enable_Type_Name_Etch=false' \
    -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -2
  ls -la "$OUT/b45-$tb.stl"
done
```
Expected: each render exits without an assert/error, prints a "Top level object is a 3D object" summary, and produces a non-empty (`> 0` byte) `.stl`.

- [ ] **Step 7: Render a top-view PNG and eyeball the body**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
"$OSC" -o "$OUT/b45-top.png" --imgsize=900,900 --projection=ortho --camera=0,0,0,0,0,0,750 \
  -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D 'Top_or_Bottom="top"' \
  -D 'Enable_Owner_Name_Etch=false' -D 'Enable_Type_Name_Etch=false' \
  -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -2
```
Expected/visual check (open `$OUT/b45-top.png`): a round disc with the **handle pointing up (+Y)**, a central film opening, and four film pegs/holes hugging the opening. Disc clearly larger than the 23c (210 vs 160 mm).

- [ ] **Step 8: Commit**

```bash
git add negative-carriers/src/beseler-45-base-shape.scad \
        negative-carriers/src/carrier-configs.scad \
        negative-carriers/src/common/universal-carrier-assembly.scad \
        negative-carriers/carrier.scad
git commit -m "feat(beseler-45): render round body + top handle via universal assembly"
```

---

## Task 2: Corner alignment / stacking pegs

**Deliverable:** The bottom board grows four Ø4.6 mm pegs at the fixed 119.7 mm square, protruding below (enlarger) and above (stacking); the top board gets four matching Ø6 mm through-holes. Film pegs and everything else are unchanged.

**Files:**
- Modify: `negative-carriers/src/carrier-configs.scad` (corner-peg constants)
- Modify: `negative-carriers/src/common/universal-carrier-assembly.scad` (feature modules + gated calls)

**Interfaces:**
- Consumes: `get_carrier_height("beseler-45")` (= 2.5, from Task 1).
- Produces: `module beseler45_corner_pegs()` (additive, bottom) and `module beseler45_corner_peg_holes()` (subtractive, top), both keyed off the new constants.

- [ ] **Step 1: Add corner-peg constants to `carrier-configs.scad`**

Immediately after the existing `BESELER_45_THICKNESS = 2.5;` line (~82) add:
```openscad
// Beseler 45 fixed corner alignment/stacking pegs (independent of film format).
// Bottom board carries the pegs (protrude down into the enlarger + up into the
// top board); the top board receives them with clearance holes.
BESELER_45_ALIGN_PEG_SPACING = 119.7;      // center-to-center square (peg at ±59.85)
BESELER_45_ALIGN_PEG_DIAMETER = 4.6;       // peg diameter
BESELER_45_ALIGN_PEG_HOLE_DIAMETER = 6;    // top-board clearance-hole diameter
BESELER_45_ALIGN_PEG_DOWN = 4;             // protrusion below the bottom face (enlarger)
BESELER_45_ALIGN_PEG_UP = 4;               // protrusion above the top face (into top board)
```

- [ ] **Step 2: Add the feature modules to `universal-carrier-assembly.scad`**

Immediately after the include block (after `include <../carrier-configs.scad>`, line ~22) and before the big `universal_carrier_assembly` doc comment, add:
```openscad
// ============================================================================
// BESELER 45 CORNER ALIGNMENT / STACKING PEGS
// Fixed square (BESELER_45_ALIGN_PEG_SPACING center-to-center). On the BOTTOM
// board the pegs protrude down (seat into the enlarger) and up (into the top
// board). The TOP board receives them with Ø BESELER_45_ALIGN_PEG_HOLE_DIAMETER
// through-holes. Independent of film format and of the film-peg style.
// ============================================================================
module beseler45_corner_pegs() {
    half = BESELER_45_ALIGN_PEG_SPACING / 2;
    r = BESELER_45_ALIGN_PEG_DIAMETER / 2;
    ch = get_carrier_height("beseler-45");
    total_h = BESELER_45_ALIGN_PEG_DOWN + ch + BESELER_45_ALIGN_PEG_UP;
    z_center = (BESELER_45_ALIGN_PEG_UP - BESELER_45_ALIGN_PEG_DOWN) / 2;
    for (xm = [-1, 1]) for (ym = [-1, 1])
        translate([xm * half, ym * half, z_center])
            cylinder(h=total_h, r=r, center=true, $fn=32);
}

module beseler45_corner_peg_holes() {
    half = BESELER_45_ALIGN_PEG_SPACING / 2;
    r = BESELER_45_ALIGN_PEG_HOLE_DIAMETER / 2;
    ch = get_carrier_height("beseler-45");
    for (xm = [-1, 1]) for (ym = [-1, 1])
        translate([xm * half, ym * half, 0])
            cylinder(h=ch + 2, r=r, center=true, $fn=32);
}
```

- [ ] **Step 3: Subtract the holes on the TOP carrier**

In `universal_top_carrier_assembly` (lines ~347-373), inside the `difference()` block, after `generate_universal_directional_arrows();` add:
```openscad
                    generate_universal_directional_arrows();

                    // Beseler 45: clearance holes for the bottom board's corner pegs
                    if (carrier_type == "beseler-45") beseler45_corner_peg_holes();
```

- [ ] **Step 4: Add the pegs on the BOTTOM carrier**

In `universal_bottom_carrier_assembly` (lines ~310-342), inside the `union()`, after the `carrier_base_processing(...) { ... }` block and before/near `generate_universal_alignment_board();` add:
```openscad
                // Add alignment board if enabled
                generate_universal_alignment_board();

                // Beseler 45: fixed corner alignment/stacking pegs (down + up)
                if (carrier_type == "beseler-45") beseler45_corner_pegs();
```

- [ ] **Step 5: Render bottom (pegs) and top (holes) — GREEN**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
for tb in top bottom; do
  "$OSC" -o "$OUT/b45-pegs-$tb.stl" -D 'Render_Quality="preview"' \
    -D 'Carrier_Type="beseler-45"' -D "Top_or_Bottom=\"$tb\"" \
    -D 'Flip_Bottom_For_Printing=false' \
    -D 'Enable_Owner_Name_Etch=false' -D 'Enable_Type_Name_Etch=false' \
    -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -2
  "$OSC" -o "$OUT/b45-pegs-$tb.png" --imgsize=900,900 --projection=ortho --camera=0,0,0,0,0,0,750 \
    -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D "Top_or_Bottom=\"$tb\"" \
    -D 'Flip_Bottom_For_Printing=false' \
    -D 'Enable_Owner_Name_Etch=false' -D 'Enable_Type_Name_Etch=false' \
    -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -1
done
```
Expected/visual check:
- `b45-pegs-top.png`: **four holes** at the wide corner square (well outside the film pegs).
- `b45-pegs-bottom.png`: **four solid pegs** at the same corners. (Top-down view shows the peg circles; the down/up protrusion is confirmed in the side view below.)

- [ ] **Step 6: Verify the down+up protrusion with a side-view PNG**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
"$OSC" -o "$OUT/b45-pegs-side.png" --imgsize=1000,500 --projection=ortho --camera=0,0,0,90,0,0,750 \
  -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D 'Top_or_Bottom="bottom"' \
  -D 'Flip_Bottom_For_Printing=false' \
  -D 'Enable_Owner_Name_Etch=false' -D 'Enable_Type_Name_Etch=false' \
  -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -1
```
Expected/visual check (`b45-pegs-side.png`, edge-on view): the corner pegs stick out **both** faces of the 2.5 mm bottom board (≈4 mm each side).

- [ ] **Step 7: Commit**

```bash
git add negative-carriers/src/carrier-configs.scad \
        negative-carriers/src/common/universal-carrier-assembly.scad
git commit -m "feat(beseler-45): add fixed corner alignment/stacking pegs (bottom) + holes (top)"
```

---

## Task 3: Handle text on the top handle

**Deliverable:** Owner/type text etches onto the top (+Y) handle, running along the handle length, on both top and bottom carriers, without render errors.

**Files:**
- Modify: `negative-carriers/src/carrier-configs.scad` (`_get_text_settings`, `calculate_text_position`, `get_text_rotation`)

**Interfaces:**
- Consumes: `BESELER_45_DIAMETER`, `BESELER_45_HANDLE_WIDTH` (from configs).
- Produces: a `beseler-45` case in `calculate_text_position` returning a valid `[x, y, z]`, and `get_text_rotation("beseler-45", _) == [0, 0, 90]`. Consumed by both `universal-carrier-assembly.scad` and `carrier-baked.scad` (both call these shared functions).

- [ ] **Step 1: Confirm current text lands via the generic branch (baseline)**

Run:
```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
"$OSC" -o "$OUT/b45-text-before.png" --imgsize=900,900 --projection=ortho --camera=0,0,0,0,0,0,750 \
  -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D 'Top_or_Bottom="top"' \
  -D 'Owner_Name="NARROWSTACKS"' -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -1
```
Expected/visual: text currently renders via the generic edge branch (placed out on the disc body, not on the handle) — this is what we're replacing.

- [ ] **Step 2: Add a `beseler-45` entry to `_get_text_settings`**

In `_get_text_settings` (lines ~60-64) add a `beseler-45` case before the final fallback (the value is unused by the dedicated position branch but must be non-undef):
```openscad
function _get_text_settings(carrier_type) =
    (carrier_type == "omega-d") ? [-90, 69.5, 5]       // rect section is 139mm wide, edge at ~69.5
    : (carrier_type == "lpl-saunders-45xx") ? [-65, 85, 5] // 215mm diameter, text near handle side
    : (carrier_type == "beseler-23c") ? [-65, 60, 5]   // 160mm diameter, text on handle
    : (carrier_type == "beseler-45") ? [0, 105, 5]     // 210mm diameter, text on top handle
    : [0, 60, 5];
```

- [ ] **Step 3: Add a `beseler-45` branch to `calculate_text_position`**

In `calculate_text_position` (lines ~406-436), add a `beseler-45` branch immediately after the `beseler-23c` branch and before the default `let(...)`:
```openscad
    :
    // Beseler 45: text lives on the protruding top (+Y) handle, running along the
    // handle's long (Y) axis (see get_text_rotation → 90°). Owner and type sit as
    // two columns across the 29mm handle width (X).
    (carrier_type == "beseler-45") ?
        let (
            handle_mid_y = BESELER_45_DIAMETER / 2 + 22,   // ~127mm, on the visible handle
            x_base = (text_type == "owner") ? (BESELER_45_HANDLE_WIDTH / 4) : (-BESELER_45_HANDLE_WIDTH / 4)
        ) [x_base, handle_mid_y, z_position]
    :
    // Default handling: position text with equal edge margin from carrier boundary
    let (
```
(The existing `let (` for the default branch stays; you are inserting the `beseler-45 ? ... :` ternary just above it.)

- [ ] **Step 4: Add a `beseler-45` case to `get_text_rotation`**

Replace `get_text_rotation` (lines ~447-449) with:
```openscad
function get_text_rotation(carrier_type, text_type) =
    (carrier_type == "omega-d" || carrier_type == "lpl-saunders-45xx") ? _VERTICAL_TEXT_ROTATION
    : (carrier_type == "beseler-45") ? [0, 0, 90]
    : _HORIZONTAL_TEXT_ROTATION;
```

- [ ] **Step 5: Render top + bottom with text — GREEN**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
for tb in top bottom; do
  "$OSC" -o "$OUT/b45-text-$tb.stl" -D 'Render_Quality="preview"' \
    -D 'Carrier_Type="beseler-45"' -D "Top_or_Bottom=\"$tb\"" \
    -D 'Owner_Name="NAME"' -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -2
  "$OSC" -o "$OUT/b45-text-$tb.png" --imgsize=900,900 --projection=ortho --camera=0,0,0,0,0,0,750 \
    -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D "Top_or_Bottom=\"$tb\"" \
    -D 'Flip_Bottom_For_Printing=false' \
    -D 'Owner_Name="NAME"' -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -1
done
```
Expected/visual check: both renders succeed; owner + type text now sit **on the top handle** (two columns running along the handle length). If the text reads upside-down/mirrored for your taste, flip `get_text_rotation` to `[0, 0, 270]` and/or swap the owner/type `x_base` signs — re-render and confirm. (Legibility is a visual judgment; the automated gate is only "renders without error.")

- [ ] **Step 6: Commit**

```bash
git add negative-carriers/src/carrier-configs.scad
git commit -m "feat(beseler-45): etch owner/type text on the top handle"
```

---

## Task 4: 4×5 landscape confirmation + full regression

**Deliverable:** Documented confirmation that beseler-45 4×5 renders landscape with the long edges on the top/bottom and the corner pegs clearing the opening, and that the other carrier types still render unchanged.

**Files:** none (verification only). If 4×5 does NOT render landscape (it should, per the spec), stop and report — do not guess a fix.

- [ ] **Step 1: Render beseler-45 4×5 top + bottom**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
for tb in top bottom; do
  "$OSC" -o "$OUT/b45-4x5-$tb.png" --imgsize=900,900 --projection=ortho --camera=0,0,0,0,0,0,750 \
    -D 'Render_Quality="preview"' -D 'Carrier_Type="beseler-45"' -D "Top_or_Bottom=\"$tb\"" \
    -D 'Film_Format="4x5"' -D 'Flip_Bottom_For_Printing=false' \
    -D 'Owner_Name="NAME"' -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -2
done
```
Expected/visual check: the 4×5 opening is **wider than tall** (landscape), its two long edges horizontal (on the top/bottom, parallel to the −Y hinge edge), handle up. The four corner pegs/holes sit clear of the opening (no overlap).

- [ ] **Step 2: Render the whole `carrier.scad` STL for beseler-45 (final smoke test)**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
"$OSC" -o "$OUT/b45-final.stl" -D 'Render_Quality="final"' \
  -D 'Carrier_Type="beseler-45"' -D 'Top_or_Bottom="bottom"' \
  -D 'Film_Format="6x6"' carrier.scad 2>&1 | tail -3
ls -la "$OUT/b45-final.stl"
```
Expected: exits without error (default heat-set pegs, no alignment board — must NOT hit the "Alignment board included, so we can't use printed pegs" assert since the board is forced off), produces a non-empty STL.

- [ ] **Step 3: Regression — the other carriers still render**

```bash
OSC="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
OUT="/private/tmp/claude-501/-Users-aaronanderson-GitHub-DarkroomSCAD/abeb5a9a-23b4-4f55-b805-3737b94776aa/scratchpad"
for ct in omega-d lpl-saunders-45xx beseler-23c frameAndPegTest; do
  "$OSC" -o "$OUT/reg-$ct.stl" -D 'Render_Quality="preview"' \
    -D "Carrier_Type=\"$ct\"" -D 'Top_or_Bottom="bottom"' \
    -D 'Alignment_Board=false' -D 'Printed_or_Heat_Set_Pegs="printed"' carrier.scad 2>&1 | tail -1
  ls -la "$OUT/reg-$ct.stl"
done
```
Expected: all four still render to non-empty STLs (no new errors introduced by the shared-function edits).

- [ ] **Step 4: Update the spec status + note the verified text rotation**

In `docs/superpowers/specs/2026-07-01-beseler-45-carrier-design.md`, change the header `Status:` line to `Implemented` and, if the text rotation was flipped from the planned `[0,0,90]` during Task 3 Step 5, note the final value in the text decision.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-07-01-beseler-45-carrier-design.md
git commit -m "docs(beseler-45): mark spec implemented; record verified text rotation"
```

---

## Notes for the implementer

- **OpenSCAD line numbers are approximate** ("lines ~NNN") because earlier edits shift them. Match on the surrounding code shown, not the number.
- **Headless renders print pre-existing warnings** (e.g. `undefined operation` from the omega text path) even on unmodified code — those are not caused by this work. The gate is "no assert/error and a non-empty STL," not "zero warnings."
- **No BOSL2 in sub-files.** `beseler-45-base-shape.scad` uses `cyl`/`cuboid` (BOSL2) but relies on the entry-point include, exactly like `beseler-23c-base-shape.scad`. Keep the commented `// include <BOSL2/std.scad>` line for standalone preview only.
- **`center=true` bodies** put the board at Z ∈ [−1.25, +1.25] (2.5 mm). The corner-peg Z math depends on that; don't change the base shape to anchor at Z=0 bottom without updating `beseler45_corner_pegs`.
- **Do NOT touch the feature-gate functions** (`_is_full_feature_carrier`, `carrier_supports_alignment_board`, `carrier_supports_multi_material_text`, `carrier_supports_test_frames`). They are defined but never called in the `.scad` sources (they exist for the web project), so text etching is NOT gated by them — the universal assembly always etches text. Adding `beseler-45` to `_is_full_feature_carrier` would wrongly advertise alignment-board support, which we don't want.
- **Bottom-carrier text is not mirrored** for beseler-45 (unlike the 23c, which etches its bottom text on the underside). This is intentional for v1: text goes on the top surface of both halves. If the bottom half's text reads mirrored when flipped and that's undesirable, that's a follow-up (add `beseler-45` to the `_etch_on_bottom` handling in `universal-carrier-assembly.scad`), not part of this plan.
