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
// Alignment Screw Hole constants (mirrored from Omega D for compatibility with Omega type boards)
LPL_ALIGNMENT_SCREW_DIAMETER = 2;
LPL_ALIGNMENT_SCREW_PATTERN_DIST_X = 82; // Corresponds to Omega D's ALIGNMENT_SCREW_DISTANCE_Y (used for X coords of holes)
LPL_ALIGNMENT_SCREW_PATTERN_DIST_Y = 113; // Corresponds to Omega D's ALIGNMENT_SCREW_DISTANCE_X (used for Y coords of holes)

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
peg_z_offset_calc = get_peg_z_offset(_is_top_piece_for_peg_z_lpl, _peg_z_value_lpl, _peg_z_value_lpl) + 0.1;

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
        carrier_base_processing(
            _top_or_bottom = Top_or_Bottom,
            _carrier_material_height = carrierHeight,
            _opening_height_param = adjusted_opening_height,
            _opening_width_param = adjusted_opening_width,
            _opening_cut_through_ext_param = Film_Opening_Cut_Through_Extension,
            _opening_fillet_param = Film_Opening_Frame_Fillet,
            _peg_style_param = Printed_or_Heat_Set_Pegs,
            _peg_diameter_param = pegDiameter, // LPL uses pegDiameter
            _peg_actual_height_param = LPL_PEG_HEIGHT,
            _peg_pos_x_param = peg_pos_x_final,
            _peg_pos_y_param = peg_pos_y_final,
            _peg_z_offset_param = peg_z_offset_calc
        ) {
            difference() { // Wrap base_shape in difference to allow for conditional screw holes
                base_shape();
                if (!Alignment_Board) {
                    // If Alignment_Board is OFF, and type implies screws, punch the alignment footprint holes
                    if (Alignment_Board_Type == "omega" || Alignment_Board_Type == "lpl-saunders") { 
                        // Assuming "lpl-saunders" board type might also use a standard screw footprint if specified elsewhere,
                        // or this provides a default screw hole option if board is off.
                        alignment_footprint_holes(
                            _screw_dia = LPL_ALIGNMENT_SCREW_DIAMETER,
                            _dist_for_x_coords = LPL_ALIGNMENT_SCREW_PATTERN_DIST_X,
                            _dist_for_y_coords = LPL_ALIGNMENT_SCREW_PATTERN_DIST_Y,
                            _carrier_h = carrierHeight, // LPL's carrier height
                            _cut_ext = Film_Opening_Cut_Through_Extension, // LPL's cut through extension
                            _is_dent = (Top_or_Bottom == "top"), // Dents for top, through-holes for bottom
                            _dent_depth = 1 // Standard dent depth
                        );
                    }
                }
            }
        }
        
        handle(); // Add the handle to the carrier part

        // Alignment board addition for LPL Saunders (only on bottom piece)
        if (Alignment_Board && Top_or_Bottom == "bottom") {
            _z_trans_val = -carrierHeight; // LPL uses -carrierHeight for its boards
            // Conditional coloring based on board type (can be kept or removed if not essential for unified logic)
            if (Alignment_Board_Type == "omega") {
                color("red") translate([0, 0, _z_trans_val]) 
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            } else if (Alignment_Board_Type == "lpl-saunders") {
                color("blue") translate([0, 0, _z_trans_val]) 
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            } else if (Alignment_Board_Type == "beseler-23c") {
                translate([0, 0, _z_trans_val]) 
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            } else {
                instantiate_alignment_board_by_type(Alignment_Board_Type); // Fallback handles echo
            }
        }
    }
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    testPiecePadding = 10;
    // Test piece dimensions for LPL (using max with opening dimensions as well)
    testPieceCuboidWidth = max(2 * peg_pos_y_final + pegDiameter + testPiecePadding * 2, adjusted_opening_width + testPiecePadding*2);
    testPieceCuboidDepth = max(2 * peg_pos_x_final + pegDiameter + testPiecePadding * 2, adjusted_opening_height + testPiecePadding*2);
    // For LPL, peg_z_offset_calc is carrierHeight / 2 for both top and bottom, suitable for test frames too.
    effective_test_top_bottom = (Top_or_Bottom == "frameAndPegTestTop") ? "top" : "bottom";

    generate_test_frame(
        _effective_test_piece_role = effective_test_top_bottom,
        _frame_material_height = carrierHeight,
        _film_opening_h = adjusted_opening_height,
        _film_opening_w = adjusted_opening_width,
        _film_opening_cut_ext = Film_Opening_Cut_Through_Extension,
        _film_opening_f = Film_Opening_Frame_Fillet,
        _peg_style = Printed_or_Heat_Set_Pegs,
        _peg_dia_val = pegDiameter,
        _peg_h_val = LPL_PEG_HEIGHT,
        _peg_x_val = peg_pos_x_final,
        _peg_y_val = peg_pos_y_final,
        _peg_z_val = peg_z_offset_calc, // LPL peg_z_offset_calc is suitable here
        _test_cuboid_width = testPieceCuboidWidth,
        _test_cuboid_depth = testPieceCuboidDepth
    );
}