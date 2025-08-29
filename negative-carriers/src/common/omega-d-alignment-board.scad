include <BOSL2/std.scad>
include <BOSL2/rounding.scad>; // Added for chamfering functions

BOARD_LENGTH_WIDTH = 127; // Replaced by FRAME_OUTER_DIM
BOARD_HEIGHT = 1.7; // Replaced by FRAME_THICKNESS
BOARD_INSIDE_OPENING_UPDOWN_Y = 119; // Geometry re-defined
BOARD_INSIDE_OPENING_UPDOWN_X = 93.5; // Geometry re-defined
BOARD_INSIDE_OPENING_LEFTRIGHT_Y = 70; // Geometry re-defined
BOARD_INSIDE_OPENING_LEFTRIGHT_X = 113; // Geometry re-defined
SMALL_ALIGNMENT_SCREW_DIAMETER = 4; // Replaced by SCREW_DIAMETER
SMALL_ALIGNMENT_SCREW_DISTANCE_X = 110 + SMALL_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
SMALL_ALIGNMENT_SCREW_DISTANCE_Y = 80 + SMALL_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
BIG_ALIGNMENT_SCREW_DIAMETER = 5; // Replaced by SCREW_DIAMETER
BIG_ALIGNMENT_SCREW_DISTANCE_X = 101 + BIG_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
BIG_ALIGNMENT_SCREW_DISTANCE_Y = 97 + BIG_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern

$fn = 100;

module opening_cutout() {

    union() {
        color("orange") cuboid([BOARD_INSIDE_OPENING_LEFTRIGHT_Y, BOARD_INSIDE_OPENING_LEFTRIGHT_X, BOARD_HEIGHT + 1], anchor=CENTER, rounding=0.5);
        color("blue") cuboid([BOARD_INSIDE_OPENING_UPDOWN_Y, BOARD_INSIDE_OPENING_UPDOWN_X, BOARD_HEIGHT + 1], anchor=CENTER, rounding=0.5);
    }
}

module alignment_screw_holes() {
    color("red") translate([SMALL_ALIGNMENT_SCREW_DISTANCE_Y / 2, SMALL_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=SMALL_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
    color("red") translate([SMALL_ALIGNMENT_SCREW_DISTANCE_Y / 2, -SMALL_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=SMALL_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
    color("red") translate([-SMALL_ALIGNMENT_SCREW_DISTANCE_Y / 2, SMALL_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=SMALL_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
    color("red") translate([-SMALL_ALIGNMENT_SCREW_DISTANCE_Y / 2, -SMALL_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=SMALL_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
}

module big_alignment_screw_holes() {
    color("green") translate([BIG_ALIGNMENT_SCREW_DISTANCE_Y / 2, BIG_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=BIG_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
    color("green") translate([BIG_ALIGNMENT_SCREW_DISTANCE_Y / 2, -BIG_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=BIG_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
    color("green") translate([-BIG_ALIGNMENT_SCREW_DISTANCE_Y / 2, BIG_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=BIG_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
    color("green") translate([-BIG_ALIGNMENT_SCREW_DISTANCE_Y / 2, -BIG_ALIGNMENT_SCREW_DISTANCE_X / 2, 0]) cylinder(d=BIG_ALIGNMENT_SCREW_DIAMETER, h=BOARD_HEIGHT + 0.1, anchor=CENTER);
}

module omega_board_edge_cuts() {
    translate([BOARD_LENGTH_WIDTH / 2, BOARD_LENGTH_WIDTH / 2, 0]) rotate([0, 0, 45]) cuboid([20, 20, 4], anchor=CENTER);
    translate([BOARD_LENGTH_WIDTH / 2, -BOARD_LENGTH_WIDTH / 2, 0]) rotate([0, 0, 45]) cuboid([20, 20, 4], anchor=CENTER);
    translate([-BOARD_LENGTH_WIDTH / 2, BOARD_LENGTH_WIDTH / 2, 0]) rotate([0, 0, 45]) cuboid([20, 20, 4], anchor=CENTER);
    translate([-BOARD_LENGTH_WIDTH / 2, -BOARD_LENGTH_WIDTH / 2, 0]) rotate([0, 0, 45]) cuboid([20, 20, 4], anchor=CENTER);
}

module board() {
    cuboid([BOARD_LENGTH_WIDTH, BOARD_LENGTH_WIDTH, BOARD_HEIGHT], anchor=CENTER, rounding=0.5);
}

module omega_d_alignment_board_screws() {
    difference() {
        color("red") board();
        omega_board_edge_cuts();
        opening_cutout();
        alignment_screw_holes();
        big_alignment_screw_holes();
    }
}

module omega_d_alignment_board_no_screws() {
    difference() {
        color("red") board();
        omega_board_edge_cuts();
        opening_cutout();
    }
}

// omega_d_alignment_board_screws();
// // omega_d_alignment_board_no_screws();
