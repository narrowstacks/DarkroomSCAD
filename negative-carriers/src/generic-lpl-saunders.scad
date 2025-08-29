// Generic LPL Saunders 45xx Carrier Template
// This module provides parameterized LPL Saunders carrier generation
// Called from main carrier.scad with configuration parameters

include <BOSL2/std.scad>
include <common/film-sizes.scad>
include <common/carrier-features.scad>
include <common/omega-d-alignment-board.scad>
include <common/lpl-saunders-alignment-board.scad>
include <common/beseler-23c-alignment-board.scad>
include <common/text-etching.scad>

/**
 * Generic LPL Saunders carrier generation module
 * All dimensions and positioning are parameterized for flexibility
 *
 * @param config - Configuration array containing all carrier-specific parameters:
 *   [0] = carrier_diameter (default: 215)
 *   [1] = carrier_height (default: 2)
 *   [2] = handle_width (default: 60)
 *   [3] = handle_height (default: 40)
 *   [4] = handle_x_offset (default: 10)
 *   [5] = edge_cuts_width (default: 120)
 *   [6] = edge_cuts_height (default: 120)
 *   [7] = edge_cuts_distance (default: 149.135)
 *   [8] = peg_diameter (default: 10)
 *   [9] = peg_height (default: 4)
 *   [10] = alignment_screw_diameter (default: 2)
 *   [11] = alignment_screw_pattern_dist_x (default: 82)
 *   [12] = alignment_screw_pattern_dist_y (default: 113)
 *   [13] = text_etch_y_translate_owner (default: -65)
 *   [14] = text_etch_y_translate_type (default: -65)
 *   [15] = owner_etch_bottom_margin (default: 5)
 *   [16] = type_etch_top_margin (default: 5)
 *   [17] = owner_etch_additional_offset (default: 20)
 *   [18] = type_etch_additional_offset (default: 20)
 *   [19] = safe_text_margin (default: 13)
 *   [20] = film_opening_frame_fillet (default: 0.5)
 *   [21] = multi_material_text_y_offset_owner (default: -75)
 *   [22] = multi_material_text_y_offset_type (default: -75)
 *
 * @param film_format - Film format string
 * @param orientation - Film orientation string  
 * @param top_or_bottom - "top" or "bottom"
 * @param printed_or_heat_set_pegs - "printed" or "heat_set"
 * @param alignment_board - true/false
 * @param alignment_board_type - "omega", "lpl-saunders", "beseler-23c", etc.
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
 * @param custom_film_format_opening_height - Custom format opening height
 * @param custom_film_format_opening_width - Custom format opening width
 */
module generic_lpl_saunders_carrier(
    config,
    film_format,
    orientation,
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
    peg_gap,
    adjust_film_width,
    adjust_film_height,
    custom_film_format_opening_height,
    custom_film_format_opening_width
) {
    // Extract configuration parameters
    CARRIER_DIAMETER = config[0];
    CARRIER_HEIGHT = config[1];
    HANDLE_WIDTH = config[2];
    HANDLE_HEIGHT = config[3];
    HANDLE_X_OFFSET = config[4];
    EDGE_CUTS_WIDTH = config[5];
    EDGE_CUTS_HEIGHT = config[6];
    EDGE_CUTS_DISTANCE = config[7];
    PEG_DIAMETER = config[8];
    PEG_HEIGHT = config[9];
    ALIGNMENT_SCREW_DIAMETER = config[10];
    ALIGNMENT_SCREW_PATTERN_DIST_X = config[11];
    ALIGNMENT_SCREW_PATTERN_DIST_Y = config[12];
    TEXT_ETCH_Y_TRANSLATE_OWNER = config[13];
    TEXT_ETCH_Y_TRANSLATE_TYPE = config[14];
    OWNER_ETCH_BOTTOM_MARGIN = config[15];
    TYPE_ETCH_TOP_MARGIN = config[16];
    OWNER_ETCH_ADDITIONAL_OFFSET = config[17];
    TYPE_ETCH_ADDITIONAL_OFFSET = config[18];
    SAFE_TEXT_MARGIN = config[19];
    FILM_OPENING_FRAME_FILLET = config[20];
    MULTI_MATERIAL_TEXT_Y_OFFSET_OWNER = config[21];
    MULTI_MATERIAL_TEXT_Y_OFFSET_TYPE = config[22];

    // General modeling constants
    CUT_THROUGH_EXTENSION = 1;

    // Direction arrow dimensions for 6x6 format
    ARROW_LENGTH = 8;
    ARROW_WIDTH = 5;
    ARROW_ETCH_DEPTH = 0.5;

    // Z-axis positioning calculations
    TEXT_ETCH_Z_POSITION = CARRIER_HEIGHT / 2 - (text_etch_depth + 0.1);
    CARRIER_HALF_HEIGHT = CARRIER_HEIGHT / 2;

    if (alignment_board && printed_or_heat_set_pegs == "printed") {
        assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
    }

    // Film format type detection
    IS_FILED_MEDIUM_FORMAT = film_format == "6x4.5 filed" || film_format == "6x6 filed" || film_format == "6x7 filed" || film_format == "6x8 filed" || film_format == "6x9 filed";

    // Get film dimensions by calling functions from film-sizes.scad
    FILM_FORMAT_HEIGHT_RAW = (film_format == "custom") ? custom_film_format_opening_height : get_film_format_height(film_format);
    FILM_FORMAT_WIDTH_RAW = (film_format == "custom") ? custom_film_format_opening_width : get_film_format_width(film_format);

    // Assert that the functions returned valid values (not undef)
    assert(FILM_FORMAT_HEIGHT_RAW != undef, str("Unknown or unsupported film_format selected for HEIGHT: ", film_format));
    assert(FILM_FORMAT_WIDTH_RAW != undef, str("Unknown or unsupported film_format selected for WIDTH: ", film_format));

    effective_orientation = get_effective_orientation(film_format, orientation);

    // Adjusted film opening dimensions (incorporating user adjustments)
    adjusted_opening_height = get_final_opening_height(film_format, orientation, adjust_film_height);
    adjusted_opening_width = get_final_opening_width(film_format, orientation, adjust_film_width);

    // Text positioning and boundary calculations
    owner_metrics = textmetrics(text=owner_name, font=fontface, size=font_size, halign="center", valign="center");
    type_metrics = textmetrics(text=selected_type_name, font=fontface, size=font_size, halign="center", valign="center");

    // Safe circular area boundaries for text placement (LPL uses circular carrier)
    safe_circle_radius = CARRIER_DIAMETER / 2 - SAFE_TEXT_MARGIN; 
    safe_min_x = -safe_circle_radius;
    safe_max_x = safe_circle_radius;
    safe_min_y = -safe_circle_radius;
    safe_max_y = safe_circle_radius;

    // Owner name text boundaries (rotated 90 degrees for LPL)
    owner_rotated_size_x = owner_metrics.size[1];
    owner_rotated_size_y = owner_metrics.size[0];
    owner_center_x = -60;  // Move closer to center to fit within safe area
    owner_center_y = -35;
    owner_min_x = owner_center_x - owner_rotated_size_x / 2;
    owner_max_x = owner_center_x + owner_rotated_size_x / 2;
    owner_min_y = owner_center_y - owner_rotated_size_y / 2;
    owner_max_y = owner_center_y + owner_rotated_size_y / 2;

    // Type name text boundaries (rotated 90 degrees for LPL)
    type_rotated_size_x = type_metrics.size[1];
    type_rotated_size_y = type_metrics.size[0];
    type_center_x = -60;  // Move closer to center to fit within safe area
    type_center_y = 40;
    type_min_x = type_center_x - type_rotated_size_x / 2;
    type_max_x = type_center_x + type_rotated_size_x / 2;
    type_min_y = type_center_y - type_rotated_size_y / 2;
    type_max_y = type_center_y + type_rotated_size_y / 2;

    // Validate text fits within safe area boundaries using shared validation
    validate_text_bounds(
        text_string=owner_name,
        font_face=fontface,
        font_size=font_size,
        center_x=owner_center_x,
        center_y=owner_center_y,
        rotation_angle=90,
        safe_min_x=safe_min_x,
        safe_max_x=safe_max_x,
        safe_min_y=safe_min_y,
        safe_max_y=safe_max_y,
        text_label="Owner Name"
    );

    validate_text_bounds(
        text_string=selected_type_name,
        font_face=fontface,
        font_size=font_size,
        center_x=type_center_x,
        center_y=type_center_y,
        rotation_angle=90,
        safe_min_x=safe_min_x,
        safe_max_x=safe_max_x,
        safe_min_y=safe_min_y,
        safe_max_y=safe_max_y,
        text_label="Type Name"
    );

    // Multi-material text depth calculations
    TEXT_SOLID_HEIGHT = layer_height_mm * text_layer_multiple;
    TEXT_SUBTRACT_DEPTH = text_as_separate_parts ? TEXT_SOLID_HEIGHT : text_etch_depth;
    TEXT_SOLID_Z_POSITION = CARRIER_HALF_HEIGHT - TEXT_SOLID_HEIGHT;

    // Text etching position calculations (LPL specific positioning)
    owner_etch_bottom_position = safe_max_y - OWNER_ETCH_BOTTOM_MARGIN - OWNER_ETCH_ADDITIONAL_OFFSET;
    owner_etch_pos = [owner_etch_bottom_position, TEXT_ETCH_Y_TRANSLATE_OWNER, TEXT_ETCH_Z_POSITION];
    owner_etch_rot = [0, 0, 90];

    type_etch_top_position = safe_min_y + TYPE_ETCH_TOP_MARGIN + TYPE_ETCH_ADDITIONAL_OFFSET;
    type_etch_pos = [type_etch_top_position, TEXT_ETCH_Y_TRANSLATE_TYPE, TEXT_ETCH_Z_POSITION];
    type_etch_rot = [0, 0, 90];

    // Peg positioning calculations
    peg_z_offset_calc = (top_or_bottom == "top") ? (CARRIER_HEIGHT - 0) : CARRIER_HALF_HEIGHT;

    // Calculate peg positions for LPL style
    peg_pos_x_final = effective_orientation == "vertical" ?
        (FILM_FORMAT_WIDTH_RAW / 2 + PEG_DIAMETER / 2 + peg_gap) :
        (FILM_FORMAT_HEIGHT_RAW / 2 + PEG_DIAMETER / 2 + peg_gap);

    peg_pos_y_final = effective_orientation == "vertical" ?
        (FILM_FORMAT_HEIGHT_RAW / 2 + PEG_DIAMETER / 2 + peg_gap) :
        (FILM_FORMAT_WIDTH_RAW / 2 + PEG_DIAMETER / 2 + peg_gap);

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
     * Creates edge cuts for the LPL Saunders carrier
     */
    module carrier_edge_cuts() {
        translate([0, EDGE_CUTS_DISTANCE, 0])
            cuboid([EDGE_CUTS_WIDTH, EDGE_CUTS_HEIGHT, CARRIER_HEIGHT + 0.1], anchor=CENTER);
        translate([0, -EDGE_CUTS_DISTANCE, 0])
            cuboid([EDGE_CUTS_WIDTH, EDGE_CUTS_HEIGHT, CARRIER_HEIGHT + 0.1], anchor=CENTER);
        translate([EDGE_CUTS_DISTANCE, 0, 0])
            cuboid([EDGE_CUTS_HEIGHT, EDGE_CUTS_WIDTH, CARRIER_HEIGHT + 0.1], anchor=CENTER);
        translate([-EDGE_CUTS_DISTANCE, 0, 0])
            cuboid([EDGE_CUTS_HEIGHT, EDGE_CUTS_WIDTH, CARRIER_HEIGHT + 0.1], anchor=CENTER);
    }

    /**
     * Creates the basic LPL Saunders carrier shape
     */
    module base_shape() {
        difference() {
            cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, anchor=CENTER);
            carrier_edge_cuts();
        }
    }

    /**
     * Creates the handle for the LPL Saunders carrier
     */
    module handle() {
        if (top_or_bottom == "top") {
            translate([CARRIER_DIAMETER / 2, HANDLE_X_OFFSET, 0])
                cuboid(
                    [HANDLE_WIDTH, HANDLE_HEIGHT, CARRIER_HEIGHT],
                    anchor=CENTER, rounding=2,
                    edges=[FWD + RIGHT, BACK + LEFT, FWD + LEFT, BACK + RIGHT]
                );
        } else {
            translate([CARRIER_DIAMETER / 2, -HANDLE_X_OFFSET, 0])
                cuboid(
                    [HANDLE_WIDTH, HANDLE_HEIGHT, CARRIER_HEIGHT],
                    anchor=CENTER, rounding=2,
                    edges=[FWD + RIGHT, BACK + LEFT, FWD + LEFT, BACK + RIGHT]
                );
        }
    }

    /**
     * Creates a left-pointing arrow shape for directional etching
     */
    module arrow_etch(etch_depth = 0.5, length = 5, width = 3) {
        translate([-10, 0, .5])
            linear_extrude(height=etch_depth + 0.1)
                polygon(points=[[-length / 2, 0], [length / 2, width / 2], [length / 2, -width / 2]]);
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
     * Generates the bottom carrier assembly
     */
    module bottom_carrier_assembly() {
        Part("Base") 
            union() {
                carrier_base_processing(
                    _top_or_bottom=top_or_bottom,
                    _carrier_material_height=CARRIER_HEIGHT,
                    _opening_height_param=adjusted_opening_height,
                    _opening_width_param=adjusted_opening_width,
                    _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                    _opening_fillet_param=FILM_OPENING_FRAME_FILLET,
                    _peg_style_param=printed_or_heat_set_pegs,
                    _peg_diameter_param=PEG_DIAMETER,
                    _peg_actual_height_param=PEG_HEIGHT,
                    _peg_pos_x_param=peg_pos_x_final,
                    _peg_pos_y_param=peg_pos_y_final,
                    _peg_z_offset_param=peg_z_offset_calc - 0.1
                ) {
                    difference() {
                        base_shape();
                        if (!alignment_board) {
                            // If Alignment_Board is OFF, and type implies screws, punch the alignment footprint holes
                            if (alignment_board_type == "omega" || alignment_board_type == "lpl-saunders") {
                                alignment_footprint_holes(
                                    _screw_dia=ALIGNMENT_SCREW_DIAMETER,
                                    _dist_for_x_coords=ALIGNMENT_SCREW_PATTERN_DIST_X,
                                    _dist_for_y_coords=ALIGNMENT_SCREW_PATTERN_DIST_Y,
                                    _carrier_h=CARRIER_HEIGHT,
                                    _cut_ext=CUT_THROUGH_EXTENSION,
                                    _is_dent=false, // Bottom piece gets through-holes
                                    _dent_depth=1
                                );
                            }
                        }
                        generate_text_etch_subtractions();
                        // Add directional arrow for 6x6 formats
                        if (film_format == "6x6" || film_format == "6x6 filed") {
                            arrowOffset = 5;
                            if (orientation == "vertical") {
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
                if (alignment_board) {
                    _z_trans_val =
                        (alignment_board_type == "omega") ? -1.4
                        : (alignment_board_type == "lpl-saunders") ? -CARRIER_HEIGHT
                        : (alignment_board_type == "beseler-23c") ? -CARRIER_HEIGHT
                        : 0;
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
                _opening_height_param=adjusted_opening_height,
                _opening_width_param=adjusted_opening_width,
                _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                _opening_fillet_param=FILM_OPENING_FRAME_FILLET,
                _peg_style_param=printed_or_heat_set_pegs,
                _peg_diameter_param=PEG_DIAMETER,
                _peg_actual_height_param=PEG_HEIGHT,
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
    }
}