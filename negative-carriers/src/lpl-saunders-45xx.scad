// !! READ README.md BEFORE USING !!

include <BOSL2/std.scad>
include <common/film-sizes.scad> // Include the film size definitions
include <common/carrier-features.scad> // Include common carrier features
include <common/omega-d-alignment-board.scad> // Include common calculations
include <common/lpl-saunders-alignment-board.scad> // Include common calculations
include <common/beseler-23c-alignment-board.scad> // Include common calculations
include <common/text-etching.scad> // Include shared text etching functionality

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
// Flip bottom carriers to printable orientation (rotate 180° on X-axis)
Flip_Bottom_For_Printing = true; // [true, false]

/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]

// If custom selected above: measurement of Custom Film Format (top to bottom)
Custom_Film_Format_Width = 37;
// Measurement of Custom Film Format carrier opening (top to bottom)
Custom_Film_Format_Opening_Width = 24;
// Measurement of Custom Film Format carrier opening (left to right)
Custom_Film_Format_Opening_Height = 36;

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

Film_Opening_Frame_Fillet = 0.5;

/* [Hidden] */
$fn = 100;

// LPL Saunders carrier base dimensions
LPL_CARRIER_DIAMETER = 215;
LPL_CARRIER_HEIGHT = 2;

// Handle dimensions
LPL_HANDLE_WIDTH = 60;
LPL_HANDLE_HEIGHT = 40;
LPL_HANDLE_X_OFFSET = 10;

// Edge cuts dimensions
LPL_EDGE_CUTS_WIDTH = 120;
LPL_EDGE_CUTS_HEIGHT = 120;
LPL_EDGE_CUTS_DISTANCE = 149.135;

// Film positioning peg dimensions
LPL_PEG_DIAMETER = 10;
LPL_PEG_HEIGHT = 4;
LPL_PEG_DISTANCE = 100;

// Alignment Screw Hole constants (mirrored from Omega D for compatibility with Omega type boards)
LPL_ALIGNMENT_SCREW_DIAMETER = 2;
LPL_ALIGNMENT_SCREW_PATTERN_DIST_X = 82; // Corresponds to Omega D's ALIGNMENT_SCREW_DISTANCE_Y (used for X coords of holes)
LPL_ALIGNMENT_SCREW_PATTERN_DIST_Y = 113; // Corresponds to Omega D's ALIGNMENT_SCREW_DISTANCE_X (used for Y coords of holes)

// General modeling constants
CUT_THROUGH_EXTENSION = 1;

// Direction arrow dimensions for 6x6 format
ARROW_LENGTH = 8;
ARROW_WIDTH = 5;
ARROW_ETCH_DEPTH = 0.5;

// Z-axis positioning calculations
TEXT_ETCH_Z_POSITION = LPL_CARRIER_HEIGHT / 2 - (TEXT_ETCH_DEPTH + 0.1);
CARRIER_HALF_HEIGHT = LPL_CARRIER_HEIGHT / 2;

if (Alignment_Board && Printed_or_Heat_Set_Pegs == "printed") {
    assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
}

// Film format type detection
IS_FILED_MEDIUM_FORMAT = Film_Format == "6x4.5 filed" || Film_Format == "6x6 filed" || Film_Format == "6x7 filed" || Film_Format == "6x8 filed" || Film_Format == "6x9 filed";

// Peg gap calculation adjusted for filed medium formats
CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - Peg_Gap) - 1 : (1 - Peg_Gap);

// Generate carrier type name for etching
SELECTED_TYPE_NAME = get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format);
// Get film dimensions by calling functions from film-sizes.scad
FILM_FORMAT_HEIGHT_RAW = (Film_Format == "custom") ? Custom_Film_Format_Opening_Height : get_film_format_height(Film_Format);
FILM_FORMAT_WIDTH_RAW = (Film_Format == "custom") ? Custom_Film_Format_Opening_Width : get_film_format_width(Film_Format);
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

// Text positioning and boundary calculations
owner_metrics = textmetrics(text=Owner_Name, font=Fontface, size=10, halign="center", valign="center");
type_metrics = textmetrics(text=SELECTED_TYPE_NAME, font=Fontface, size=10, halign="center", valign="center");

// Safe circular area boundaries for text placement (LPL uses circular carrier)
safe_circle_radius = LPL_CARRIER_DIAMETER / 2 - 13; // 13mm margin from edge
safe_min_x = -safe_circle_radius;
safe_max_x = safe_circle_radius;
safe_min_y = -safe_circle_radius;
safe_max_y = safe_circle_radius;

// Owner name text boundaries (rotated 270 degrees)
owner_rotated_size_x = owner_metrics.size[1];
owner_rotated_size_y = owner_metrics.size[0];
owner_center_x = -80;
owner_center_y = -35;
owner_min_x = owner_center_x - owner_rotated_size_x / 2;
owner_max_x = owner_center_x + owner_rotated_size_x / 2;
owner_min_y = owner_center_y - owner_rotated_size_y / 2;
owner_max_y = owner_center_y + owner_rotated_size_y / 2;

// Type name text boundaries (rotated 270 degrees)
type_rotated_size_x = type_metrics.size[1];
type_rotated_size_y = type_metrics.size[0];
type_center_x = -80;
type_center_y = 40;
type_min_x = type_center_x - type_rotated_size_x / 2;
type_max_x = type_center_x + type_rotated_size_x / 2;
type_min_y = type_center_y - type_rotated_size_y / 2;
type_max_y = type_center_y + type_rotated_size_y / 2;

// Validate text fits within safe area boundaries using shared validation
validate_text_bounds(
    text_string=Owner_Name,
    font_face=Fontface,
    font_size=10,
    center_x=owner_center_x,
    center_y=owner_center_y,
    rotation_angle=270,
    safe_min_x=safe_min_x,
    safe_max_x=safe_max_x,
    safe_min_y=safe_min_y,
    safe_max_y=safe_max_y,
    text_label="Owner Name"
);

validate_text_bounds(
    text_string=SELECTED_TYPE_NAME,
    font_face=Fontface,
    font_size=10,
    center_x=type_center_x,
    center_y=type_center_y,
    rotation_angle=270,
    safe_min_x=safe_min_x,
    safe_max_x=safe_max_x,
    safe_min_y=safe_min_y,
    safe_max_y=safe_max_y,
    text_label="Type Name"
);

// Multi-material text depth calculations
TEXT_SOLID_HEIGHT = Layer_Height_mm * Text_Layer_Multiple;
TEXT_SUBTRACT_DEPTH = Text_As_Separate_Parts ? TEXT_SOLID_HEIGHT : TEXT_ETCH_DEPTH;
TEXT_SOLID_Z_POSITION = CARRIER_HALF_HEIGHT - TEXT_SOLID_HEIGHT;

// Text etching position calculations
owner_etch_bottom_margin = 5;
owner_etch_bottom_position = safe_max_y - owner_etch_bottom_margin - 20;
owner_etch_pos = [owner_etch_bottom_position, -65, TEXT_ETCH_Z_POSITION];
owner_etch_rot = [0, 0, 90];

type_etch_top_margin = 5;
type_etch_top_position = safe_min_y + type_etch_top_margin + 20;
type_etch_pos = [type_etch_top_position, -65, TEXT_ETCH_Z_POSITION];
type_etch_rot = [0, 0, 90];

// Peg positioning calculations using updated constants
peg_z_offset_calc =
    (Top_or_Bottom == "top") ?
        (LPL_CARRIER_HEIGHT - 0)
    : CARRIER_HALF_HEIGHT;

// peg_pos_x_final and peg_pos_y_final are half the distance between opposite peg centers.
// Assumes FILM_FORMAT_WIDTH_RAW is the film's narrow dimension and LPL_PEG_DISTANCE is the longitudinal peg pitch.
// Peg_Gap is added to position pegs further from the film edge.
peg_pos_x_final =
    effective_orientation == "vertical" ?
        (FILM_FORMAT_WIDTH_RAW / 2 + LPL_PEG_DIAMETER / 2 + Peg_Gap)
    : (FILM_FORMAT_HEIGHT_RAW / 2 + LPL_PEG_DIAMETER / 2 + Peg_Gap);

peg_pos_y_final =
    effective_orientation == "vertical" ?
        (FILM_FORMAT_HEIGHT_RAW / 2 + LPL_PEG_DIAMETER / 2 + Peg_Gap)
    : (FILM_FORMAT_WIDTH_RAW / 2 + LPL_PEG_DIAMETER / 2 + Peg_Gap);

/**
 * Creates edge cuts for the LPL Saunders carrier
 * Removes material from the circular base to create the characteristic shape
 */
module carrier_edge_cuts() {
    translate([0, LPL_EDGE_CUTS_DISTANCE, 0])
        cuboid([LPL_EDGE_CUTS_WIDTH, LPL_EDGE_CUTS_HEIGHT, LPL_CARRIER_HEIGHT + 0.1], anchor=CENTER);
    translate([0, -LPL_EDGE_CUTS_DISTANCE, 0])
        cuboid([LPL_EDGE_CUTS_WIDTH, LPL_EDGE_CUTS_HEIGHT, LPL_CARRIER_HEIGHT + 0.1], anchor=CENTER);
    translate([LPL_EDGE_CUTS_DISTANCE, 0, 0])
        cuboid([LPL_EDGE_CUTS_HEIGHT, LPL_EDGE_CUTS_WIDTH, LPL_CARRIER_HEIGHT + 0.1], anchor=CENTER);
    translate([-LPL_EDGE_CUTS_DISTANCE, 0, 0])
        cuboid([LPL_EDGE_CUTS_HEIGHT, LPL_EDGE_CUTS_WIDTH, LPL_CARRIER_HEIGHT + 0.1], anchor=CENTER);
}

/**
 * Creates the basic LPL Saunders carrier shape
 * Circular base with edge cuts to create the characteristic shape
 */
module base_shape() {
    difference() {
        cyl(h=LPL_CARRIER_HEIGHT, r=LPL_CARRIER_DIAMETER / 2, anchor=CENTER);
        carrier_edge_cuts();
    }
}

/**
 * Creates the handle for the LPL Saunders carrier
 * Position varies based on top or bottom carrier
 */
module handle() {
    if (Top_or_Bottom == "top") {
        translate([LPL_CARRIER_DIAMETER / 2, LPL_HANDLE_X_OFFSET, 0])
            cuboid(
                [LPL_HANDLE_WIDTH, LPL_HANDLE_HEIGHT, LPL_CARRIER_HEIGHT],
                anchor=CENTER, rounding=2,
                edges=[FWD + RIGHT, BACK + LEFT, FWD + LEFT, BACK + RIGHT]
            );
    } else {
        translate([LPL_CARRIER_DIAMETER / 2, -LPL_HANDLE_X_OFFSET, 0])
            cuboid(
                [LPL_HANDLE_WIDTH, LPL_HANDLE_HEIGHT, LPL_CARRIER_HEIGHT],
                anchor=CENTER, rounding=2,
                edges=[FWD + RIGHT, BACK + LEFT, FWD + LEFT, BACK + RIGHT]
            );
    }
}

/**
 * Creates a left-pointing arrow shape for directional etching
 * Used to indicate film orientation on 6x6 format carriers
 * @param etch_depth Depth of the etched arrow
 * @param length Arrow length
 * @param width Arrow width
 */
module arrow_etch(etch_depth = 0.5, length = 5, width = 3) {
    translate([-10, 0, .5])
        linear_extrude(height=etch_depth + 0.1)
            polygon(points=[[-length / 2, 0], [length / 2, width / 2], [length / 2, -width / 2]]);
}

/**
 * Generates multi-material text parts for LPL Saunders carrier
 * Uses shared text etching library with LPL-specific positioning
 */
module generate_multi_material_text_parts() {
    owner_text_solid_pos = [owner_etch_bottom_position, -75, TEXT_SOLID_Z_POSITION];
    type_text_solid_pos = [type_etch_top_position, -75, TEXT_SOLID_Z_POSITION];

    generate_shared_multi_material_text_parts(
        owner_name=Owner_Name,
        type_name=SELECTED_TYPE_NAME,
        enable_owner_etch=Enable_Owner_Name_Etch,
        enable_type_etch=Enable_Type_Name_Etch,
        owner_position=owner_text_solid_pos,
        type_position=type_text_solid_pos,
        owner_rotation=owner_etch_rot,
        type_rotation=type_etch_rot,
        font_face=Fontface,
        font_size=Font_Size,
        text_height=TEXT_SOLID_HEIGHT,
        text_as_separate_parts=Text_As_Separate_Parts,
        which_part=_WhichPart
    );
}

/**
 * Generates text etch subtractions for LPL Saunders carrier
 * Uses shared text etching library with LPL-specific positioning
 */
module generate_text_etch_subtractions() {
    generate_shared_text_etch_subtractions(
        owner_name=Owner_Name,
        type_name=SELECTED_TYPE_NAME,
        enable_owner_etch=Enable_Owner_Name_Etch,
        enable_type_etch=Enable_Type_Name_Etch,
        owner_position=owner_etch_pos,
        type_position=type_etch_pos,
        owner_rotation=owner_etch_rot,
        type_rotation=type_etch_rot,
        font_face=Fontface,
        font_size=Font_Size,
        etch_depth=TEXT_SUBTRACT_DEPTH
    );
}

/**
 * Local Part module for LPL Saunders carrier compatibility
 * Wraps shared Part functionality with local color scheme
 * @param DoPart Part name to conditionally render
 */
module Part(DoPart) {
    color(SharedPartColor(DoPart)) {
        if (_WhichPart == "All" || DoPart == _WhichPart) {
            children();
        }
    }
}

/**
 * Generates the bottom carrier assembly with all its components
 * This module contains the original bottom carrier logic
 */
module bottom_carrier_assembly() {
    Part("Base") union() {
            carrier_base_processing(
                _top_or_bottom=Top_or_Bottom,
                _carrier_material_height=LPL_CARRIER_HEIGHT,
                _opening_height_param=adjusted_opening_height,
                _opening_width_param=adjusted_opening_width,
                _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                _opening_fillet_param=Film_Opening_Frame_Fillet,
                _peg_style_param=Printed_or_Heat_Set_Pegs,
                _peg_diameter_param=LPL_PEG_DIAMETER,
                _peg_actual_height_param=LPL_PEG_HEIGHT,
                _peg_pos_x_param=peg_pos_x_final,
                _peg_pos_y_param=peg_pos_y_final,
                _peg_z_offset_param=peg_z_offset_calc - 0.1
            ) {
                difference() {
                    base_shape();
                    if (!Alignment_Board) {
                        // If Alignment_Board is OFF, and type implies screws, punch the alignment footprint holes
                        if (Alignment_Board_Type == "omega" || Alignment_Board_Type == "lpl-saunders") {
                            alignment_footprint_holes(
                                _screw_dia=LPL_ALIGNMENT_SCREW_DIAMETER,
                                _dist_for_x_coords=LPL_ALIGNMENT_SCREW_PATTERN_DIST_X,
                                _dist_for_y_coords=LPL_ALIGNMENT_SCREW_PATTERN_DIST_Y,
                                _carrier_h=LPL_CARRIER_HEIGHT,
                                _cut_ext=CUT_THROUGH_EXTENSION,
                                _is_dent=false, // Bottom piece gets through-holes
                                _dent_depth=1
                            );
                        }
                    }
                    generate_text_etch_subtractions();
                    // Add directional arrow for 6x6 formats
                    if (Film_Format == "6x6" || Film_Format == "6x6 filed") {
                        arrowOffset = 5;
                        if (Orientation == "vertical") {
                            currentOpeningWidth = FILM_FORMAT_WIDTH_RAW;
                            arrowPosX = 0;
                            arrowPosY = currentOpeningWidth / 2 + arrowOffset + ARROW_LENGTH / 2;
                            translate([arrowPosX + 10, -arrowPosY, 0])
                                arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                        } else {
                            currentOpeningHeight = FILM_FORMAT_HEIGHT_RAW;
                            arrowPosX = 0;
                            arrowPosY = -currentOpeningHeight / 2 - arrowOffset - ARROW_LENGTH / 2;
                            translate([arrowPosX, arrowPosY, 0])
                                rotate([0, 0, 90])
                                    arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                        }
                    }
                }
            }

            handle(); // Add the handle to the carrier part

            // Add alignment board if enabled
            if (Alignment_Board) {
                _z_trans_val =
                    (Alignment_Board_Type == "omega") ? -1.4
                    : (Alignment_Board_Type == "lpl-saunders") ? -LPL_CARRIER_HEIGHT
                    : (Alignment_Board_Type == "beseler-23c") ? -LPL_CARRIER_HEIGHT
                    : 0;
                translate([0, 0, _z_trans_val])
                    instantiate_alignment_board_by_type(Alignment_Board_Type);
            }
        }
}

// Main carrier generation logic
if (Top_or_Bottom == "bottom") {
    // Apply rotation for printable orientation if enabled
    if (Flip_Bottom_For_Printing) {
        rotate([180, 0, 0]) {
            bottom_carrier_assembly();
        }
    } else {
        bottom_carrier_assembly();
    }

    generate_multi_material_text_parts();
} else if (Top_or_Bottom == "top") {
    Part("Base") carrier_base_processing(
            _top_or_bottom=Top_or_Bottom,
            _carrier_material_height=LPL_CARRIER_HEIGHT,
            _opening_height_param=adjusted_opening_height,
            _opening_width_param=adjusted_opening_width,
            _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
            _opening_fillet_param=Film_Opening_Frame_Fillet,
            _peg_style_param=Printed_or_Heat_Set_Pegs,
            _peg_diameter_param=LPL_PEG_DIAMETER,
            _peg_actual_height_param=LPL_PEG_HEIGHT,
            _peg_pos_x_param=peg_pos_x_final,
            _peg_pos_y_param=peg_pos_y_final,
            _peg_z_offset_param=peg_z_offset_calc - 1
        ) {
            union() {
                difference() {
                    base_shape();
                    generate_text_etch_subtractions();
                }
                handle(); // Add the handle to the carrier part
            }
        }

    generate_multi_material_text_parts();
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    // Generate test pieces for fit validation
    testPiecePadding = 10;
    testPieceWidth = 2 * peg_pos_y_final + LPL_PEG_DIAMETER + testPiecePadding * 2;
    testPieceDepth = 2 * peg_pos_x_final + LPL_PEG_DIAMETER + testPiecePadding * 2;
    test_peg_z_offset = CARRIER_HALF_HEIGHT;
    effective_test_top_bottom = (Top_or_Bottom == "frameAndPegTestTop") ? "top" : "bottom";

    generate_test_frame(
        _effective_test_piece_role=effective_test_top_bottom,
        _frame_material_height=LPL_CARRIER_HEIGHT,
        _film_opening_h=adjusted_opening_height,
        _film_opening_w=adjusted_opening_width,
        _film_opening_cut_ext=CUT_THROUGH_EXTENSION,
        _film_opening_f=Film_Opening_Frame_Fillet,
        _peg_style=Printed_or_Heat_Set_Pegs,
        _peg_dia_val=LPL_PEG_DIAMETER,
        _peg_h_val=LPL_PEG_HEIGHT,
        _peg_x_val=peg_pos_x_final,
        _peg_y_val=peg_pos_y_final,
        _peg_z_val=test_peg_z_offset,
        _test_cuboid_width=testPieceWidth,
        _test_cuboid_depth=testPieceDepth
    );
}
