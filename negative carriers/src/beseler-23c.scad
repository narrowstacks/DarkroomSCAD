// !! READ README.md BEFORE USING !!

include <BOSL2/std.scad>
include <common/film-sizes.scad> // Include the film size definitions
include <common/carrier-features.scad> // Include common carrier features
include <common/beseler-23c-alignment-board.scad> // Include the alignment board
include <common/lpl-saunders-alignment-board.scad> // Include the alignment board
include <common/omega-d-alignment-board.scad> // Include the alignment board

/* [Carrier Options] */
// Top or bottom of the carrier
Top_or_Bottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]
// Orientation of the film in the carrier
Orientation = "vertical"; // ["vertical", "horizontal"]
// Include the alignment board?
Alignment_Board = true; // [true, false]
// Alignment_Board_Type = "beseler-23c"; // ["omega", "lpl-saunders", "beseler-23c"]
// Printed or heat-set pegs? Heat set pegs required when including alignment board.
Printed_or_Heat_Set_Pegs = "heat_set"; // ["printed", "heat_set"]

/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]

/* [Customization] */
// Enable or disable the owner name etching
Enable_Owner_Name_Etch = true; // [true, false]
// Name to etch on the carrier
Owner_Name = "NAME";

/* [Film Opening Parameters] */
// Extra distance for the film opening cut to ensure it goes through the material.
Film_Opening_Cut_Through_Extension = 1; //
// Fillet radius for the film opening edges.
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
CARRIER_DIAMETER = 160;
CARRIER_HEIGHT = 2;
PEG_Z_OFFSET = Top_or_Bottom == "bottom" ? CARRIER_HEIGHT / 2 : CARRIER_HEIGHT - TOP_PEG_HOLE_Z_OFFSET;

// Peg constants (similar to Omega D)
PEG_DIAMETER = 5.6; // [mm] Diameter of the pegs
PEG_HEIGHT = 4;     // [mm] Height of the pegs
TOP_PEG_HOLE_Z_OFFSET = 1; // [mm] Z offset for peg holes in the top carrier part, relative to CARRIER_HEIGHT. (e.g. Omega D uses 2mm for a 2mm thick carrier, meaning holes are at mid-plane if peg height matches carrier height)

HANDLE_LENGTH = 50;
HANDLE_WIDTH = 42;

// custom opening height
customFilmFormatHeight = 36;
// custom opening width
customFilmFormatWidth = 24;
// custom film format height (for peg distance)
customFilmFormatPegDistance = 36;

// Get film dimensions by calling functions from film-sizes.scad
FILM_FORMAT_HEIGHT = get_film_format_height(Film_Format);
FILM_FORMAT_WIDTH = get_film_format_width(Film_Format);
FILM_FORMAT_PEG_DISTANCE = get_film_format_peg_distance(Film_Format);

// Determine actual opening dimensions based on orientation
opening_width_actual = get_final_opening_width(Film_Format, Orientation, Adjust_Film_Width);
opening_height_actual = get_final_opening_height(Film_Format, Orientation, Adjust_Film_Height);

// Peg Feature Dimensions & Calculations
_is_top_piece_for_peg_z = (Top_or_Bottom == "top");

// Z offset for pegs/holes
_value_for_top_peg_z = CARRIER_HEIGHT - TOP_PEG_HOLE_Z_OFFSET; // Peg holes on top piece
_value_for_bottom_peg_z = CARRIER_HEIGHT / 2;                 // Pegs on bottom piece (if implemented)
peg_z_offset_calc = get_peg_z_offset(_is_top_piece_for_peg_z, _value_for_top_peg_z, _value_for_bottom_peg_z);

// Determine effective orientation (especially for "4x5", though Beseler doesn't list it, good practice)
effective_orientation = get_effective_orientation(Film_Format, Orientation);

// Check if the selected format is a "filed" medium format
IS_FILED_MEDIUM_FORMAT = Film_Format == "35mm filed" || // Add other filed formats if they exist for Beseler
                         Film_Format == "6x4.5 filed" ||
                         Film_Format == "6x6 filed" ||
                         Film_Format == "6x7 filed" ||
                         Film_Format == "6x8 filed" ||
                         Film_Format == "6x9 filed";

// Internal calculation for peg gap, adjusted for filed formats
CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - Peg_Gap) - 1 : (1 - Peg_Gap);

// Calculate peg positions using Omega-style rules
_peg_radius = PEG_DIAMETER / 2;
_film_width_actual_half = (get_film_format_width(Film_Format) + Adjust_Film_Width) / 2; // Use adjusted width
_film_peg_distance_actual_half = FILM_FORMAT_PEG_DISTANCE / 2; // Peg distance usually not adjusted by Adjust_Film_Height/Width

if (Alignment_Board && Printed_or_Heat_Set_Pegs == "printed") {
    assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
}
peg_pos_x_calc = calculate_omega_style_peg_coordinate(
    is_dominant_film_dimension = (effective_orientation == "vertical"), // X uses film width if vertical
    film_width_or_equiv_half = _film_width_actual_half,
    film_peg_distance_half = _film_peg_distance_actual_half,
    peg_radius = _peg_radius,
    omega_internal_gap_value = CALCULATED_INTERNAL_PEG_GAP
);

peg_pos_y_calc = calculate_omega_style_peg_coordinate(
    is_dominant_film_dimension = (effective_orientation == "horizontal"), // Y uses film width if horizontal
    film_width_or_equiv_half = _film_width_actual_half,
    film_peg_distance_half = _film_peg_distance_actual_half,
    peg_radius = _peg_radius,
    omega_internal_gap_value = CALCULATED_INTERNAL_PEG_GAP
);

$fn=200;

module handle() {
    translate([0, CARRIER_DIAMETER/2, 0]) color("grey") cuboid([HANDLE_WIDTH, HANDLE_LENGTH*1.5, CARRIER_HEIGHT], anchor = CENTER, rounding = .5);
}

module base_shape() {
    color("grey") union() {
        cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER/2, center = true, rounding = .5);
    }
}

// Main logic
if (Top_or_Bottom == "bottom") {
    union() {
        carrier_base_processing(
            _top_or_bottom = Top_or_Bottom,
            _carrier_material_height = CARRIER_HEIGHT,
            _opening_height_param = opening_height_actual,
            _opening_width_param = opening_width_actual,
            _opening_cut_through_ext_param = Film_Opening_Cut_Through_Extension,
            _opening_fillet_param = Film_Opening_Frame_Fillet,
            _peg_style_param = Printed_or_Heat_Set_Pegs,
            _peg_diameter_param = PEG_DIAMETER,
            _peg_actual_height_param = PEG_HEIGHT,
            _peg_pos_x_param = peg_pos_x_calc,
            _peg_pos_y_param = peg_pos_y_calc,
            _peg_z_offset_param = peg_z_offset_calc
        ) {
            base_shape(); // Beseler's base_shape
            // No Beseler-specific subtractions comparable to Omega-D's registration holes were in the original main diff block.
            // Text etching is not explicitly in the main body difference of the original Beseler file.
        }
        
        // Beseler-specific additions (handle, alignment board)
        handle();

        // Beseler's unique alignment board logic for the bottom piece
        if (Alignment_Board) {
            difference() {
                translate([0, 0, CARRIER_HEIGHT/2]) beseler_23c_alignment_board(); 
                translate([0, 0, -2]) base_shape(); 
            }
        }
    }
} else { // topOrBottom == "top" (Original Beseler file only had "bottom" or "top" for main logic, no test frames explicitly)
    // For the top piece, it's mostly subtractions from the base_shape.
    carrier_base_processing(
        _top_or_bottom = Top_or_Bottom,
        _carrier_material_height = CARRIER_HEIGHT,
        _opening_height_param = opening_height_actual,
        _opening_width_param = opening_width_actual,
        _opening_cut_through_ext_param = Film_Opening_Cut_Through_Extension,
        _opening_fillet_param = Film_Opening_Frame_Fillet,
        _peg_style_param = Printed_or_Heat_Set_Pegs,
        _peg_diameter_param = PEG_DIAMETER,
        _peg_actual_height_param = PEG_HEIGHT,
        _peg_pos_x_param = peg_pos_x_calc,
        _peg_pos_y_param = peg_pos_y_calc,
        _peg_z_offset_param = peg_z_offset_calc
    ) {
        base_shape(); // Beseler's base_shape
        // No specific subtractions for top piece in original main diff other than film opening and pegs.
    }
    handle();
}

// NOTE: The original beseler-23c.scad did not have explicit frameAndPegTestBottom/Top options 
// in its main if/else structure. If these are desired, they would need to be added using 
// the generate_test_frame module, similar to how it was done for omega-d.scad, 
// including calculations for test piece dimensions and Z offsets for pegs.
// For example:
/*
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    testPiecePadding = 10; 
    // Calculate testPieceWidth and testPieceDepth based on peg_pos_x_calc, peg_pos_y_calc, PEG_DIAMETER and padding
    // Example: testPieceWidth = 2 * peg_pos_y_calc + PEG_DIAMETER + testPiecePadding * 2;
    // Example: testPieceDepth = 2 * peg_pos_x_calc + PEG_DIAMETER + testPiecePadding * 2;
    test_peg_z_offset = CARRIER_HEIGHT / 2;
    effective_test_top_bottom = (Top_or_Bottom == "frameAndPegTestTop") ? "top" : "bottom";

    generate_test_frame(
        _effective_test_piece_role = effective_test_top_bottom,
        _frame_material_height = CARRIER_HEIGHT,
        _film_opening_h = opening_height_actual,
        _film_opening_w = opening_width_actual,
        _film_opening_cut_ext = Film_Opening_Cut_Through_Extension,
        _film_opening_f = Film_Opening_Frame_Fillet,
        _peg_style = Printed_or_Heat_Set_Pegs,
        _peg_dia_val = PEG_DIAMETER,
        _peg_h_val = PEG_HEIGHT,
        _peg_x_val = peg_pos_x_calc,
        _peg_y_val = peg_pos_y_calc,
        _peg_z_val = test_peg_z_offset,
        _test_cuboid_width = testPieceWidth, // Calculated value
        _test_cuboid_depth = testPieceDepth  // Calculated value
    );
}
*/
