include <BOSL2/std.scad>

$fn = 100;

CIRCLE_DIAMETER = 161.5;
TOP_BOTTOM_CUT = 10.75;
BOARD_DEPTH = 4;
GAP_WIDTH = 121;
CORNER_CUT_BOX_WIDTH = 20;
SCREWS_DIAMETER = 3.5;
SCREW_HOLE_BOTTOM_DIAMETER = 2.5;
SCREW_HOLE_TOP_DIAMETER = 5;
SCREW_HOLE_LOCATION_X = 18;
SCREW_HOLE_LOCATION_Y = 5.3;
SCREW_HOLE_DISTANCE_X = 121;
SCREW_HOLE_DISTANCE_Y = 121;

module lpl_corner_cut_box() {
    rotate([0, 0, 45]) cuboid([CORNER_CUT_BOX_WIDTH, CORNER_CUT_BOX_WIDTH, BOARD_DEPTH + 0.1], anchor = CENTER);
}

module lpl_saunders_alignment_board() {
    // Use color for debugging visibility if needed, can be removed later.
    // color("red")
    rotate([0, 180, 90]) difference() {
        cyl(l=BOARD_DEPTH + 0.1, d=CIRCLE_DIAMETER, chamfer=.9, chamfang = 45, from_end = true); 
        translate([0, 0, -BOARD_DEPTH/2]) cuboid([CIRCLE_DIAMETER, CIRCLE_DIAMETER, BOARD_DEPTH + 0.1], anchor = CENTER);
        cuboid([CIRCLE_DIAMETER + 0.1, GAP_WIDTH, BOARD_DEPTH + 0.2], anchor = CENTER);
        translate([0, CIRCLE_DIAMETER/2, 0]) cuboid([161, TOP_BOTTOM_CUT, BOARD_DEPTH + 0.2], anchor = CENTER);
        translate([0, -CIRCLE_DIAMETER/2, 0]) cuboid([161, TOP_BOTTOM_CUT, BOARD_DEPTH + 0.2], anchor = CENTER);
    }
}