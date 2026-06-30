
// BOSL2 is included once at the entry point (carrier.scad) — OpenSCAD re-parses
// every include with no dedup, so re-including the ~80k-line library here would
// add seconds per render. Uncomment both to render/preview this file by itself:
// include <BOSL2/std.scad>
// include <BOSL2/rounding.scad>

BOARD_LENGTH_WIDTH = 127; // Replaced by FRAME_OUTER_DIM
BOARD_HEIGHT = 1.7; // Replaced by FRAME_THICKNESS
BOARD_INSIDE_OPENING_UPDOWN_Y = 119; // X-extent of tall box for non-4x5 formats
BOARD_INSIDE_OPENING_UPDOWN_Y_4X5 = 121; // X-extent of tall box for 4x5: clears 120mm film with 0.5mm/side; outer X rail = (127-121)/2 = 3mm
BOARD_INSIDE_OPENING_UPDOWN_X = 93.5; // Y-extent (width) of tall box for non-4x5 formats (keeps screw holes clear)
BOARD_INSIDE_OPENING_UPDOWN_X_4X5 = 97; // Y-extent (width) of tall box for 4x5: clears 95mm film opening with 1mm/side margin; keeps big-screw edge (Y=50.5) 2mm from opening; corner rail ≈3.9mm
BOARD_INSIDE_OPENING_LEFTRIGHT_Y = 70; // X-extent of wide box
BOARD_INSIDE_OPENING_LEFTRIGHT_X = 113; // Y-extent (height) of wide box for non-4x5 formats
BOARD_INSIDE_OPENING_LEFTRIGHT_X_4X5 = 105; // Y-extent (height) of wide box for 4x5: clears 95mm film, keeps screws at ±57 Y in solid material with ~4mm rail
SMALL_ALIGNMENT_SCREW_DIAMETER = 4; // Replaced by SCREW_DIAMETER
SMALL_ALIGNMENT_SCREW_DISTANCE_X = 110 + SMALL_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
SMALL_ALIGNMENT_SCREW_DISTANCE_Y = 80 + SMALL_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
BIG_ALIGNMENT_SCREW_DIAMETER = 5; // Replaced by SCREW_DIAMETER
BIG_ALIGNMENT_SCREW_DISTANCE_X = 101 + BIG_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern
BIG_ALIGNMENT_SCREW_DISTANCE_Y = 97 + BIG_ALIGNMENT_SCREW_DIAMETER; // Re-interpreted for new hole pattern

// $fn inherited from carrier.scad for variable preview/final quality

// The taller box's Y-width widens for 4x5 to clear the negative; other formats keep
// the narrower opening so the alignment screw holes are not cut into.
function omega_updown_opening_width(film_format) =
    film_format == "4x5" ? BOARD_INSIDE_OPENING_UPDOWN_X_4X5 : BOARD_INSIDE_OPENING_UPDOWN_X;

// The taller box's X-length widens for 4x5 to clear the 120mm film opening; other formats keep 119mm.
function omega_updown_opening_length(film_format) =
    film_format == "4x5" ? BOARD_INSIDE_OPENING_UPDOWN_Y_4X5 : BOARD_INSIDE_OPENING_UPDOWN_Y;

// The wider box's Y-height is slimmed for 4x5 so the central notch stays away from screw holes.
function omega_leftright_opening_height(film_format) =
    film_format == "4x5" ? BOARD_INSIDE_OPENING_LEFTRIGHT_X_4X5 : BOARD_INSIDE_OPENING_LEFTRIGHT_X;

module opening_cutout(
    updown_width = BOARD_INSIDE_OPENING_UPDOWN_X,
    updown_length = BOARD_INSIDE_OPENING_UPDOWN_Y,
    leftright_height = BOARD_INSIDE_OPENING_LEFTRIGHT_X
) {
    union() {
        cuboid([BOARD_INSIDE_OPENING_LEFTRIGHT_Y, leftright_height, BOARD_HEIGHT + 1], anchor=CENTER, rounding=0.5);
        cuboid([updown_length, updown_width, BOARD_HEIGHT + 1], anchor=CENTER, rounding=0.5);
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
        opening_cutout(
            updown_width = omega_updown_opening_width(film_format),
            updown_length = omega_updown_opening_length(film_format),
            leftright_height = omega_leftright_opening_height(film_format)
        );
        alignment_screw_holes();
        big_alignment_screw_holes();
    }
}

module omega_d_alignment_board_no_screws(film_format = "") {
    render() difference() {
        board();
        omega_board_edge_cuts();
        opening_cutout(
            updown_width = omega_updown_opening_width(film_format),
            updown_length = omega_updown_opening_length(film_format),
            leftright_height = omega_leftright_opening_height(film_format)
        );
    }
}

// omega_d_alignment_board_screws();
// // omega_d_alignment_board_no_screws();
