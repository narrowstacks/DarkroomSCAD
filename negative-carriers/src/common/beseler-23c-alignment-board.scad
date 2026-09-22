
// BOSL2 is included once at the entry point (carrier.scad) — OpenSCAD re-parses
// every include with no dedup, so re-including the ~80k-line library here would
// add seconds per render. Uncomment to render/preview this file by itself:
// include <BOSL2/std.scad>
// include <../carrier-configs.scad>  // pilot-hole pattern constants

alignmentCircleOuterDiameter = 120;
alignmentCircleInnerDiameter = 110;

// Torus dimensions derived from outer/inner diameters
// Major radius: midpoint between outer and inner radii
TORUS_MAJOR_RADIUS = (alignmentCircleOuterDiameter + alignmentCircleInnerDiameter) / 4; // 57.5
// Minor radius: half the difference between outer and inner radii (cross-section radius)
TORUS_MINOR_RADIUS = (alignmentCircleOuterDiameter - alignmentCircleInnerDiameter) / 4; // 2.5

// pilot_holes: cut the carrier's screw footprint (BESELER_23C_BOARD_SCREW_PATTERN_DIST,
// carrier-configs.scad — on the ring's centre-line at 45°) as thread-forming
// pilot holes through the ring, for the separately printed board that the
// carrier screws onto. Off for a fused board.
module beseler_23c_alignment_board(pilot_holes = false, pilot_dia = 1.9) {
    render() translate([0, 0, .5]) difference() {
        torus(r_maj=TORUS_MAJOR_RADIUS, r_min=TORUS_MINOR_RADIUS, anchor=CENTER);
        if (pilot_holes)
            for (xm = [-1, 1]) for (ym = [-1, 1])
                translate([xm * BESELER_23C_BOARD_SCREW_PATTERN_DIST / 2, ym * BESELER_23C_BOARD_SCREW_PATTERN_DIST / 2, 0])
                    cylinder(h=2 * TORUS_MINOR_RADIUS + 2, d=pilot_dia, center=true, $fn=24);
    }
}
