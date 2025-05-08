// !! READ README.md BEFORE USING !!

include <BOSL2/std.scad>
include <common/film-sizes.scad> // Include the film size definitions
include <common/carrier-features.scad> // Include common carrier features
include <common/omega-d-alignment-board.scad> // Include common calculations
include <common/lpl-saunders-alignment-board.scad> // Include common calculations
include <common/beseler-23c-alignment-board.scad> // Include common calculations

/* [Carrier Options] */
// Top or bottom of the carrier
Top_or_Bottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]
// Orientation of the film in the carrier
Orientation = "vertical"; // ["vertical", "horizontal"]
// Printed or heat-set pegs?
Printed_or_Heat_Set_Pegs = "printed"; // ["printed", "heat_set"]
// Include the alignment board?
Alignment_Board = true; // [true, false]
// Type of alignment board- both are compatible with each other, just different styles
Alignment_Board_Type = "omega"; // ["omega", "lpl-saunders", "beseler-23c"]

/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]

/* [Customization] */
// Enable or disable the owner name etching
Enable_Owner_Name_Etch = true; // [true, false]
// Name to etch on the carrier
Owner_Name = "NAME";

Film_Opening_Frame_Fillet = 0.5; //


/* [Carrier Type Name Source] */
// Enable or disable the type name etching
Enable_Type_Name_Etch = true; // [true, false]
Type_Name = "Carrier Type"; // ["Carrier Type", "Custom"]
// Custom type name, if Type Name is "custom"
Custom_Type_Name = "CUSTOM";

/* [Adjustments] */
// Leave at 0 for default gap. Measured in mm. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.

Peg_Gap = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film width, subtract (use negative values) to decrease it.
Adjust_Film_Width = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film height, subtract (use negative values) to decrease it.
Adjust_Film_Height = 0;

/* [Carrier Etchings] */
// Font to use for the etchings
Fontface = "Futura";
// Font size for etchings
Font_Size = 10;

/* [Hidden] */
if (Alignment_Board && Printed_or_Heat_Set_Pegs == "printed") {
    assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
}

// Calculate values needed for generic modules
// Film Opening Dimensions
$fn = 100;
// Extra distance for the film opening cut to ensure it goes through the material.
Film_Opening_Cut_Through_Extension = 1; // 
// Get film dimensions by calling functions from film-sizes.scad
FILM_FORMAT_HEIGHT_RAW = get_film_format_height(Film_Format);
FILM_FORMAT_WIDTH_RAW = get_film_format_width(Film_Format);
// Note: LPL Saunders might not use film peg distance directly from standards in the same way Omega does,
// as 'pegDistance' is a user-configurable variable.

// Assert that the functions returned valid values (not undef)
assert(FILM_FORMAT_HEIGHT_RAW != undef, str("Unknown or unsupported Film_Format selected for HEIGHT: ", Film_Format));
assert(FILM_FORMAT_WIDTH_RAW != undef, str("Unknown or unsupported Film_Format selected for WIDTH: ", Film_Format));

effective_orientation = get_effective_orientation(Film_Format, Orientation);
// calculated_opening_height = get_calculated_opening_height(effective_orientation, FILM_FORMAT_HEIGHT_RAW, FILM_FORMAT_WIDTH_RAW); // Removed
// calculated_opening_width = get_calculated_opening_width(effective_orientation, FILM_FORMAT_HEIGHT_RAW, FILM_FORMAT_WIDTH_RAW); // Removed

// opening_height_actual = Orientation == "vertical" ? calculated_opening_height : calculated_opening_width; // Removed
// opening_width_actual = Orientation == "vertical" ? calculated_opening_width : calculated_opening_height; // Removed

// Adjusted film opening dimensions (incorporating user adjustments)
adjusted_opening_height = get_final_opening_height(Film_Format, Orientation, Adjust_Film_Height);
adjusted_opening_width = get_final_opening_width(Film_Format, Orientation, Adjust_Film_Width);

// Carrier Dimensions
carrierHeight = 2;
carrierDiameter = 215;

handleWidth = 60;
handleHeight = 40;
handleXOffset = 10;

edgeCutsWidth = 120;
edgeCutsHeight = 120;
edgeCutsDistance = 149.135;

// Peg Dimensions
pegDiameter = 10;
pegDistance = 100;
LPL_PEG_HEIGHT = 4; // Height of the pegs

// Peg Feature Calculations
// For LPL, peg Z offset is carrierHeight / 2 for both top and bottom.
_is_top_piece_for_peg_z_lpl = (Top_or_Bottom == "top"); // This boolean is for the function argument
_peg_z_value_lpl = carrierHeight / 2;
peg_z_offset_calc = get_peg_z_offset(_is_top_piece_for_peg_z_lpl, _peg_z_value_lpl, _peg_z_value_lpl);

// peg_pos_x_final and peg_pos_y_final are half the distance between opposite peg centers.
// Assumes FILM_FORMAT_WIDTH_RAW is the film's narrow dimension and pegDistance is the longitudinal peg pitch.
// Peg_Gap is added to position pegs further from the film edge.
peg_pos_x_final = effective_orientation == "vertical" ?
    (FILM_FORMAT_WIDTH_RAW/2 + pegDiameter/2 + Peg_Gap) :
    (FILM_FORMAT_HEIGHT_RAW/2 + pegDiameter/2 + Peg_Gap);

peg_pos_y_final = effective_orientation == "vertical" ?
    (FILM_FORMAT_HEIGHT_RAW/2 + pegDiameter/2 + Peg_Gap) :
    (FILM_FORMAT_WIDTH_RAW/2 + pegDiameter/2 + Peg_Gap);

module carrier_edge_cuts() {
    translate([0, edgeCutsDistance, 0]) cuboid([edgeCutsWidth, edgeCutsHeight, carrierHeight + 0.1], anchor = CENTER);
    translate([0, -edgeCutsDistance, 0]) cuboid([edgeCutsWidth, edgeCutsHeight, carrierHeight + 0.1], anchor = CENTER);
    translate([edgeCutsDistance, 0, 0]) cuboid([edgeCutsHeight, edgeCutsWidth, carrierHeight + 0.1], anchor = CENTER);
    translate([-edgeCutsDistance, 0, 0]) cuboid([edgeCutsHeight, edgeCutsWidth, carrierHeight + 0.1], anchor = CENTER);
}
module base_shape() {
    difference() {
        cyl(h = carrierHeight, r = carrierDiameter/2, anchor = CENTER);
        carrier_edge_cuts();
    }
}

module handle() {
    if(Top_or_Bottom == "top") {
        translate([carrierDiameter/2, handleXOffset, 0]) cuboid([handleWidth, handleHeight, carrierHeight], anchor = CENTER, rounding = 2, edges=[FWD+RIGHT,BACK+LEFT, FWD+LEFT, BACK+RIGHT]);
    } else {
        translate([carrierDiameter/2, -handleXOffset, 0]) cuboid([handleWidth, handleHeight, carrierHeight], anchor = CENTER, rounding = 2, edges=[FWD+RIGHT,BACK+LEFT, FWD+LEFT, BACK+RIGHT]);
    }
}

// Main logic for carrier generation
if (Top_or_Bottom == "bottom" || Top_or_Bottom == "top") {
    union() { // Main union for the carrier part
        difference() { // Start of difference for the main carrier body
            base_shape();
            film_opening(
                opening_height = adjusted_opening_height,
                opening_width = adjusted_opening_width,
                carrier_height = carrierHeight,
                cut_through_extension = Film_Opening_Cut_Through_Extension,
                frame_fillet = Film_Opening_Frame_Fillet
            );

            // Peg-related subtractions using the common module
            generate_peg_features(
                _top_or_bottom = Top_or_Bottom,
                _printed_or_heat_set = Printed_or_Heat_Set_Pegs,
                _peg_dia = pegDiameter,
                _peg_h = LPL_PEG_HEIGHT,
                _peg_x = peg_pos_x_final,
                _peg_y = peg_pos_y_final,
                _z_off = peg_z_offset_calc,
                _is_subtraction_pass = true
            );

        } // End of difference for the main carrier body

        // Additive peg features (e.g., printed pegs on bottom) using the common module
        generate_peg_features(
            _top_or_bottom = Top_or_Bottom,
            _printed_or_heat_set = Printed_or_Heat_Set_Pegs,
            _peg_dia = pegDiameter,
            _peg_h = LPL_PEG_HEIGHT,
            _peg_x = peg_pos_x_final,
            _peg_y = peg_pos_y_final,
            _z_off = peg_z_offset_calc,
            _is_subtraction_pass = false
        );
        
        handle(); // Add the handle to the carrier part

        // Alignment board addition
        if (Alignment_Board && Top_or_Bottom == "bottom") {
            _z_trans_val = -carrierHeight; // LPL uses -carrierHeight for its boards
            // Conditional coloring based on board type
            if (Alignment_Board_Type == "omega") {
                color("red") translate([0, 0, _z_trans_val]) 
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            } else if (Alignment_Board_Type == "lpl-saunders") {
                color("blue") translate([0, 0, _z_trans_val]) 
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            } else if (Alignment_Board_Type == "beseler-23c") {
                // Assuming LPL might support Beseler board with same Z offset
                // color("green") // Example color
                translate([0, 0, _z_trans_val]) 
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            } else {
                // Fallback for unknown, or let instantiate_alignment_board_by_type handle echo
                instantiate_alignment_board_by_type(Alignment_Board_Type);
            }
        }
    }
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    // Create a smaller base for the test piece
    testPiecePadding = 10;
    // Test piece dimensions based on max extent of pegs or film opening
    testPieceWidth = max(2 * peg_pos_y_final + testPiecePadding * 2, adjusted_opening_width + testPiecePadding*2);
    testPieceDepth = max(2 * peg_pos_x_final + testPiecePadding * 2, adjusted_opening_height + testPiecePadding*2);

    // Determine effective top/bottom string for the common module based on the test piece type
    effective_test_top_bottom = (Top_or_Bottom == "frameAndPegTestTop") ? "top" : "bottom";

    union() {
        // Additive peg features for test piece (e.g., printed pegs on bottom test piece)
        generate_peg_features(
            _top_or_bottom = effective_test_top_bottom,
            _printed_or_heat_set = Printed_or_Heat_Set_Pegs,
            _peg_dia = pegDiameter,
            _peg_h = LPL_PEG_HEIGHT,
            _peg_x = peg_pos_x_final,
            _peg_y = peg_pos_y_final,
            _z_off = peg_z_offset_calc, // Assuming peg_z_offset_calc is appropriate for test pieces too
            _is_subtraction_pass = false
        );

        difference() {
            cuboid([testPieceDepth, testPieceWidth, carrierHeight], anchor = CENTER);
            film_opening(
                opening_height = adjusted_opening_height,
                opening_width = adjusted_opening_width,
                carrier_height = carrierHeight,
                cut_through_extension = Film_Opening_Cut_Through_Extension,
                frame_fillet = Film_Opening_Frame_Fillet
            );

            // Peg-related subtractions for test piece
            generate_peg_features(
                _top_or_bottom = effective_test_top_bottom,
                _printed_or_heat_set = Printed_or_Heat_Set_Pegs,
                _peg_dia = pegDiameter,
                _peg_h = LPL_PEG_HEIGHT,
                _peg_x = peg_pos_x_final,
                _peg_y = peg_pos_y_final,
                _z_off = peg_z_offset_calc, // Assuming peg_z_offset_calc is appropriate
                _is_subtraction_pass = true
            );
        }
    }
}