// !! READ README.md BEFORE USING !!

include <BOSL2/std.scad>
// Film size definitions
include <src/common/film-sizes.scad>
// Common features shared by all carriers
include <src/common/carrier-features.scad>
// Omega style alignment board
include <src/common/omega-d-alignment-board.scad>
// LPL Saunders style alignment board
include <src/common/lpl-saunders-alignment-board.scad>
// Text etching functionality
include <src/common/text-etching.scad>

// Carrier configuration system
include <src/carrier-configs.scad>
// Universal carrier assembly system
include <src/common/universal-carrier-assembly.scad>
// Base shape generators
include <src/omega-d-base-shape.scad>
include <src/lpl-saunders-base-shape.scad>
include <src/beseler-23c-base-shape.scad>
include <src/test-frame-base-shape.scad>

/* [Carrier Type] */
Carrier_Type = "omega-d"; // ["omega-d", "lpl-saunders-45xx", "beseler-23c", "beseler-45", "frameAndPegTest"]
Orientation = "vertical"; // ["vertical", "horizontal"]

/* [Carrier Options] */
// Top or bottom of the carrier
Top_or_Bottom = "bottom"; // ["top", "bottom"]
// Orientation of the film in the carrier. Does nothing for 4x5.
// Include the alignment board?
Alignment_Board = true; // [true, false]
Alignment_Board_Type = "omega"; // ["omega", "lpl-saunders", "beseler-23c"]
// Flip bottom carriers to printable orientation (rotate 180° on X-axis)
Flip_Bottom_For_Printing = true; // [true, false]

// Printed or heat-set pegs? Heat set pegs required when including alignment board.
Printed_or_Heat_Set_Pegs = "heat_set"; // ["printed", "heat_set"]

/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]

/* [Custom Film Format] */
// Actual film stock width (for peg positioning)
Custom_Film_Width = 37;
// Actual film stock height (for film handling)
Custom_Film_Height = 37;
// Film opening width (the visible/cropped area)
Custom_Opening_Width = 24;
// Film opening height (the visible/cropped area)
Custom_Opening_Height = 36;

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
Fontface = "Lucida Console";
// Font size for etchings
Font_Size = 10;
// Depth for etching
TEXT_ETCH_DEPTH = 1;

/* [Multi-Material Text] */
// Render text as separate parts for multi-material printing
Text_As_Separate_Parts = false; // [true, false]
// Desired slicer layer height (mm)
Layer_Height_mm = 0.27;
// Number of layers for text thickness (multiple of layer height)
Text_Layer_Multiple = 1;

/* [Multi-Material Output Selector] */
// Select which part to render when exporting STLs
_WhichPart = "All"; // ["All", "Base", "OwnerText", "TypeText"]

/* [Adjustments] */
// Leave at 0 for default gap. Measured in mm. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.
Peg_Gap = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film width, subtract (use negative values) to decrease it.
Adjust_Film_Width = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film height, subtract (use negative values) to decrease it.
Adjust_Film_Height = 0;

/* [Hidden] */
$fn = 100;

// ============================================================================
// MAIN CARRIER GENERATION LOGIC
// ============================================================================

// Validate the selected carrier type
validate_carrier_config(Carrier_Type);

// Get configuration for the selected carrier type
carrier_config = get_carrier_config(Carrier_Type);

// Generate carrier type name for etching
SELECTED_TYPE_NAME = get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format);

// ============================================================================
// UNIFIED FILM OPENING AND PEG CALCULATIONS
// ============================================================================

// Calculate film opening dimensions once for all carriers
effective_orientation = get_effective_orientation(Film_Format, Orientation);
adjusted_opening_height = get_custom_aware_opening_height(Film_Format, Orientation, Adjust_Film_Height, Custom_Film_Height, Custom_Film_Width, Custom_Opening_Height);
adjusted_opening_width = get_custom_aware_opening_width(Film_Format, Orientation, Adjust_Film_Width, Custom_Film_Height, Custom_Film_Width, Custom_Opening_Width);

// Get peg diameter from config (index varies by carrier type)
peg_diameter =
    (Carrier_Type == "omega-d") ? carrier_config[7]
    : (Carrier_Type == "lpl-saunders-45xx") ? carrier_config[8]
    : (Carrier_Type == "beseler-23c") ? carrier_config[2]
    : (is_test_frame_type(Carrier_Type)) ? carrier_config[1]
    : 5.6; // Default fallback

// Calculate peg positions once for all carriers using unified approach
peg_positions = calculate_unified_peg_positions(
    film_format_str=Film_Format,
    orientation_str=Orientation,
    peg_diameter=peg_diameter,
    peg_gap_val=Peg_Gap,
    adjust_film_width_val=Adjust_Film_Width,
    adjust_film_height_val=Adjust_Film_Height,
    positioning_style="omega", // Use omega style for all carriers for consistency
    film_peg_distance=get_film_format_peg_distance(Film_Format, Custom_Film_Width)
);

peg_pos_x_calc = peg_positions[0];
peg_pos_y_calc = peg_positions[1];

// ============================================================================
// CARRIER DISPATCH LOGIC
// ============================================================================

// Dispatch to appropriate base shape and assemble with universal system
if (Carrier_Type == "omega-d") {
    universal_carrier_assembly(
        config=carrier_config,
        carrier_type=Carrier_Type,
        top_or_bottom=Top_or_Bottom,
        printed_or_heat_set_pegs=Printed_or_Heat_Set_Pegs,
        alignment_board=Alignment_Board,
        alignment_board_type=Alignment_Board_Type,
        flip_bottom_for_printing=Flip_Bottom_For_Printing,
        enable_owner_name_etch=Enable_Owner_Name_Etch,
        owner_name=Owner_Name,
        enable_type_name_etch=Enable_Type_Name_Etch,
        selected_type_name=SELECTED_TYPE_NAME,
        fontface=Fontface,
        font_size=Font_Size,
        text_etch_depth=TEXT_ETCH_DEPTH,
        text_as_separate_parts=Text_As_Separate_Parts,
        layer_height_mm=Layer_Height_mm,
        text_layer_multiple=Text_Layer_Multiple,
        which_part=_WhichPart,
        opening_height=adjusted_opening_height,
        opening_width=adjusted_opening_width,
        peg_pos_x=peg_pos_x_calc,
        peg_pos_y=peg_pos_y_calc,
        film_format_for_arrows=Film_Format
    );
} else if (Carrier_Type == "lpl-saunders-45xx") {
    universal_carrier_assembly(
        config=carrier_config,
        carrier_type=Carrier_Type,
        top_or_bottom=Top_or_Bottom,
        printed_or_heat_set_pegs=Printed_or_Heat_Set_Pegs,
        alignment_board=Alignment_Board,
        alignment_board_type=Alignment_Board_Type,
        flip_bottom_for_printing=Flip_Bottom_For_Printing,
        enable_owner_name_etch=Enable_Owner_Name_Etch,
        owner_name=Owner_Name,
        enable_type_name_etch=Enable_Type_Name_Etch,
        selected_type_name=SELECTED_TYPE_NAME,
        fontface=Fontface,
        font_size=Font_Size,
        text_etch_depth=TEXT_ETCH_DEPTH,
        text_as_separate_parts=Text_As_Separate_Parts,
        layer_height_mm=Layer_Height_mm,
        text_layer_multiple=Text_Layer_Multiple,
        which_part=_WhichPart,
        opening_height=adjusted_opening_height,
        opening_width=adjusted_opening_width,
        peg_pos_x=peg_pos_x_calc,
        peg_pos_y=peg_pos_y_calc,
        film_format_for_arrows=Film_Format
    );
} else if (Carrier_Type == "beseler-23c") {
    universal_carrier_assembly(
        config=carrier_config,
        carrier_type=Carrier_Type,
        top_or_bottom=Top_or_Bottom,
        printed_or_heat_set_pegs=Printed_or_Heat_Set_Pegs,
        alignment_board=Alignment_Board,
        alignment_board_type=Alignment_Board_Type,
        flip_bottom_for_printing=Flip_Bottom_For_Printing,
        enable_owner_name_etch=Enable_Owner_Name_Etch,
        owner_name=Owner_Name,
        enable_type_name_etch=Enable_Type_Name_Etch,
        selected_type_name=SELECTED_TYPE_NAME,
        fontface=Fontface,
        font_size=Font_Size,
        text_etch_depth=TEXT_ETCH_DEPTH,
        text_as_separate_parts=Text_As_Separate_Parts,
        layer_height_mm=Layer_Height_mm,
        text_layer_multiple=Text_Layer_Multiple,
        which_part=_WhichPart,
        opening_height=adjusted_opening_height,
        opening_width=adjusted_opening_width,
        peg_pos_x=peg_pos_x_calc,
        peg_pos_y=peg_pos_y_calc,
        film_format_for_arrows=Film_Format
    );
} else if (Carrier_Type == "beseler-45") {
    // Future implementation placeholder
    assert(false, str("CARRIER TYPE ERROR: '", Carrier_Type, "' is not yet implemented. Use one of: omega-d, lpl-saunders-45xx, beseler-23c"));
} else if (is_test_frame_type(Carrier_Type)) {
    // Handle test frame types with universal assembly
    universal_carrier_assembly(
        config=carrier_config,
        carrier_type=Carrier_Type,
        top_or_bottom=Top_or_Bottom,
        printed_or_heat_set_pegs=Printed_or_Heat_Set_Pegs,
        alignment_board=false, // Test frames don't use alignment boards
        alignment_board_type="none",
        flip_bottom_for_printing=false, // Test frames don't need flipping
        enable_owner_name_etch=false, // Test frames don't have text
        owner_name="",
        enable_type_name_etch=false,
        selected_type_name="",
        fontface=Fontface,
        font_size=Font_Size,
        text_etch_depth=TEXT_ETCH_DEPTH,
        text_as_separate_parts=false,
        layer_height_mm=Layer_Height_mm,
        text_layer_multiple=Text_Layer_Multiple,
        which_part=_WhichPart,
        opening_height=adjusted_opening_height,
        opening_width=adjusted_opening_width,
        peg_pos_x=peg_pos_x_calc,
        peg_pos_y=peg_pos_y_calc,
        film_format_for_arrows=Film_Format
    );
} else {
    assert(false, str("CARRIER TYPE ERROR: Unknown carrier type '", Carrier_Type, "'. Supported types: ", get_supported_carrier_types()));
}
