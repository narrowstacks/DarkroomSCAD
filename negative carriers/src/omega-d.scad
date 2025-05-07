// !! READ README.md BEFORE USING !!

include <BOSL2/std.scad>
include <common/film-sizes.scad> // Film size definitions
include <common/carrier-features.scad> // Common features shared by all carriers
include <common/omega-d-alignment-board.scad> // Omega style alignment board
include <common/lpl-saunders-alignment-board.scad> // LPL Saunders style alignment board

/* [Carrier Options] */
// Top or bottom of the carrier
Top_or_Bottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]
// Orientation of the film in the carrier. Does nothing for 4x5.
Orientation = "vertical"; // ["vertical", "horizontal"]
// Include the alignment board?
Alignment_Board = true; // [true, false]
Alignment_Board_Type = "omega"; // ["omega", "lpl-saunders"]

// Printed or heat-set pegs? Heat set pegs required when including alignment board.
Printed_or_Heat_Set_Pegs = "heat_set"; // ["printed", "heat_set"]

/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5"]
// Custom_Film_Height = "20";
// Custom_Film_Width = "20";

/* [Customization] */
// Enable or disable the owner name etching
Enable_Owner_Name_Etch = true; // [true, false]
// Name to etch on the carrier
Owner_Name = "NAME";

/* [Carrier Type Name Source] */
// Enable or disable the type name etching
Enable_Type_Name_Etch = true; // [true, false]
Type_Name = "Carrier Type"; // ["Carrier Type", "Custom"]
// Custom type name, if Type Name is "custom"
Custom_Type_Name = "CUSTOM";

/* [Name and Format Etchings Settings] */
// Font to use for the etchings
Fontface = "Futura";
// Font size for etchings
Font_Size = 10;
// Depth for etching
TEXT_ETCH_DEPTH = 1; 

/* [Adjustments] */
// Leave at 0 for default gap. Measured in mm. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.
Peg_Gap = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film width, subtract (use negative values) to decrease it.
Adjust_Film_Width = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film height, subtract (use negative values) to decrease it.
Adjust_Film_Height = 0;

/* [Hidden] */
OMEGA_D_CARRIER_LENGTH = 202;
OMEGA_D_CARRIER_WIDTH = 139;
OMEGA_D_CARRIER_HEIGHT = 2;
OMEGA_D_CARRIER_CIRCLE_DIAMETER = 168;
OMEGA_D_CARRIER_RECT_OFFSET = 13.5;
OMEGA_D_CARRIER_FILLET = 5;
OMEGA_D_FRAME_FILLET = 0.5;

// Pegs
OMEGA_D_PEG_DIAMETER = 5.6;
OMEGA_D_PEG_HEIGHT = 4;

// Registration holes
OMEGA_D_REG_HOLE_DIAMETER = 6.2;
OMEGA_D_REG_HOLE_DISTANCE = 130;
OMEGA_D_REG_HOLE_X_LENGTH = 5;
OMEGA_D_REG_HOLE_OFFSET = 4.5;
OMEGA_D_REG_HOLE_TOP_X_OFFSET = 5; // Added for top registration hole X offset
OMEGA_D_REG_HOLE_BOTTOM_X_OFFSET = -7; // Added for bottom registration hole X offset

// Alignment hole screws
OMEGA_D_ALIGNMENT_SCREW_DIAMETER = 2;
OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X = 113;
OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y = 82;

// General constants
CUT_THROUGH_EXTENSION = 1; // ensures difference operations cut fully through
OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION = 0; // extends the length of the reg hole slots
OMEGA_D_REG_HOLE_CYL_Y_OFFSET = 3.1; // Y offset for the cylindrical part of the reg holes
OMEGA_D_TOP_PEG_HOLE_Z_OFFSET = 2; // Z offset for the peg holes in the top carrier part

// Arrow dimensions for etching
ARROW_LENGTH = 8;
ARROW_WIDTH = 5;
ARROW_ETCH_DEPTH = 0.5;

// Check if the selected format is a "filed" medium format
IS_FILED_MEDIUM_FORMAT = Film_Format == "6x4.5 filed" ||
    Film_Format == "6x6 filed" ||
    Film_Format == "6x7 filed" ||
    Film_Format == "6x8 filed" ||
    Film_Format == "6x9 filed";

// Internal calculation based on user input, adjusted for filed formats
CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - Peg_Gap) - 1 : (1 - Peg_Gap);

$fn=100;

// Get film dimensions by calling functions from film-sizes.scad
FILM_FORMAT_HEIGHT = get_film_format_height(Film_Format);
FILM_FORMAT_WIDTH = get_film_format_width(Film_Format);
FILM_FORMAT_PEG_DISTANCE = get_film_format_peg_distance(Film_Format);

// Assert that the functions returned valid values (not undef)
assert(FILM_FORMAT_HEIGHT != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
assert(FILM_FORMAT_WIDTH != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
assert(FILM_FORMAT_PEG_DISTANCE != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
if (Alignment_Board && Printed_or_Heat_Set_Pegs == "printed") {
    assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
}

SELECTED_TYPE_NAME = get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format);

// Calculate Z offset for pegs/holes based on topOrBottom
PEG_Z_OFFSET = Top_or_Bottom == "bottom" ? OMEGA_D_CARRIER_HEIGHT / 2 : OMEGA_D_CARRIER_HEIGHT - OMEGA_D_TOP_PEG_HOLE_Z_OFFSET;

// Get text metrics
owner_metrics = textmetrics(text=Owner_Name, font=Fontface, size=10, halign="center", valign="center");
type_metrics = textmetrics(text=SELECTED_TYPE_NAME, font=Fontface, size=10, halign="center", valign="center");
safe_rect_center_x = -OMEGA_D_CARRIER_RECT_OFFSET;
safe_rect_size_x = OMEGA_D_CARRIER_LENGTH;
safe_rect_size_y = OMEGA_D_CARRIER_WIDTH;
safe_min_x = safe_rect_center_x - safe_rect_size_x / 2;
safe_max_x = safe_rect_center_x + safe_rect_size_x / 2;
safe_min_y = -safe_rect_size_y / 2;
safe_max_y = safe_rect_size_y / 2;
owner_rotated_size_x = owner_metrics.size[1]; // text height
owner_rotated_size_y = owner_metrics.size[0]; // text width
owner_center_x = -100;
owner_center_y = -35;
owner_min_x = owner_center_x - owner_rotated_size_x / 2;
owner_max_x = owner_center_x + owner_rotated_size_x / 2;
owner_min_y = owner_center_y - owner_rotated_size_y / 2;
owner_max_y = owner_center_y + owner_rotated_size_y / 2;
type_rotated_size_x = type_metrics.size[1]; // text height
type_rotated_size_y = type_metrics.size[0]; // text width
type_center_x = -100;
type_center_y = 40;
type_min_x = type_center_x - type_rotated_size_x / 2;
type_max_x = type_center_x + type_rotated_size_x / 2;
type_min_y = type_center_y - type_rotated_size_y / 2;
type_max_y = type_center_y + type_rotated_size_y / 2;
// echo(str("Type Name Final BBox X: [", type_min_x, ", ", type_max_x, "]"));
// echo(str("Type Name Final BBox Y: [", type_min_y, ", ", type_max_y, "]"));

// Check bounds and assert if text goes outside the safe rectangular area
assert(owner_min_x >= safe_min_x && owner_max_x <= safe_max_x,
       str("ERROR: Owner Name '", Owner_Name, "' X dimension [", owner_min_x, ", ", owner_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider shortening the name or adjusting position."));
assert(owner_min_y >= safe_min_y && owner_max_y <= safe_max_y,
       str("ERROR: Owner Name '", Owner_Name, "' Y dimension [", owner_min_y, ", ", owner_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider shortening the name or adjusting position."));
assert(type_min_x >= safe_min_x && type_max_x <= safe_max_x,
       str("ERROR: Type Name '", SELECTED_TYPE_NAME, "' X dimension [", type_min_x, ", ", type_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider adjusting position."));
assert(type_min_y >= safe_min_y && type_max_y <= safe_max_y,
       str("ERROR: Type Name '", SELECTED_TYPE_NAME, "' Y dimension [", type_min_y, ", ", type_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider adjusting position."));

module base_shape() {
    color("grey") union() {
        cylinder(h=OMEGA_D_CARRIER_HEIGHT, r=OMEGA_D_CARRIER_CIRCLE_DIAMETER/2, center = true);
        translate([-OMEGA_D_CARRIER_RECT_OFFSET, 0, 0]) cuboid([OMEGA_D_CARRIER_LENGTH, OMEGA_D_CARRIER_WIDTH, OMEGA_D_CARRIER_HEIGHT], anchor = CENTER, rounding=OMEGA_D_CARRIER_FILLET, edges=[[0,0,0,0], [0,0,0,0], [1,1,1,1]]);
    }
}

module alignment_screw_holes(is_dent = false, dent_depth = 1) {
    // hole_height = is_dent ? dent_depth : OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION; // Removed, height calculated in cylinder call
    // For dents, place their base at the bottom surface. For through-holes, center them vertically.
    z_pos = is_dent ? (-OMEGA_D_CARRIER_HEIGHT / 2) - 0.1 : 0;
    // use_center = true; // Removed, centering determined by is_dent
    hole_radius = is_dent ? OMEGA_D_ALIGNMENT_SCREW_DIAMETER/2 + 0.25 : OMEGA_D_ALIGNMENT_SCREW_DIAMETER/2;
    // Make the dent cylinder slightly taller to ensure subtraction // Removed effective_hole_height logic
    // effective_hole_height = is_dent ? dent_depth + 0.1 : hole_height;

    hole_h = is_dent ? dent_depth : OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION;
    use_center = !is_dent; // Center only if it's a through-hole

    // color("red")
    translate([OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
    // color("red")
    translate([-OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
    // color("red")
    translate([OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, -OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
    // color("red")
    translate([-OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, -OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
}

module registration_holes() {
    // top 
    translate([0, -1.5, 0]) union() {
        color("red") translate([OMEGA_D_REG_HOLE_TOP_X_OFFSET + (OMEGA_D_REG_HOLE_DISTANCE/2) + OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2, 0]) cuboid([OMEGA_D_REG_HOLE_DIAMETER, OMEGA_D_REG_HOLE_DIAMETER + OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION, OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
        color("red") translate([OMEGA_D_REG_HOLE_TOP_X_OFFSET + (OMEGA_D_REG_HOLE_DISTANCE/2) + OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_CYL_Y_OFFSET, 0]) cylinder(h=OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=OMEGA_D_REG_HOLE_DIAMETER/2, center = true);
    }
    // bottom
    translate([0, -1.5, 0]) union() {
        color("red") translate([OMEGA_D_REG_HOLE_BOTTOM_X_OFFSET - (OMEGA_D_REG_HOLE_DISTANCE/2) - OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2, 0]) cuboid([OMEGA_D_REG_HOLE_DIAMETER, OMEGA_D_REG_HOLE_DIAMETER + OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION, OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
        color("red") translate([OMEGA_D_REG_HOLE_BOTTOM_X_OFFSET - (OMEGA_D_REG_HOLE_DISTANCE/2) - OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_CYL_Y_OFFSET, 0]) cylinder(h=OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=OMEGA_D_REG_HOLE_DIAMETER/2, center = true);
    }
}

// Module to create a left-pointing arrow shape for etching
module arrow_etch(etch_depth = 0.5, length = 5, width = 3) {
    // Centered around [0,0] for easier placement later
    // Tip at [-length/2, 0], Base at [length/2, +/- width/2]
    translate([-10 ,0, .5]) // Position Z base at the top surface
    linear_extrude(height = etch_depth + 0.1) // Extrude upwards
        polygon(points=[ [-length/2, 0], [length/2, width/2], [length/2, -width/2] ]);
}

// Calculate values needed for generic modules
// Film Opening Dimensions
effective_orientation = (Film_Format == "4x5") ? "vertical" : Orientation;
calculated_opening_height = effective_orientation == "vertical" ? FILM_FORMAT_HEIGHT : FILM_FORMAT_WIDTH;
calculated_opening_width = effective_orientation == "vertical" ? FILM_FORMAT_WIDTH : FILM_FORMAT_HEIGHT;
adjusted_opening_height = calculated_opening_height + Adjust_Film_Height;
adjusted_opening_width = calculated_opening_width + Adjust_Film_Width;

// Peg Feature Dimensions
peg_z_offset_calc = Top_or_Bottom == "top" ? PEG_Z_OFFSET : OMEGA_D_CARRIER_HEIGHT / 2;
// Calculate peg positions based on Orientation and Film Format
peg_pos_x_calc = effective_orientation == "vertical" ?
            (FILM_FORMAT_WIDTH/2 + OMEGA_D_PEG_DIAMETER/2) :
            (FILM_FORMAT_PEG_DISTANCE/2 + OMEGA_D_PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP);
peg_pos_y_calc = effective_orientation == "vertical" ?
            (FILM_FORMAT_PEG_DISTANCE/2 + OMEGA_D_PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP) :
            (FILM_FORMAT_WIDTH/2 + OMEGA_D_PEG_DIAMETER/2);

// Text Etch Positions & Parameters
owner_etch_bottom_margin = 5;
owner_etch_bottom_position = safe_max_y - owner_etch_bottom_margin;
// Position vector for translate() before calling text_etch for Owner Name
// Adjust Z to position the *base* of the extrusion correctly for subtraction
owner_etch_z_pos = OMEGA_D_CARRIER_HEIGHT / 2 - (TEXT_ETCH_DEPTH + 0.1);
owner_etch_pos = [owner_etch_bottom_position, -95, owner_etch_z_pos];
owner_etch_rot = [0, 0, 270]; // Rotation vector for rotate() before calling text_etch

type_etch_top_margin = 5;
type_etch_top_position = safe_min_y + type_etch_top_margin;
// Position vector for translate() before calling text_etch for Type Name
// Adjust Z to position the *base* of the extrusion correctly for subtraction
type_etch_z_pos = OMEGA_D_CARRIER_HEIGHT / 2 - (TEXT_ETCH_DEPTH + 0.1);
type_etch_pos = [type_etch_top_position, -95, type_etch_z_pos];
type_etch_rot = [0, 0, 270]; // Rotation vector for rotate() before calling text_etch

// Module to encapsulate common subtractions for top and bottom pieces
module common_subtractions(is_top_piece) {
    film_opening(
        opening_height = adjusted_opening_height,
        opening_width = adjusted_opening_width,
        carrier_height = OMEGA_D_CARRIER_HEIGHT,
        cut_through_extension = CUT_THROUGH_EXTENSION,
        frame_fillet = OMEGA_D_FRAME_FILLET
    );
    registration_holes();

    if (!Alignment_Board) {
        // For bottom piece (is_top_piece=false), is_dent will be false (default behavior of alignment_screw_holes).
        // For top piece (is_top_piece=true), is_dent will be true.
        // dent_depth is only used if is_dent is true.
        if (Alignment_Board_Type == "omega") {
            alignment_screw_holes(is_dent = is_top_piece, dent_depth = 1);
        } else if (Alignment_Board_Type == "lpl-saunders") {
            alignment_screw_holes(is_dent = is_top_piece, dent_depth = 1);
        }
    }

    if (Enable_Owner_Name_Etch) {
        rotate(owner_etch_rot) translate(owner_etch_pos)
            text_etch(
                text_string = Owner_Name,
                font = Fontface,
                size = Font_Size,
                etch_depth = TEXT_ETCH_DEPTH,
                halign = "right",
                valign = "top"
            );
    }
    if (Enable_Type_Name_Etch) {
        rotate(type_etch_rot) translate(type_etch_pos)
            text_etch(
                text_string = SELECTED_TYPE_NAME,
                font = Fontface,
                size = Font_Size,
                etch_depth = TEXT_ETCH_DEPTH,
                halign = "left",
                valign = "top"
            );
    }
}

// Main logic
if (Top_or_Bottom == "bottom") {
    union() {
        // Positive Features for Bottom Piece
        if (Alignment_Board) {
            if (Alignment_Board_Type == "omega") {
                translate([0, 0, -2]) omega_d_alignment_board_no_screws();
            } else if (Alignment_Board_Type == "lpl-saunders") {
                translate([0, 0, 0.15]) lpl_saunders_alignment_board();
            }
        } else { // No Alignment Board
            if (Printed_or_Heat_Set_Pegs == "printed") {
                // Add printed pegs if no alignment board and printed pegs are selected
                pegs_feature(
                    is_hole = false,
                    peg_diameter = OMEGA_D_PEG_DIAMETER,
                    peg_height = OMEGA_D_PEG_HEIGHT,
                    peg_pos_x = peg_pos_x_calc,
                    peg_pos_y = peg_pos_y_calc,
                    z_offset = peg_z_offset_calc + 0.1 // Use calculated z_offset for bottom
                );
            }
            // If heat-set pegs are selected (and no alignment board),
            // holes are made in the difference() block below.
        }

        // Base Shape with Subtractions for Bottom Piece
        difference() {
            base_shape();
            common_subtractions(is_top_piece = false);

            // Bottom-specific peg-related subtractions
            // If heat-set pegs are chosen, make holes for them in the bottom piece.
            // This occurs regardless of the alignment board, per original logic.
            if (Printed_or_Heat_Set_Pegs == "heat_set") {
                heat_set_pegs_holes(
                    peg_height = 4.2,
                    peg_pos_x = peg_pos_x_calc,
                    peg_pos_y = peg_pos_y_calc,
                    z_offset = peg_z_offset_calc + 0.1
                );
            }

            // Add arrow etch for 6x6 formats on the bottom piece
            if (Film_Format == "6x6" || Film_Format == "6x6 filed") {
                arrowOffset = 5; // Distance from opening edge to arrow tip
                if (Orientation == "vertical") {
                    currentOpeningWidth = FILM_FORMAT_WIDTH;
                    arrowPosX = 0;
                    arrowPosY = currentOpeningWidth / 2 + arrowOffset + ARROW_LENGTH / 2;
                    translate([arrowPosX + 10, -arrowPosY , 0])
                        arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                } else { // Orientation == "horizontal"
                    currentOpeningHeight = FILM_FORMAT_HEIGHT;
                    arrowPosX = 0;
                    arrowPosY = -currentOpeningHeight / 2 - arrowOffset - ARROW_LENGTH / 2;
                    translate([arrowPosX, arrowPosY, 0])
                    rotate([0, 0, 90])
                        arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                }
            }
        }
    }
} else if (Top_or_Bottom == "top") {
    difference() {
        base_shape();
        common_subtractions(is_top_piece = true);

        // Top-specific peg-related subtractions
        if (Printed_or_Heat_Set_Pegs == "heat_set") {
            // Holes for screws to engage with heat-set inserts (in bottom or alignment board)
            heat_set_pegs_socket_head_opening(
                peg_height = OMEGA_D_PEG_HEIGHT,
                peg_pos_x = peg_pos_x_calc,
                peg_pos_y = peg_pos_y_calc,
                z_offset = peg_z_offset_calc + 0.1 // z_offset includes +0.1 as per original use
            );
        } else { // Printed pegs are on the bottom piece, so top needs clearance holes
            pegs_feature(
                is_hole = true,
                peg_diameter = OMEGA_D_PEG_DIAMETER,
                peg_height = OMEGA_D_PEG_HEIGHT,
                peg_pos_x = peg_pos_x_calc,
                peg_pos_y = peg_pos_y_calc,
                z_offset = peg_z_offset_calc // Use calculated z_offset for top
            );
        }
    }
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    // Create a smaller base for the test piece, slightly larger than the film opening + pegs
    testPiecePadding = 10; // Add padding around

    // Test piece dimensions based on max extent of pegs
    testPieceWidth = 2 * peg_pos_y_calc + testPiecePadding * 2;
    testPieceHeight = 2 * peg_pos_x_calc + testPiecePadding * 2;
    // Z offset for pegs/holes in test frames should be centered
    test_peg_z_offset = OMEGA_D_CARRIER_HEIGHT / 2;

    difference() {
        // Center the test piece
        cuboid([testPieceHeight, testPieceWidth, OMEGA_D_CARRIER_HEIGHT], anchor = CENTER);
        // Use generic film_opening
        film_opening(
            opening_height = adjusted_opening_height,
            opening_width = adjusted_opening_width,
            carrier_height = OMEGA_D_CARRIER_HEIGHT,
            cut_through_extension = CUT_THROUGH_EXTENSION,
            frame_fillet = OMEGA_D_FRAME_FILLET
        );
        // Subtract holes if it's the top test piece
        if (Top_or_Bottom == "frameAndPegTestTop") {
            // Use generic pegs_feature for holes
             pegs_feature(
                is_hole = true,
                peg_diameter = OMEGA_D_PEG_DIAMETER,
                peg_height = OMEGA_D_PEG_HEIGHT,
                peg_pos_x = peg_pos_x_calc,
                peg_pos_y = peg_pos_y_calc,
                z_offset = test_peg_z_offset // Correct Z offset for test frame
             );
        }
    }
    // Add pegs if it's the bottom test piece
    if (Top_or_Bottom == "frameAndPegTestBottom") {
        // Use generic pegs_feature for pegs
         pegs_feature(
            is_hole = false,
            peg_diameter = OMEGA_D_PEG_DIAMETER,
            peg_height = OMEGA_D_PEG_HEIGHT,
            peg_pos_x = peg_pos_x_calc,
            peg_pos_y = peg_pos_y_calc,
            z_offset = test_peg_z_offset // Correct Z offset for test frame
         );
    }
}

