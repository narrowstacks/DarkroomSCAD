include <BOSL2/std.scad>
include <BOSL2/rounding.scad>; // Added for chamfering functions

BOARD_LENGTH_WIDTH = 127; // Replaced by FRAME_OUTER_DIM
BOARD_HEIGHT = 1.7; // Replaced by FRAME_THICKNESS
BOARD_INSIDE_OPENING_UPDOWN_Y = 119; // Geometry re-defined
BOARD_INSIDE_OPENING_UPDOWN_X = 93.5; // taller-box width for non-4x5 formats (keeps screw holes clear)
BOARD_INSIDE_OPENING_UPDOWN_X_4X5 = 103; // widened so a 4x5 negative (101.6mm) clears the opening
BOARD_INSIDE_OPENING_LEFTRIGHT_Y = 70; // Geometry re-defined
BOARD_INSIDE_OPENING_LEFTRIGHT_X = 113; // Geometry re-defined
SMALL_ALIGNMENT_SCREW_DIAMETER = 4; // Replaced by SCREW_DIAMETER
SMALL_ALIGNMENT_SCREW_DISTANCE_X = 110 + SMALL_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
SMALL_ALIGNMENT_SCREW_DISTANCE_Y = 80 + SMALL_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
BIG_ALIGNMENT_SCREW_DIAMETER = 5; // Replaced by SCREW_DIAMETER
BIG_ALIGNMENT_SCREW_DISTANCE_X = 101 + BIG_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
BIG_ALIGNMENT_SCREW_DISTANCE_Y = 97 + BIG_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern

// $fn inherited from carrier.scad for variable preview/final quality

// The taller box's width widens for 4x5 to clear the negative; other formats keep
// the narrower opening so the alignment screw holes are not cut into.
function omega_updown_opening_width(film_format) =
    film_format == "4x5" ? BOARD_INSIDE_OPENING_UPDOWN_X_4X5 : BOARD_INSIDE_OPENING_UPDOWN_X;

module opening_cutout(updown_width = BOARD_INSIDE_OPENING_UPDOWN_X) {
    union() {
        cuboid([BOARD_INSIDE_OPENING_LEFTRIGHT_Y, BOARD_INSIDE_OPENING_LEFTRIGHT_X, BOARD_HEIGHT + 1], anchor=CENTER, rounding=0.5);
        cuboid([BOARD_INSIDE_OPENING_UPDOWN_Y, updown_width, BOARD_HEIGHT + 1], anchor=CENTER, rounding=0.5);
    }
}

// Parameterized screw hole pattern - generates 4 holes in a rectangular layout
module screw_hole_quad(diameter, dist_x, dist_y, height) {
    // Use $fn=24 for screw holes - sufficient quality at lower cost
    for (x_mult = [-1, 1]) {
        for (y_mult = [-1, 1]) {
            translate([x_mult * dist_y / 2, y_mult * dist_x / 2, 0])
                cylinder(d=diameter, h=height, anchor=CENTER, $fn=24);
        }
    }
}

module alignment_screw_holes() {
    screw_hole_quad(SMALL_ALIGNMENT_SCREW_DIAMETER, SMALL_ALIGNMENT_SCREW_DISTANCE_X, SMALL_ALIGNMENT_SCREW_DISTANCE_Y, BOARD_HEIGHT + 0.1);
}

module big_alignment_screw_holes() {
    screw_hole_quad(BIG_ALIGNMENT_SCREW_DIAMETER, BIG_ALIGNMENT_SCREW_DISTANCE_X, BIG_ALIGNMENT_SCREW_DISTANCE_Y, BOARD_HEIGHT + 0.1);
}

module omega_board_edge_cuts() {
    for (x_mult = [-1, 1]) {
        for (y_mult = [-1, 1]) {
            translate([x_mult * BOARD_LENGTH_WIDTH / 2, y_mult * BOARD_LENGTH_WIDTH / 2, 0])
                rotate([0, 0, 45]) cuboid([20, 20, 4], anchor=CENTER);
        }
    }
}

module board() {
    cuboid([BOARD_LENGTH_WIDTH, BOARD_LENGTH_WIDTH, BOARD_HEIGHT], anchor=CENTER, rounding=0.5);
}

module omega_d_alignment_board_screws(film_format = "") {
    render() difference() {
        board();
        omega_board_edge_cuts();
        opening_cutout(omega_updown_opening_width(film_format));
        alignment_screw_holes();
        big_alignment_screw_holes();
    }
}

module omega_d_alignment_board_no_screws(film_format = "") {
    render() difference() {
        board();
        omega_board_edge_cuts();
        opening_cutout(omega_updown_opening_width(film_format));
    }
}

// omega_d_alignment_board_screws();
// // omega_d_alignment_board_no_screws();
