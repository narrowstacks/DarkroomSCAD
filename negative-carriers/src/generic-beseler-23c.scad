// Generic Beseler 23C Carrier Template
// This module provides parameterized Beseler 23C carrier generation
// Called from main carrier.scad with configuration parameters

include <BOSL2/std.scad>
include <common/film-sizes.scad>
include <common/carrier-features.scad>
include <common/beseler-23c-alignment-board.scad>
include <common/lpl-saunders-alignment-board.scad>
include <common/omega-d-alignment-board.scad>
include <common/text-etching.scad>

/**
 * Generic Beseler 23C carrier generation module
 * All dimensions and positioning are parameterized for flexibility
 *
 * @param config - Configuration array containing all carrier-specific parameters:
 *   [0] = carrier_diameter (default: 160)
 *   [1] = carrier_height (default: 2)
 *   [2] = peg_diameter (default: 5.6)
 *   [3] = peg_height (default: 4)
 *   [4] = top_peg_hole_z_offset (default: 1)
 *   [5] = handle_length (default: 50)
 *   [6] = handle_width (default: 42)
 *   [7] = film_opening_cut_through_extension (default: 1)
 *   [8] = film_opening_frame_fillet (default: 0.5)
 *   [9] = text_etch_y_translate_owner (default: -65)
 *   [10] = text_etch_y_translate_type (default: -65)
 *   [11] = owner_etch_bottom_margin (default: 5)
 *   [12] = type_etch_top_margin (default: 5)
 *   [13] = owner_etch_additional_offset (default: 20)
 *   [14] = type_etch_additional_offset (default: 20)
 *   [15] = safe_text_margin (default: 13)
 *   [16] = multi_material_text_y_offset_owner (default: -75)
 *   [17] = multi_material_text_y_offset_type (default: -75)
 *
 * @param film_format - Film format string
 * @param orientation - Film orientation string  
 * @param top_or_bottom - "top" or "bottom"
 * @param printed_or_heat_set_pegs - "printed" or "heat_set"
 * @param alignment_board - true/false
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
 * @param peg_gap - Peg gap adjustment
 * @param adjust_film_width - Film width adjustment
 * @param adjust_film_height - Film height adjustment
 */
module generic_beseler_23c_carrier(
    config,
    film_format,
    orientation,
    top_or_bottom,
    printed_or_heat_set_pegs,
    alignment_board,
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
    peg_gap,
    adjust_film_width,
    adjust_film_height
) {
    // Extract configuration parameters
    CARRIER_DIAMETER = config[0];
    CARRIER_HEIGHT = config[1];
    PEG_DIAMETER = config[2];
    PEG_HEIGHT = config[3];
    TOP_PEG_HOLE_Z_OFFSET = config[4];
    HANDLE_LENGTH = config[5];
    HANDLE_WIDTH = config[6];
    FILM_OPENING_CUT_THROUGH_EXTENSION = config[7];
    FILM_OPENING_FRAME_FILLET = config[8];
    TEXT_ETCH_Y_TRANSLATE_OWNER = config[9];
    TEXT_ETCH_Y_TRANSLATE_TYPE = config[10];
    OWNER_ETCH_BOTTOM_MARGIN = config[11];
    TYPE_ETCH_TOP_MARGIN = config[12];
    OWNER_ETCH_ADDITIONAL_OFFSET = config[13];
    TYPE_ETCH_ADDITIONAL_OFFSET = config[14];
    SAFE_TEXT_MARGIN = config[15];
    MULTI_MATERIAL_TEXT_Y_OFFSET_OWNER = config[16];
    MULTI_MATERIAL_TEXT_Y_OFFSET_TYPE = config[17];

    // Z-axis positioning calculations
    TEXT_ETCH_Z_POSITION = CARRIER_HEIGHT / 2 - (text_etch_depth + 0.1);
    CARRIER_HALF_HEIGHT = CARRIER_HEIGHT / 2;

    // Peg Z offset calculation
    peg_z_offset_calc = top_or_bottom == "bottom" ? CARRIER_HEIGHT / 2 : CARRIER_HEIGHT - TOP_PEG_HOLE_Z_OFFSET;

    if (alignment_board && printed_or_heat_set_pegs == "printed") {
        assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
    }

    // Get film dimensions by calling functions from film-sizes.scad
    FILM_FORMAT_HEIGHT = get_film_format_height(film_format);
    FILM_FORMAT_WIDTH = get_film_format_width(film_format);
    FILM_FORMAT_PEG_DISTANCE = get_film_format_peg_distance(film_format);

    // Determine actual opening dimensions based on orientation
    opening_width_actual = get_final_opening_width(film_format, orientation, adjust_film_width);
    opening_height_actual = get_final_opening_height(film_format, orientation, adjust_film_height);

    // Determine effective orientation
    effective_orientation = get_effective_orientation(film_format, orientation);

    // Check if the selected format is a "filed" medium format
    IS_FILED_MEDIUM_FORMAT = film_format == "35mm filed" || 
        film_format == "6x4.5 filed" || film_format == "6x6 filed" || 
        film_format == "6x7 filed" || film_format == "6x8 filed" || film_format == "6x9 filed";

    // Internal calculation for peg gap, adjusted for filed formats
    CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - peg_gap) - 1 : (1 - peg_gap);

    // Calculate peg positions using Omega-style rules
    _peg_radius = PEG_DIAMETER / 2;
    _film_width_actual_half = (get_film_format_width(film_format) + adjust_film_width) / 2;
    _film_peg_distance_actual_half = FILM_FORMAT_PEG_DISTANCE / 2;

    peg_pos_x_calc = calculate_omega_style_peg_coordinate(
        is_dominant_film_dimension=(effective_orientation == "vertical"), // X uses film width if vertical
        film_width_or_equiv_half=_film_width_actual_half,
        film_peg_distance_half=_film_peg_distance_actual_half,
        peg_radius=_peg_radius,
        omega_internal_gap_value=CALCULATED_INTERNAL_PEG_GAP
    );

    peg_pos_y_calc = calculate_omega_style_peg_coordinate(
        is_dominant_film_dimension=(effective_orientation == "horizontal"), // Y uses film width if horizontal
        film_width_or_equiv_half=_film_width_actual_half,
        film_peg_distance_half=_film_peg_distance_actual_half,
        peg_radius=_peg_radius,
        omega_internal_gap_value=CALCULATED_INTERNAL_PEG_GAP
    );

    // Text positioning and boundary calculations (using circular boundary)
    owner_metrics = textmetrics(text=owner_name, font=fontface, size=font_size, halign="center", valign="center");
    type_metrics = textmetrics(text=selected_type_name, font=fontface, size=font_size, halign="center", valign="center");

    // Safe circular area boundaries for text placement
    safe_circle_radius = CARRIER_DIAMETER / 2 - SAFE_TEXT_MARGIN; 
    safe_min_x = -safe_circle_radius;
    safe_max_x = safe_circle_radius;
    safe_min_y = -safe_circle_radius;
    safe_max_y = safe_circle_radius;

    // Multi-material text depth calculations  
    TEXT_SOLID_HEIGHT = layer_height_mm * text_layer_multiple;
    TEXT_SUBTRACT_DEPTH = text_as_separate_parts ? TEXT_SOLID_HEIGHT : text_etch_depth;
    TEXT_SOLID_Z_POSITION = CARRIER_HALF_HEIGHT - TEXT_SOLID_HEIGHT;

    // Text etching position calculations (Beseler specific positioning - similar to LPL but simpler)
    owner_etch_bottom_position = safe_max_y - OWNER_ETCH_BOTTOM_MARGIN - OWNER_ETCH_ADDITIONAL_OFFSET;
    owner_etch_pos = [owner_etch_bottom_position, TEXT_ETCH_Y_TRANSLATE_OWNER, TEXT_ETCH_Z_POSITION];
    owner_etch_rot = [0, 0, 90];

    type_etch_top_position = safe_min_y + TYPE_ETCH_TOP_MARGIN + TYPE_ETCH_ADDITIONAL_OFFSET;
    type_etch_pos = [type_etch_top_position, TEXT_ETCH_Y_TRANSLATE_TYPE, TEXT_ETCH_Z_POSITION];
    type_etch_rot = [0, 0, 90];

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
     * Creates the handle for the Beseler 23C carrier
     */
    module handle() {
        translate([0, CARRIER_DIAMETER / 2, 0]) 
            color("grey") 
                cuboid([HANDLE_WIDTH, HANDLE_LENGTH * 1.5, CARRIER_HEIGHT], anchor=CENTER, rounding=.5);
    }

    /**
     * Creates the basic Beseler 23C carrier shape
     */
    module base_shape() {
        color("grey") 
            union() {
                cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, center=true, rounding=.5);
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
        owner_text_solid_pos = [owner_etch_bottom_position, MULTI_MATERIAL_TEXT_Y_OFFSET_OWNER, TEXT_SOLID_Z_POSITION];
        type_text_solid_pos = [type_etch_top_position, MULTI_MATERIAL_TEXT_Y_OFFSET_TYPE, TEXT_SOLID_Z_POSITION];

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
                    _opening_height_param=opening_height_actual,
                    _opening_width_param=opening_width_actual,
                    _opening_cut_through_ext_param=FILM_OPENING_CUT_THROUGH_EXTENSION,
                    _opening_fillet_param=FILM_OPENING_FRAME_FILLET,
                    _peg_style_param=printed_or_heat_set_pegs,
                    _peg_diameter_param=PEG_DIAMETER,
                    _peg_actual_height_param=PEG_HEIGHT,
                    _peg_pos_x_param=peg_pos_x_calc,
                    _peg_pos_y_param=peg_pos_y_calc,
                    _peg_z_offset_param=peg_z_offset_calc
                ) {
                    difference() {
                        base_shape();
                        generate_text_etch_subtractions();
                    }
                }

                // Beseler-specific additions (handle, alignment board)
                handle();

                // Beseler's unique alignment board logic for the bottom piece
                if (alignment_board) {
                    difference() {
                        translate([0, 0, CARRIER_HEIGHT / 2]) beseler_23c_alignment_board();
                        translate([0, 0, -2]) base_shape();
                    }
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
                _opening_height_param=opening_height_actual,
                _opening_width_param=opening_width_actual,
                _opening_cut_through_ext_param=FILM_OPENING_CUT_THROUGH_EXTENSION,
                _opening_fillet_param=FILM_OPENING_FRAME_FILLET,
                _peg_style_param=printed_or_heat_set_pegs,
                _peg_diameter_param=PEG_DIAMETER,
                _peg_actual_height_param=PEG_HEIGHT,
                _peg_pos_x_param=peg_pos_x_calc,
                _peg_pos_y_param=peg_pos_y_calc,
                _peg_z_offset_param=peg_z_offset_calc
            ) {
                difference() {
                    base_shape();
                    generate_text_etch_subtractions();
                }
            }
        
        handle();
        generate_multi_material_text_parts();
    }
}