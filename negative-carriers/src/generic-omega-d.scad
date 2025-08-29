// Generic Omega-D Carrier Template
// This module provides parameterized Omega-D carrier generation
// Called from main carrier.scad with configuration parameters

include <BOSL2/std.scad>
include <common/film-sizes.scad>
include <common/carrier-features.scad>
include <common/omega-d-alignment-board.scad>
include <common/lpl-saunders-alignment-board.scad>
include <common/text-etching.scad>

/**
 * Generic Omega-D carrier generation module
 * All dimensions and positioning are parameterized for flexibility
 *
 * @param config - Configuration array containing all carrier-specific parameters:
 *   [0] = carrier_length (default: 202)
 *   [1] = carrier_width (default: 139) 
 *   [2] = carrier_height (default: 2)
 *   [3] = carrier_circle_diameter (default: 168)
 *   [4] = carrier_rect_offset (default: 13.5)
 *   [5] = carrier_fillet (default: 5)
 *   [6] = frame_fillet (default: 0.5)
 *   [7] = peg_diameter (default: 5.6)
 *   [8] = peg_height (default: 4)
 *   [9] = reg_hole_diameter (default: 6.2)
 *   [10] = reg_hole_distance (default: 130)
 *   [11] = reg_hole_x_length (default: 5)
 *   [12] = reg_hole_offset (default: 4.5)
 *   [13] = reg_hole_top_x_offset (default: 5)
 *   [14] = reg_hole_bottom_x_offset (default: -7)
 *   [15] = alignment_screw_diameter (default: 2)
 *   [16] = alignment_screw_distance_x (default: 113)
 *   [17] = alignment_screw_distance_y (default: 82)
 *   [18] = top_peg_hole_z_offset (default: 2)
 *   [19] = text_etch_y_translate (default: -90)
 *   [20] = owner_etch_bottom_margin (default: 5)
 *   [21] = type_etch_top_margin (default: 5)
 *
 * @param top_or_bottom - "top" or "bottom"
 * @param printed_or_heat_set_pegs - "printed" or "heat_set"
 * @param alignment_board - true/false
 * @param alignment_board_type - "omega", "lpl-saunders", etc.
 * @param flip_bottom_for_printing - true/false
 * @param enable_owner_name_etch - true/false
 * @param owner_name - Owner name string
 * @param enable_type_name_etch - true/false
 * @param selected_type_name - Type name string
 * @param fontface - Font family string
 * @param font_size - Font size number
 * @param text_etch_depth - Text etch depth
 * @param text_as_separate_parts - true/false
 * @param layer_height_mm - Layer height for multi-material
 * @param text_layer_multiple - Text layer count multiplier
 * @param which_part - "All", "Base", "OwnerText", "TypeText"
 * @param opening_height - Pre-calculated film opening height
 * @param opening_width - Pre-calculated film opening width
 * @param peg_pos_x - Pre-calculated peg X position
 * @param peg_pos_y - Pre-calculated peg Y position
 * @param film_format_for_arrows - Film format string (for directional arrows only)
 */
module generic_omega_d_carrier(
    config,
    top_or_bottom,
    printed_or_heat_set_pegs,
    alignment_board,
    alignment_board_type,
    flip_bottom_for_printing,
    enable_owner_name_etch,
    owner_name,
    enable_type_name_etch,
    selected_type_name,
    fontface,
    font_size,
    text_etch_depth,
    text_as_separate_parts,
    layer_height_mm,
    text_layer_multiple,
    which_part,
    // Pre-calculated values from carrier.scad
    opening_height,
    opening_width,
    peg_pos_x,
    peg_pos_y,
    film_format_for_arrows
) {
    // Extract configuration parameters
    CARRIER_LENGTH = config[0];
    CARRIER_WIDTH = config[1];
    CARRIER_HEIGHT = config[2];
    CARRIER_CIRCLE_DIAMETER = config[3];
    CARRIER_RECT_OFFSET = config[4];
    CARRIER_FILLET = config[5];
    FRAME_FILLET = config[6];
    PEG_DIAMETER = config[7];
    PEG_HEIGHT = config[8];
    REG_HOLE_DIAMETER = config[9];
    REG_HOLE_DISTANCE = config[10];
    REG_HOLE_X_LENGTH = config[11];
    REG_HOLE_OFFSET = config[12];
    REG_HOLE_TOP_X_OFFSET = config[13];
    REG_HOLE_BOTTOM_X_OFFSET = config[14];
    ALIGNMENT_SCREW_DIAMETER = config[15];
    ALIGNMENT_SCREW_DISTANCE_X = config[16];
    ALIGNMENT_SCREW_DISTANCE_Y = config[17];
    TOP_PEG_HOLE_Z_OFFSET = config[18];
    TEXT_ETCH_Y_TRANSLATE = config[19];
    OWNER_ETCH_BOTTOM_MARGIN = config[20];
    TYPE_ETCH_TOP_MARGIN = config[21];

    // General modeling constants
    CUT_THROUGH_EXTENSION = 1;
    REG_HOLE_SLOT_LENGTH_EXTENSION = 0;
    REG_HOLE_CYL_Y_OFFSET = 3.1;

    // Direction arrow dimensions for 6x6 format (now using centralized values from carrier-features.scad)
    // ARROW_LENGTH, ARROW_WIDTH, and ARROW_ETCH_DEPTH are now defined in carrier-features.scad

    // Z-axis positioning calculations
    TEXT_ETCH_Z_POSITION = CARRIER_HEIGHT / 2 - (text_etch_depth + 0.1);
    CARRIER_HALF_HEIGHT = CARRIER_HEIGHT / 2;

    if (alignment_board && printed_or_heat_set_pegs == "printed") {
        assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
    }

    // Peg positioning calculations (Z-offset only, X/Y positions come from carrier.scad)
    peg_z_offset_calc = (top_or_bottom == "top") ? (CARRIER_HEIGHT - TOP_PEG_HOLE_Z_OFFSET) : CARRIER_HALF_HEIGHT;

    // Text positioning calculations
    owner_metrics = textmetrics(text=owner_name, font=fontface, size=font_size, halign="center", valign="center");
    type_metrics = textmetrics(text=selected_type_name, font=fontface, size=font_size, halign="center", valign="center");

    // Safe rectangular area boundaries for text placement
    safe_rect_center_x = -CARRIER_RECT_OFFSET;
    safe_rect_size_x = CARRIER_LENGTH;
    safe_rect_size_y = CARRIER_WIDTH;
    safe_min_x = safe_rect_center_x - safe_rect_size_x / 2;
    safe_max_x = safe_rect_center_x + safe_rect_size_x / 2;
    safe_min_y = -safe_rect_size_y / 2;
    safe_max_y = safe_rect_size_y / 2;

    // Text etching position calculations (Omega-D specific positioning)
    owner_etch_bottom_position = safe_max_y - OWNER_ETCH_BOTTOM_MARGIN;
    owner_etch_pos = [owner_etch_bottom_position, TEXT_ETCH_Y_TRANSLATE, TEXT_ETCH_Z_POSITION];
    owner_etch_rot = [0, 0, 270];

    type_etch_top_position = safe_min_y + TYPE_ETCH_TOP_MARGIN;
    type_etch_pos = [type_etch_top_position, TEXT_ETCH_Y_TRANSLATE, TEXT_ETCH_Z_POSITION];
    type_etch_rot = [0, 0, 270];

    // Multi-material text depth calculations
    TEXT_SOLID_HEIGHT = layer_height_mm * text_layer_multiple;
    TEXT_SUBTRACT_DEPTH = text_as_separate_parts ? TEXT_SOLID_HEIGHT : text_etch_depth;
    TEXT_SOLID_Z_POSITION = CARRIER_HALF_HEIGHT - TEXT_SOLID_HEIGHT;

    /**
     * Local Part module for compatibility
     */
    module Part(DoPart) {
        color(SharedPartColor(DoPart)) {
            if (which_part == "All" || DoPart == which_part) {
                children();
            }
        }
    }

    /**
     * Creates the basic Omega-D carrier shape
     * Combines circular and rectangular sections with rounded edges
     */
    module base_shape() {
        color("grey")
            union() {
                cylinder(h=CARRIER_HEIGHT, r=CARRIER_CIRCLE_DIAMETER / 2, center=true);
                translate([-CARRIER_RECT_OFFSET, 0, 0])
                    cuboid(
                        [CARRIER_LENGTH, CARRIER_WIDTH, CARRIER_HEIGHT],
                        anchor=CENTER,
                        rounding=CARRIER_FILLET,
                        edges=[
                            [0, 0, 0, 0],
                            [0, 0, 0, 0],
                            [1, 1, 1, 1],
                        ]
                    );
            }
    }

    /**
     * Creates registration holes for Omega-D enlarger alignment
     */
    module registration_holes() {
        translate([0, -1.5, 0]) {
            // Top registration hole
            union() {
                color("red")
                    translate([REG_HOLE_TOP_X_OFFSET + (REG_HOLE_DISTANCE / 2) + REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2, 0])
                        cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor=CENTER);
                color("red")
                    translate([REG_HOLE_TOP_X_OFFSET + (REG_HOLE_DISTANCE / 2) + REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2 + REG_HOLE_CYL_Y_OFFSET, 0])
                        cylinder(h=CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=REG_HOLE_DIAMETER / 2, center=true);
            }
            // Bottom registration hole
            union() {
                color("red")
                    translate([REG_HOLE_BOTTOM_X_OFFSET - (REG_HOLE_DISTANCE / 2) - REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2, 0])
                        cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor=CENTER);
                color("red")
                    translate([REG_HOLE_BOTTOM_X_OFFSET - (REG_HOLE_DISTANCE / 2) - REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2 + REG_HOLE_CYL_Y_OFFSET, 0])
                        cylinder(h=CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=REG_HOLE_DIAMETER / 2, center=true);
            }
        }
    }

    /**
     * Creates a separation hole for the top carrier
     */
    module separation_hole() {
        translate([-115, -70, 0]) {
            cylinder(h=CARRIER_HEIGHT + 1, r=10, center=true);
        }
    }

    // Arrow etching functionality now provided by carrier-features.scad
    // The arrow_etch module and related functions are centralized there

    /**
     * Generates alignment board footprint holes
     */
    module generate_alignment_footprint_holes(is_dent_holes = false) {
        if (!alignment_board) {
            if (alignment_board_type == "omega" || alignment_board_type == "lpl-saunders") {
                alignment_footprint_holes(
                    _screw_dia=ALIGNMENT_SCREW_DIAMETER,
                    _dist_for_x_coords=ALIGNMENT_SCREW_DISTANCE_Y,
                    _dist_for_y_coords=ALIGNMENT_SCREW_DISTANCE_X,
                    _carrier_h=CARRIER_HEIGHT,
                    _cut_ext=CUT_THROUGH_EXTENSION,
                    _is_dent=is_dent_holes,
                    _dent_depth=1
                );
            }
        }
    }

    /**
     * Generates text etch subtractions
     */
    module generate_text_etch_subtractions() {
        generate_shared_text_etch_subtractions(
            owner_name=owner_name,
            type_name=selected_type_name,
            enable_owner_etch=enable_owner_name_etch,
            enable_type_etch=enable_type_name_etch,
            owner_position=owner_etch_pos,
            type_position=type_etch_pos,
            owner_rotation=owner_etch_rot,
            type_rotation=type_etch_rot,
            font_face=fontface,
            font_size=font_size,
            etch_depth=TEXT_SUBTRACT_DEPTH
        );
    }

    /**
     * Generates multi-material text parts
     */
    module generate_multi_material_text_parts() {
        owner_text_solid_pos = [owner_etch_bottom_position, -95, TEXT_SOLID_Z_POSITION];
        type_text_solid_pos = [type_etch_top_position, -95, TEXT_SOLID_Z_POSITION];

        generate_shared_multi_material_text_parts(
            owner_name=owner_name,
            type_name=selected_type_name,
            enable_owner_etch=enable_owner_name_etch,
            enable_type_etch=enable_type_name_etch,
            owner_position=owner_text_solid_pos,
            type_position=type_text_solid_pos,
            owner_rotation=owner_etch_rot,
            type_rotation=type_etch_rot,
            font_face=fontface,
            font_size=font_size,
            text_height=TEXT_SOLID_HEIGHT,
            text_as_separate_parts=text_as_separate_parts,
            which_part=which_part
        );
    }

    /**
     * Generates the bottom carrier assembly
     */
    module bottom_carrier_assembly() {
        Part("Base")
            union() {
                carrier_base_processing(
                    _top_or_bottom=top_or_bottom,
                    _carrier_material_height=CARRIER_HEIGHT,
                    _opening_height_param=opening_height,
                    _opening_width_param=opening_width,
                    _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                    _opening_fillet_param=FRAME_FILLET,
                    _peg_style_param=printed_or_heat_set_pegs,
                    _peg_diameter_param=PEG_DIAMETER,
                    _peg_actual_height_param=PEG_HEIGHT,
                    _peg_pos_x_param=peg_pos_x,
                    _peg_pos_y_param=peg_pos_y,
                    _peg_z_offset_param=peg_z_offset_calc + 0.1
                ) {
                    difference() {
                        base_shape();
                        registration_holes();
                        generate_alignment_footprint_holes(is_dent_holes=false);
                        generate_text_etch_subtractions();
                        // Add directional arrow for appropriate formats using centralized module
                        generate_directional_arrow_etch(
                            film_format_str=film_format_for_arrows,
                            orientation_str="vertical", // Omega-D carriers are always vertical orientation
                            opening_width=opening_width,
                            opening_height=opening_height,
                            arrow_length=ARROW_LENGTH,
                            arrow_width=ARROW_WIDTH,
                            arrow_etch_depth=ARROW_ETCH_DEPTH,
                            arrow_offset=5
                        );
                    }
                }

                // Add alignment board if enabled
                if (alignment_board) {
                    _z_trans_val = (alignment_board_type == "omega") ? -1.4 : (alignment_board_type == "lpl-saunders") ? 0.15 : 0;
                    translate([0, 0, _z_trans_val])
                        instantiate_alignment_board_by_type(alignment_board_type);
                }
            }
    }

    // Main carrier generation logic
    if (top_or_bottom == "bottom") {
        // Apply rotation for printable orientation if enabled
        if (flip_bottom_for_printing) {
            rotate([180, 0, 0]) {
                bottom_carrier_assembly();
            }
        } else {
            bottom_carrier_assembly();
        }

        generate_multi_material_text_parts();
    } else if (top_or_bottom == "top") {
        Part("Base")
            carrier_base_processing(
                _top_or_bottom=top_or_bottom,
                _carrier_material_height=CARRIER_HEIGHT,
                _opening_height_param=opening_height,
                _opening_width_param=opening_width,
                _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                _opening_fillet_param=FRAME_FILLET,
                _peg_style_param=printed_or_heat_set_pegs,
                _peg_diameter_param=PEG_DIAMETER,
                _peg_actual_height_param=PEG_HEIGHT,
                _peg_pos_x_param=peg_pos_x,
                _peg_pos_y_param=peg_pos_y,
                _peg_z_offset_param=peg_z_offset_calc
            ) {
                difference() {
                    base_shape();
                    separation_hole();
                    registration_holes();
                    generate_alignment_footprint_holes(is_dent_holes=true);
                    generate_text_etch_subtractions();
                }
            }

        generate_multi_material_text_parts();
    }
}
