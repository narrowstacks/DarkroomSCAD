// Universal Carrier Assembly System
// Centralized module for all common carrier features and assembly logic
// This is the single source of truth for film openings, pegs, text etching,
// alignment boards, and directional arrows across all enlarger types

include <BOSL2/std.scad>
include <film-sizes.scad>
include <carrier-features.scad>
include <omega-d-alignment-board.scad>
include <lpl-saunders-alignment-board.scad>
include <beseler-23c-alignment-board.scad>
include <text-etching.scad>
// Need access to base shape modules
include <../omega-d-base-shape.scad>
include <../lpl-saunders-base-shape.scad>
include <../beseler-23c-base-shape.scad>
include <../test-frame-base-shape.scad>
// Need access to carrier configuration functions
include <../carrier-configs.scad>

/**
 * Universal carrier assembly system
 * Combines base shape with all common features in a consistent manner
 *
 * @param config - Configuration array from carrier configs
 * @param carrier_type - String identifier for carrier type
 * @param top_or_bottom - "top" or "bottom"
 * @param printed_or_heat_set_pegs - "printed" or "heat_set"
 * @param alignment_board - true/false
 * @param alignment_board_type - "omega", "lpl-saunders", "beseler-23c"
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
 * @param film_format_for_arrows - Film format string (for directional arrows)
 */
module universal_carrier_assembly(
    // Base shape generation
    base_shape_module,

    // Configuration parameters
    config,
    carrier_type,

    // Common parameters
    top_or_bottom,
    printed_or_heat_set_pegs,
    alignment_board,
    alignment_board_type,
    flip_bottom_for_printing,

    // Text etching parameters
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

    // Pre-calculated feature positioning
    opening_height,
    opening_width,
    peg_pos_x,
    peg_pos_y,
    film_format_for_arrows,

    // Text position customization (user offsets applied to defaults)
    owner_text_offset = [0, 0], // [dx, dy] in mm
    type_text_offset = [0, 0] // [dx, dy] in mm
) {
    // Universal constants that apply to all carrier types
    CUT_THROUGH_EXTENSION = 1;

    // Carrier height per type
    CARRIER_HEIGHT = get_carrier_height(carrier_type);

    // Extract peg parameters from config (positions vary by carrier type)
    PEG_DIAMETER = DEFAULT_PEG_DIAMETER;
    PEG_HEIGHT = DEFAULT_PEG_HEIGHT;

    // Extract film opening fillet from config (positions vary by carrier type)
    FILM_OPENING_FRAME_FILLET = get_film_opening_frame_fillet(carrier_type);

    // Alignment screw parameters (positions vary by carrier type)
    ALIGNMENT_SCREW_DIAMETER = get_alignment_screw_diameter(carrier_type);
    ALIGNMENT_SCREW_PATTERN_DIST_X = get_alignment_screw_pattern_dist_x(carrier_type);
    ALIGNMENT_SCREW_PATTERN_DIST_Y = get_alignment_screw_pattern_dist_y(carrier_type);

    // Z-axis positioning calculations
    TEXT_ETCH_Z_POSITION = CARRIER_HEIGHT / 2 - (text_etch_depth + 0.1);
    CARRIER_HALF_HEIGHT = CARRIER_HEIGHT / 2;

    // Peg Z positioning (varies by top/bottom and carrier type)
    TOP_PEG_HOLE_Z_OFFSET = get_top_peg_hole_z_offset(carrier_type);

    peg_z_offset_calc =
        (top_or_bottom == "top") ?
            (CARRIER_HEIGHT - TOP_PEG_HOLE_Z_OFFSET)
        : CARRIER_HALF_HEIGHT;

    // Multi-material text calculations
    TEXT_SOLID_HEIGHT = layer_height_mm * text_layer_multiple;
    TEXT_SUBTRACT_DEPTH = text_as_separate_parts ? TEXT_SOLID_HEIGHT : text_etch_depth;
    TEXT_SOLID_Z_POSITION = CARRIER_HALF_HEIGHT - TEXT_SOLID_HEIGHT;

    // Validation
    if (alignment_board && printed_or_heat_set_pegs == "printed") {
        assert(false, "CARRIER OPTIONS ERROR: Alignment board included, so we can't use printed pegs! Please use heat-set pegs or disable the alignment board.");
    }

    // Pre-calculate text positions ONCE for performance (avoids duplicate textmetrics calls)
    // Only calculate when text etching is enabled - textmetrics() is expensive
    _cached_text_positions = (enable_owner_name_etch || enable_type_name_etch)
        ? _calculate_text_positions_once()
        : [[0,0,0], [0,0,0], [0,0,0], [0,0,0]]; // Dummy values when text disabled

    function _calculate_text_positions_once() =
        let (
            // Get carrier-specific text positioning parameters
            owner_text_config = get_owner_text_settings(carrier_type),
            type_text_config = get_type_text_settings(carrier_type),

            // Calculate text boundaries and positions
            owner_metrics = textmetrics(text=owner_name, font=fontface, size=font_size, halign="center", valign="center"),
            type_metrics = textmetrics(text=selected_type_name, font=fontface, size=font_size, halign="center", valign="center"),

            // Position calculations (carrier-type specific)
            owner_position = calculate_text_position(carrier_type, "owner", owner_text_config, owner_metrics, TEXT_ETCH_Z_POSITION, opening_width),
            type_position = calculate_text_position(carrier_type, "type", type_text_config, type_metrics, TEXT_ETCH_Z_POSITION, opening_width),

            // Apply user offsets
            owner_position_adj = [owner_position[0] + owner_text_offset[0], owner_position[1] + owner_text_offset[1], owner_position[2]],
            type_position_adj = [type_position[0] + type_text_offset[0], type_position[1] + type_text_offset[1], type_position[2]],

            // Rotation calculations (carrier-type specific)
            owner_rotation = get_text_rotation(carrier_type, "owner"),
            type_rotation = get_text_rotation(carrier_type, "type")
        ) [owner_position_adj, type_position_adj, owner_rotation, type_rotation];

    /**
     * Universal Part module for multi-material compatibility
     */
    module Part(DoPart) {
        color(SharedPartColor(DoPart)) {
            if (which_part == "All" || DoPart == which_part) {
                children();
            }
        }
    }

    /**
     * Universal text etch generation
     * Uses pre-cached text positions for performance
     */
    module generate_universal_text_etches() {
        // Use cached positions (calculated once at module instantiation)
        owner_pos = _cached_text_positions[0];
        type_pos = _cached_text_positions[1];
        owner_rot = _cached_text_positions[2];
        type_rot = _cached_text_positions[3];

        generate_shared_text_etch_subtractions(
            owner_name=owner_name,
            type_name=selected_type_name,
            enable_owner_etch=enable_owner_name_etch,
            enable_type_etch=enable_type_name_etch,
            owner_position=owner_pos,
            type_position=type_pos,
            owner_rotation=owner_rot,
            type_rotation=type_rot,
            font_face=fontface,
            font_size=font_size,
            etch_depth=TEXT_SUBTRACT_DEPTH
        );
    }

    /**
     * Universal multi-material text generation
     * Uses pre-cached text positions for performance
     */
    module generate_universal_multi_material_text() {
        // Use cached positions (calculated once at module instantiation)
        owner_pos = _cached_text_positions[0];
        type_pos = _cached_text_positions[1];
        owner_rot = _cached_text_positions[2];
        type_rot = _cached_text_positions[3];

        // Adjust Z position for solid text parts
        owner_solid_pos = [owner_pos[0], owner_pos[1], TEXT_SOLID_Z_POSITION];
        type_solid_pos = [type_pos[0], type_pos[1], TEXT_SOLID_Z_POSITION];

        generate_shared_multi_material_text_parts(
            owner_name=owner_name,
            type_name=selected_type_name,
            enable_owner_etch=enable_owner_name_etch,
            enable_type_etch=enable_type_name_etch,
            owner_position=owner_solid_pos,
            type_position=type_solid_pos,
            owner_rotation=owner_rot,
            type_rotation=type_rot,
            font_face=fontface,
            font_size=font_size,
            text_height=TEXT_SOLID_HEIGHT,
            text_as_separate_parts=text_as_separate_parts,
            which_part=which_part
        );
    }

    /**
     * Universal alignment footprint holes
     */
    module generate_universal_alignment_footprint_holes(is_dent_holes = false) {
        if (!alignment_board) {
            if (alignment_board_type == "omega" || alignment_board_type == "lpl-saunders") {
                alignment_footprint_holes(
                    _screw_dia=ALIGNMENT_SCREW_DIAMETER,
                    _dist_for_x_coords=ALIGNMENT_SCREW_PATTERN_DIST_X,
                    _dist_for_y_coords=ALIGNMENT_SCREW_PATTERN_DIST_Y,
                    _carrier_h=CARRIER_HEIGHT,
                    _cut_ext=CUT_THROUGH_EXTENSION,
                    _is_dent=is_dent_holes,
                    _dent_depth=1
                );
            }
        }
    }

    /**
     * Universal alignment board instantiation
     */
    module generate_universal_alignment_board() {
        if (alignment_board) {
            // Z-translation varies by carrier and alignment board type
            z_trans_val = get_alignment_board_z_offset(carrier_type, alignment_board_type, CARRIER_HEIGHT);

            translate([0, 0, z_trans_val])
                instantiate_alignment_board_by_type(alignment_board_type);
        }
    }

    /**
     * Universal directional arrow generation
     */
    module generate_universal_directional_arrows() {
        // Use consistent vertical orientation for all carriers
        generate_directional_arrow_etch(
            film_format_str=film_format_for_arrows,
            orientation_str="vertical",
            opening_width=opening_width,
            opening_height=opening_height,
            arrow_length=ARROW_LENGTH,
            arrow_width=ARROW_WIDTH,
            arrow_etch_depth=ARROW_ETCH_DEPTH,
            arrow_offset=5
        );
    }

    /**
     * Universal base shape generation
     * Calls the appropriate base shape module based on carrier type
     */
    module generate_universal_base_shape() {
        if (carrier_type == "omega-d") {
            omega_d_base_shape(config, top_or_bottom);
        } else if (carrier_type == "lpl-saunders-45xx") {
            lpl_saunders_base_shape(config, top_or_bottom);
        } else if (carrier_type == "beseler-23c") {
            beseler_23c_base_shape(config, top_or_bottom);
        } else if (is_test_frame_type(carrier_type)) {
            test_frame_base_shape(config, top_or_bottom, opening_width, opening_height, peg_pos_x, peg_pos_y);
        } else {
            // Fallback - should not happen due to validation
            cube([10, 10, 2], center=true);
        }
    }

    /**
     * Universal bottom carrier assembly
     */
    module universal_bottom_carrier_assembly() {
        Part("Base")
            union() {
                // Process base shape with all common features
                carrier_base_processing(
                    _top_or_bottom=top_or_bottom,
                    _carrier_material_height=CARRIER_HEIGHT,
                    _opening_height_param=opening_height,
                    _opening_width_param=opening_width,
                    _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                    _opening_fillet_param=FILM_OPENING_FRAME_FILLET,
                    _peg_style_param=printed_or_heat_set_pegs,
                    _peg_diameter_param=PEG_DIAMETER,
                    _peg_actual_height_param=PEG_HEIGHT,
                    _peg_pos_x_param=peg_pos_x,
                    _peg_pos_y_param=peg_pos_y,
                    _peg_z_offset_param=peg_z_offset_calc
                ) {
                    difference() {
                        // Generate base shape using provided module
                        generate_universal_base_shape();

                        // Apply all universal subtractions
                        generate_universal_alignment_footprint_holes(is_dent_holes=false);
                        generate_universal_text_etches();
                        generate_universal_directional_arrows();
                    }
                }

                // Add alignment board if enabled
                generate_universal_alignment_board();
            }
    }

    /**
     * Universal top carrier assembly
     */
    module universal_top_carrier_assembly() {
        Part("Base")
            carrier_base_processing(
                _top_or_bottom=top_or_bottom,
                _carrier_material_height=CARRIER_HEIGHT,
                _opening_height_param=opening_height,
                _opening_width_param=opening_width,
                _opening_cut_through_ext_param=CUT_THROUGH_EXTENSION,
                _opening_fillet_param=FILM_OPENING_FRAME_FILLET,
                _peg_style_param=printed_or_heat_set_pegs,
                _peg_diameter_param=PEG_DIAMETER,
                _peg_actual_height_param=PEG_HEIGHT,
                _peg_pos_x_param=peg_pos_x,
                _peg_pos_y_param=peg_pos_y,
                _peg_z_offset_param=peg_z_offset_calc
            ) {
                difference() {
                    // Generate base shape using provided module
                    generate_universal_base_shape();

                    // Apply all universal subtractions
                    generate_universal_alignment_footprint_holes(is_dent_holes=true);
                    generate_universal_text_etches();
                    generate_universal_directional_arrows();
                }
            }
    }

    // Main assembly logic
    if (top_or_bottom == "bottom") {
        // Apply rotation for printable orientation if enabled
        if (flip_bottom_for_printing) {
            rotate([180, 0, 0]) {
                universal_bottom_carrier_assembly();
            }
        } else {
            universal_bottom_carrier_assembly();
        }

        // Generate multi-material text parts
        generate_universal_multi_material_text();
    } else if (top_or_bottom == "top") {
        universal_top_carrier_assembly();

        // Generate multi-material text parts
        generate_universal_multi_material_text();
    }
}

// ============================================================================
// HELPER FUNCTIONS FOR CARRIER-SPECIFIC CONFIGURATION
// ============================================================================

/**
 * Text settings are provided by carrier-configs via dedicated getters
 */
function get_owner_text_settings(carrier_type) = carrier_owner_text_settings(carrier_type);
function get_type_text_settings(carrier_type) = carrier_type_text_settings(carrier_type);

/**
 * Calculate text position based on carrier type and text configuration
 */
function calculate_text_position(carrier_type, text_type, text_config, text_metrics, z_position, opening_width) =
    // Special handling: Beseler 23C text should live on the handle by default
    (carrier_type == "beseler-23c") ?
        let (
            // Beseler 23C base shape constants (mirrors beseler-23c-base-shape.scad)
            // Using local constants avoids coupling to base-shape scopes
            BESELER_23C_DIAMETER = 160,
            BESELER_HANDLE_WIDTH = 42,

            // Handle center is located on the negative X side of the disc
            handle_center_x = -BESELER_23C_DIAMETER / 2,

            // Separate owner/type horizontally relative to handle center so
            // their default haligns (owner=right, type=left) keep text on the handle
            x_offset = (text_type == "owner") ? 5 : -35,

            // Stack the two lines vertically within the handle area
            y_offset = (text_type == "owner") ? (BESELER_HANDLE_WIDTH / 3) : ( -BESELER_HANDLE_WIDTH / 8)
        ) [handle_center_x + x_offset, y_offset, z_position]
    :
    // Default handling for other carriers: place text to the left/right of the opening
    let (
        // Extract settings
        y_translate = (len(text_config) > 0) ? text_config[0] : 0,
        safe_margin = (len(text_config) > 3) ? text_config[3] : 13,
        // Position to left/right of opening by a safe margin
        x_base = (text_type == "owner") ? -(opening_width / 2 + safe_margin) : (opening_width / 2 + safe_margin)
    ) [x_base, y_translate, z_position];

/**
 * Get text rotation based on carrier type
 */
function get_text_rotation(carrier_type, text_type) =
    (carrier_type == "omega-d") ? [0, 0, 270]
    : (carrier_type == "lpl-saunders-45xx") ? [0, 0, 270]
    : (carrier_type == "beseler-23c") ? [0, 0, 0] // Horizontal text on the handle
    : [0, 0, 0]; // Default fallback

/**
 * Get alignment board Z offset based on carrier and board type
 */
function get_alignment_board_z_offset(carrier_type, alignment_board_type, carrier_height) =
    (carrier_type == "omega-d") ?
        (
            (alignment_board_type == "omega") ? -1.4
            : (alignment_board_type == "lpl-saunders") ? 0.15
            : 0
        )
    : (carrier_type == "lpl-saunders-45xx") ?
        (
            (alignment_board_type == "omega") ? -1.4
            : (alignment_board_type == "lpl-saunders") ? -carrier_height
            : (alignment_board_type == "beseler-23c") ? -carrier_height
            : 0
        )
    : (carrier_type == "beseler-23c") ? carrier_height / 2
    : 0; // Default fallback
