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
// Flip bottom carriers to printable orientation (rotate 180° on X-axis)
Flip_Bottom_For_Printing = true; // [true, false]

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
$fn=100;

// Omega-D carrier base dimensions
OMEGA_D_CARRIER_LENGTH = 202;
OMEGA_D_CARRIER_WIDTH = 139;
OMEGA_D_CARRIER_HEIGHT = 2;
OMEGA_D_CARRIER_CIRCLE_DIAMETER = 168;
OMEGA_D_CARRIER_RECT_OFFSET = 13.5;
OMEGA_D_CARRIER_FILLET = 5;
OMEGA_D_FRAME_FILLET = 0.5;

// Film positioning peg dimensions
OMEGA_D_PEG_DIAMETER = 5.6;
OMEGA_D_PEG_HEIGHT = 4;

// Registration hole dimensions and positioning
OMEGA_D_REG_HOLE_DIAMETER = 6.2;
OMEGA_D_REG_HOLE_DISTANCE = 130;
OMEGA_D_REG_HOLE_X_LENGTH = 5;
OMEGA_D_REG_HOLE_OFFSET = 4.5;
OMEGA_D_REG_HOLE_TOP_X_OFFSET = 5;
OMEGA_D_REG_HOLE_BOTTOM_X_OFFSET = -7;

// Alignment board screw hole dimensions
OMEGA_D_ALIGNMENT_SCREW_DIAMETER = 2;
OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X = 113;
OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y = 82;

// General modeling constants
CUT_THROUGH_EXTENSION = 1;
OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION = 0;
OMEGA_D_REG_HOLE_CYL_Y_OFFSET = 3.1;
OMEGA_D_TOP_PEG_HOLE_Z_OFFSET = 2;

// Direction arrow dimensions for 6x6 format
ARROW_LENGTH = 8;
ARROW_WIDTH = 5;
ARROW_ETCH_DEPTH = 0.5;

// Z-axis positioning calculations
TEXT_ETCH_Z_POSITION = OMEGA_D_CARRIER_HEIGHT / 2 - (TEXT_ETCH_DEPTH + 0.1);
CARRIER_HALF_HEIGHT = OMEGA_D_CARRIER_HEIGHT / 2;

// Film format type detection
IS_FILED_MEDIUM_FORMAT = Film_Format == "6x4.5 filed" ||
    Film_Format == "6x6 filed" ||
    Film_Format == "6x7 filed" ||
    Film_Format == "6x8 filed" ||
    Film_Format == "6x9 filed";

// Peg gap calculation adjusted for filed medium formats
CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - Peg_Gap) - 1 : (1 - Peg_Gap);

// Film format dimensions from film-sizes.scad
FILM_FORMAT_HEIGHT = get_film_format_height(Film_Format);
FILM_FORMAT_WIDTH = get_film_format_width(Film_Format);
FILM_FORMAT_PEG_DISTANCE = get_film_format_peg_distance(Film_Format);

// Validate film format selection
assert(FILM_FORMAT_HEIGHT != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
assert(FILM_FORMAT_WIDTH != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
assert(FILM_FORMAT_PEG_DISTANCE != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
if (Alignment_Board && Printed_or_Heat_Set_Pegs == "printed") {
    assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
}

// Generate carrier type name for etching
SELECTED_TYPE_NAME = get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format);

// Text positioning and boundary calculations
owner_metrics = textmetrics(text=Owner_Name, font=Fontface, size=10, halign="center", valign="center");
type_metrics = textmetrics(text=SELECTED_TYPE_NAME, font=Fontface, size=10, halign="center", valign="center");

// Safe rectangular area boundaries for text placement
safe_rect_center_x = -OMEGA_D_CARRIER_RECT_OFFSET;
safe_rect_size_x = OMEGA_D_CARRIER_LENGTH;
safe_rect_size_y = OMEGA_D_CARRIER_WIDTH;
safe_min_x = safe_rect_center_x - safe_rect_size_x / 2;
safe_max_x = safe_rect_center_x + safe_rect_size_x / 2;
safe_min_y = -safe_rect_size_y / 2;
safe_max_y = safe_rect_size_y / 2;

// Owner name text boundaries (rotated 270 degrees)
owner_rotated_size_x = owner_metrics.size[1];
owner_rotated_size_y = owner_metrics.size[0];
owner_center_x = -100;
owner_center_y = -35;
owner_min_x = owner_center_x - owner_rotated_size_x / 2;
owner_max_x = owner_center_x + owner_rotated_size_x / 2;
owner_min_y = owner_center_y - owner_rotated_size_y / 2;
owner_max_y = owner_center_y + owner_rotated_size_y / 2;

// Type name text boundaries (rotated 270 degrees)
type_rotated_size_x = type_metrics.size[1];
type_rotated_size_y = type_metrics.size[0];
type_center_x = -100;
type_center_y = 40;
type_min_x = type_center_x - type_rotated_size_x / 2;
type_max_x = type_center_x + type_rotated_size_x / 2;
type_min_y = type_center_y - type_rotated_size_y / 2;
type_max_y = type_center_y + type_rotated_size_y / 2;

// Validate text fits within safe area boundaries
assert(owner_min_x >= safe_min_x && owner_max_x <= safe_max_x,
       str("ERROR: Owner Name '", Owner_Name, "' X dimension [", owner_min_x, ", ", owner_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider shortening the name or adjusting position."));
assert(owner_min_y >= safe_min_y && owner_max_y <= safe_max_y,
       str("ERROR: Owner Name '", Owner_Name, "' Y dimension [", owner_min_y, ", ", owner_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider shortening the name or adjusting position."));
assert(type_min_x >= safe_min_x && type_max_x <= safe_max_x,
       str("ERROR: Type Name '", SELECTED_TYPE_NAME, "' X dimension [", type_min_x, ", ", type_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider adjusting position."));
assert(type_min_y >= safe_min_y && type_max_y <= safe_max_y,
       str("ERROR: Type Name '", SELECTED_TYPE_NAME, "' Y dimension [", type_min_y, ", ", type_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider adjusting position."));

// Multi-material text depth calculations
TEXT_SOLID_HEIGHT = Layer_Height_mm * Text_Layer_Multiple;
TEXT_SUBTRACT_DEPTH = Text_As_Separate_Parts ? TEXT_SOLID_HEIGHT : TEXT_ETCH_DEPTH;
TEXT_SOLID_Z_POSITION = CARRIER_HALF_HEIGHT - TEXT_SOLID_HEIGHT;

/**
 * Generates multi-material text parts for separate printing
 * Creates solid text objects positioned for multi-color printing
 */
module generate_multi_material_text_parts() {
    if (Text_As_Separate_Parts) {
        owner_text_solid_pos = [owner_etch_bottom_position, -95, TEXT_SOLID_Z_POSITION];
        type_text_solid_pos = [type_etch_top_position, -95, TEXT_SOLID_Z_POSITION];
        
        if (Enable_Owner_Name_Etch) {
            Part("OwnerText")
                rotate(owner_etch_rot) translate(owner_text_solid_pos)
                    text_solid(
                        text_string = Owner_Name,
                        font = Fontface,
                        size = Font_Size,
                        height = TEXT_SOLID_HEIGHT,
                        halign = "right",
                        valign = "top"
                    );
        }
        if (Enable_Type_Name_Etch) {
            Part("TypeText")
                rotate(type_etch_rot) translate(type_text_solid_pos)
                    text_solid(
                        text_string = SELECTED_TYPE_NAME,
                        font = Fontface,
                        size = Font_Size,
                        height = TEXT_SOLID_HEIGHT,
                        halign = "left",
                        valign = "top"
                    );
        }
    }
}

/**
 * Generates alignment board footprint holes
 * @param is_dent_holes true for top piece (dents), false for bottom piece (through-holes)
 */
module generate_alignment_footprint_holes(is_dent_holes = false) {
    if (!Alignment_Board) {
        if (Alignment_Board_Type == "omega" || Alignment_Board_Type == "lpl-saunders") {
            alignment_footprint_holes(
                _screw_dia = OMEGA_D_ALIGNMENT_SCREW_DIAMETER,
                _dist_for_x_coords = OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y,
                _dist_for_y_coords = OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X,
                _carrier_h = OMEGA_D_CARRIER_HEIGHT,
                _cut_ext = CUT_THROUGH_EXTENSION,
                _is_dent = is_dent_holes,
                _dent_depth = 1
            );
        }
    }
}

/**
 * Generates text etch subtractions for owner and type names
 * Creates recessed text areas on the carrier surface
 */
module generate_text_etch_subtractions() {
    if (Enable_Owner_Name_Etch) {
        rotate(owner_etch_rot) translate(owner_etch_pos)
            text_etch(
                text_string = Owner_Name,
                font = Fontface,
                size = Font_Size,
                etch_depth = TEXT_SUBTRACT_DEPTH,
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
                etch_depth = TEXT_SUBTRACT_DEPTH,
                halign = "left",
                valign = "top"
            );
    }
}

/**
 * Maps part names to preview colors for multi-material visualization
 * @param part Part name string
 * @return Color name for OpenSCAD preview
 */
function PartColor(part) =
    (part == "Base") ? "grey" :
    (part == "OwnerText") ? "orange" :
    (part == "TypeText") ? "purple" :
    "gray";

/**
 * Part gating module for multi-material printing
 * Controls which parts are rendered based on selection
 * @param DoPart Part name to conditionally render
 */
module Part(DoPart) {
    color(PartColor(DoPart)) {
        if (_WhichPart == "All" || DoPart == _WhichPart) {
            children();
        }
    }
}

/**
 * Creates the basic Omega-D carrier shape
 * Combines circular and rectangular sections with rounded edges
 */
module base_shape() {
    color("grey") union() {
        cylinder(h=OMEGA_D_CARRIER_HEIGHT, r=OMEGA_D_CARRIER_CIRCLE_DIAMETER/2, center = true);
        translate([-OMEGA_D_CARRIER_RECT_OFFSET, 0, 0]) 
            cuboid([OMEGA_D_CARRIER_LENGTH, OMEGA_D_CARRIER_WIDTH, OMEGA_D_CARRIER_HEIGHT], 
                   anchor = CENTER, rounding=OMEGA_D_CARRIER_FILLET, 
                   edges=[[0,0,0,0], [0,0,0,0], [1,1,1,1]]);
    }
}

/**
 * Creates registration holes for Omega-D enlarger alignment
 * Generates top and bottom registration slots with cylindrical extensions
 */
module registration_holes() {
    translate([0, -1.5, 0]) {
        // Top registration hole
        union() {
            color("red") translate([OMEGA_D_REG_HOLE_TOP_X_OFFSET + (OMEGA_D_REG_HOLE_DISTANCE/2) + OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2, 0]) 
                cuboid([OMEGA_D_REG_HOLE_DIAMETER, OMEGA_D_REG_HOLE_DIAMETER + OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION, OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
            color("red") translate([OMEGA_D_REG_HOLE_TOP_X_OFFSET + (OMEGA_D_REG_HOLE_DISTANCE/2) + OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_CYL_Y_OFFSET, 0]) 
                cylinder(h=OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=OMEGA_D_REG_HOLE_DIAMETER/2, center = true);
        }
        // Bottom registration hole
        union() {
            color("red") translate([OMEGA_D_REG_HOLE_BOTTOM_X_OFFSET - (OMEGA_D_REG_HOLE_DISTANCE/2) - OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2, 0]) 
                cuboid([OMEGA_D_REG_HOLE_DIAMETER, OMEGA_D_REG_HOLE_DIAMETER + OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION, OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
            color("red") translate([OMEGA_D_REG_HOLE_BOTTOM_X_OFFSET - (OMEGA_D_REG_HOLE_DISTANCE/2) - OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_CYL_Y_OFFSET, 0]) 
                cylinder(h=OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=OMEGA_D_REG_HOLE_DIAMETER/2, center = true);
        }
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
    translate([-10 ,0, .5]) 
        linear_extrude(height = etch_depth + 0.1) 
            polygon(points=[ [-length/2, 0], [length/2, width/2], [length/2, -width/2] ]);
}

// Film opening calculations using carrier-features.scad functions
effective_orientation = get_effective_orientation(Film_Format, Orientation);
adjusted_opening_height = get_final_opening_height(Film_Format, Orientation, Adjust_Film_Height);
adjusted_opening_width = get_final_opening_width(Film_Format, Orientation, Adjust_Film_Width);

// Peg positioning calculations
peg_z_offset_calc = (Top_or_Bottom == "top") ? 
    (OMEGA_D_CARRIER_HEIGHT - OMEGA_D_TOP_PEG_HOLE_Z_OFFSET) : 
    CARRIER_HALF_HEIGHT;

// Calculate peg positions using Omega-style coordinate system
peg_pos_x_calc = calculate_omega_style_peg_coordinate(
    is_dominant_film_dimension = (effective_orientation == "vertical"),
    film_width_or_equiv_half = FILM_FORMAT_WIDTH / 2,
    film_peg_distance_half = FILM_FORMAT_PEG_DISTANCE / 2,
    peg_radius = OMEGA_D_PEG_DIAMETER / 2,
    omega_internal_gap_value = CALCULATED_INTERNAL_PEG_GAP
);

peg_pos_y_calc = calculate_omega_style_peg_coordinate(
    is_dominant_film_dimension = (effective_orientation == "horizontal"),
    film_width_or_equiv_half = FILM_FORMAT_WIDTH / 2,
    film_peg_distance_half = FILM_FORMAT_PEG_DISTANCE / 2,
    peg_radius = OMEGA_D_PEG_DIAMETER / 2,
    omega_internal_gap_value = CALCULATED_INTERNAL_PEG_GAP
);

// Text etching position calculations
owner_etch_bottom_margin = 5;
owner_etch_bottom_position = safe_max_y - owner_etch_bottom_margin;
owner_etch_pos = [owner_etch_bottom_position, -95, TEXT_ETCH_Z_POSITION];
owner_etch_rot = [0, 0, 270];

type_etch_top_margin = 5;
type_etch_top_position = safe_min_y + type_etch_top_margin;
type_etch_pos = [type_etch_top_position, -95, TEXT_ETCH_Z_POSITION];
type_etch_rot = [0, 0, 270];

/**
 * Generates the bottom carrier assembly with all its components
 * This module contains the original bottom carrier logic
 */
module bottom_carrier_assembly() {
    Part("Base") union() {
        carrier_base_processing(
            _top_or_bottom = Top_or_Bottom,
            _carrier_material_height = OMEGA_D_CARRIER_HEIGHT,
            _opening_height_param = adjusted_opening_height,
            _opening_width_param = adjusted_opening_width,
            _opening_cut_through_ext_param = CUT_THROUGH_EXTENSION,
            _opening_fillet_param = OMEGA_D_FRAME_FILLET,
            _peg_style_param = Printed_or_Heat_Set_Pegs,
            _peg_diameter_param = OMEGA_D_PEG_DIAMETER,
            _peg_actual_height_param = OMEGA_D_PEG_HEIGHT,
            _peg_pos_x_param = peg_pos_x_calc,
            _peg_pos_y_param = peg_pos_y_calc,
            _peg_z_offset_param = peg_z_offset_calc + 0.1
        ) {
            difference() {
                base_shape();
                registration_holes();
                generate_alignment_footprint_holes(is_dent_holes = false);
                generate_text_etch_subtractions();
                // Add directional arrow for 6x6 formats
                if (Film_Format == "6x6" || Film_Format == "6x6 filed") {
                    arrowOffset = 5;
                    if (Orientation == "vertical") {
                        currentOpeningWidth = FILM_FORMAT_WIDTH;
                        arrowPosX = 0;
                        arrowPosY = currentOpeningWidth / 2 + arrowOffset + ARROW_LENGTH / 2;
                        translate([arrowPosX + 10, -arrowPosY , 0])
                            arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                    } else {
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

        // Add alignment board if enabled
        if (Alignment_Board) {
            _z_trans_val = (Alignment_Board_Type == "omega") ? -1.4 :
                           (Alignment_Board_Type == "lpl-saunders") ? 0.15 :
                           0; 
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
        _top_or_bottom = Top_or_Bottom,
        _carrier_material_height = OMEGA_D_CARRIER_HEIGHT,
        _opening_height_param = adjusted_opening_height,
        _opening_width_param = adjusted_opening_width,
        _opening_cut_through_ext_param = CUT_THROUGH_EXTENSION,
        _opening_fillet_param = OMEGA_D_FRAME_FILLET,
        _peg_style_param = Printed_or_Heat_Set_Pegs,
        _peg_diameter_param = OMEGA_D_PEG_DIAMETER,
        _peg_actual_height_param = OMEGA_D_PEG_HEIGHT,
        _peg_pos_x_param = peg_pos_x_calc,
        _peg_pos_y_param = peg_pos_y_calc,
        _peg_z_offset_param = peg_z_offset_calc
    ) {
        difference() {
            base_shape();
            registration_holes(); 
            generate_alignment_footprint_holes(is_dent_holes = true);
            generate_text_etch_subtractions();
        }
    }

    generate_multi_material_text_parts();

} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    // Generate test pieces for fit validation
    testPiecePadding = 10; 
    testPieceWidth = 2 * peg_pos_y_calc + OMEGA_D_PEG_DIAMETER + testPiecePadding * 2;
    testPieceDepth = 2 * peg_pos_x_calc + OMEGA_D_PEG_DIAMETER + testPiecePadding * 2;
    test_peg_z_offset = CARRIER_HALF_HEIGHT;
    effective_test_top_bottom = (Top_or_Bottom == "frameAndPegTestTop") ? "top" : "bottom";

    generate_test_frame(
        _effective_test_piece_role = effective_test_top_bottom,
        _frame_material_height = OMEGA_D_CARRIER_HEIGHT,
        _film_opening_h = adjusted_opening_height,
        _film_opening_w = adjusted_opening_width,
        _film_opening_cut_ext = CUT_THROUGH_EXTENSION,
        _film_opening_f = OMEGA_D_FRAME_FILLET,
        _peg_style = Printed_or_Heat_Set_Pegs,
        _peg_dia_val = OMEGA_D_PEG_DIAMETER,
        _peg_h_val = OMEGA_D_PEG_HEIGHT,
        _peg_x_val = peg_pos_x_calc,
        _peg_y_val = peg_pos_y_calc,
        _peg_z_val = test_peg_z_offset,
        _test_cuboid_width = testPieceWidth,
        _test_cuboid_depth = testPieceDepth
    );
}

