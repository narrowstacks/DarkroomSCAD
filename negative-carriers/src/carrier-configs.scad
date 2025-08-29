// Carrier Configuration System
// Centralizes all carrier-specific parameters and settings
// This file defines configuration arrays for each supported enlarger type

/**
 * Get the configuration array for a specific carrier type
 * @param carrier_type - String identifier for the carrier type
 * @return Array of configuration parameters specific to that carrier
 */
function get_carrier_config(carrier_type) = 
    carrier_type == "omega-d" ? get_omega_d_config() :
    carrier_type == "lpl-saunders-45xx" ? get_lpl_saunders_config() :
    carrier_type == "beseler-23c" ? get_beseler_23c_config() :
    carrier_type == "beseler-45" ? get_beseler_45_config() :
    // Generic test frame type - uses default config values
    carrier_type == "frameAndPegTest" ? get_test_frame_config() :
    undef; // Return undef for unknown carrier types

/**
 * Omega-D Carrier Configuration
 * All dimensions and positioning parameters for Omega-D carriers
 * 
 * Array indices:
 * [0] = carrier_length, [1] = carrier_width, [2] = carrier_height, 
 * [3] = carrier_circle_diameter, [4] = carrier_rect_offset, [5] = carrier_fillet,
 * [6] = frame_fillet, [7] = peg_diameter, [8] = peg_height,
 * [9] = reg_hole_diameter, [10] = reg_hole_distance, [11] = reg_hole_x_length,
 * [12] = reg_hole_offset, [13] = reg_hole_top_x_offset, [14] = reg_hole_bottom_x_offset,
 * [15] = alignment_screw_diameter, [16] = alignment_screw_distance_x, [17] = alignment_screw_distance_y,
 * [18] = top_peg_hole_z_offset, [19] = text_etch_y_translate, [20] = owner_etch_bottom_margin,
 * [21] = type_etch_top_margin
 */
function get_omega_d_config() = [
    202,    // carrier_length
    139,    // carrier_width  
    2,      // carrier_height
    168,    // carrier_circle_diameter
    13.5,   // carrier_rect_offset
    5,      // carrier_fillet
    0.5,    // frame_fillet
    5.6,    // peg_diameter
    4,      // peg_height
    6.2,    // reg_hole_diameter
    130,    // reg_hole_distance
    5,      // reg_hole_x_length
    4.5,    // reg_hole_offset
    5,      // reg_hole_top_x_offset
    -7,     // reg_hole_bottom_x_offset
    2,      // alignment_screw_diameter
    113,    // alignment_screw_distance_x
    82,     // alignment_screw_distance_y
    2,      // top_peg_hole_z_offset
    -90,    // text_etch_y_translate
    5,      // owner_etch_bottom_margin
    5       // type_etch_top_margin
];

/**
 * LPL Saunders 45xx Carrier Configuration
 * All dimensions and positioning parameters for LPL Saunders carriers
 * 
 * Array indices:
 * [0] = carrier_diameter, [1] = carrier_height, [2] = handle_width,
 * [3] = handle_height, [4] = handle_x_offset, [5] = edge_cuts_width,
 * [6] = edge_cuts_height, [7] = edge_cuts_distance, [8] = peg_diameter,
 * [9] = peg_height, [10] = alignment_screw_diameter, [11] = alignment_screw_pattern_dist_x,
 * [12] = alignment_screw_pattern_dist_y, [13] = text_etch_y_translate_owner, [14] = text_etch_y_translate_type,
 * [15] = owner_etch_bottom_margin, [16] = type_etch_top_margin, [17] = owner_etch_additional_offset,
 * [18] = type_etch_additional_offset, [19] = safe_text_margin, [20] = film_opening_frame_fillet,
 * [21] = multi_material_text_y_offset_owner, [22] = multi_material_text_y_offset_type
 */
function get_lpl_saunders_config() = [
    215,      // carrier_diameter
    2,        // carrier_height
    60,       // handle_width
    40,       // handle_height
    10,       // handle_x_offset
    120,      // edge_cuts_width
    120,      // edge_cuts_height
    149.135,  // edge_cuts_distance
    10,       // peg_diameter
    4,        // peg_height
    2,        // alignment_screw_diameter
    82,       // alignment_screw_pattern_dist_x (corresponds to Omega D's Y)
    113,      // alignment_screw_pattern_dist_y (corresponds to Omega D's X)
    -65,      // text_etch_y_translate_owner
    -65,      // text_etch_y_translate_type
    5,        // owner_etch_bottom_margin
    5,        // type_etch_top_margin
    30,       // owner_etch_additional_offset (increased from 20 to move text closer to center)
    30,       // type_etch_additional_offset (increased from 20 to move text closer to center)
    20,       // safe_text_margin (increased from 13 to provide more margin)
    0.5,      // film_opening_frame_fillet
    -75,      // multi_material_text_y_offset_owner
    -75       // multi_material_text_y_offset_type
];

/**
 * Beseler 23C Carrier Configuration
 * All dimensions and positioning parameters for Beseler 23C carriers
 * 
 * Array indices:
 * [0] = carrier_diameter, [1] = carrier_height, [2] = peg_diameter,
 * [3] = peg_height, [4] = top_peg_hole_z_offset, [5] = handle_length,
 * [6] = handle_width, [7] = film_opening_cut_through_extension, [8] = film_opening_frame_fillet,
 * [9] = text_etch_y_translate_owner, [10] = text_etch_y_translate_type, [11] = owner_etch_bottom_margin,
 * [12] = type_etch_top_margin, [13] = owner_etch_additional_offset, [14] = type_etch_additional_offset,
 * [15] = safe_text_margin, [16] = multi_material_text_y_offset_owner, [17] = multi_material_text_y_offset_type
 */
function get_beseler_23c_config() = [
    160,    // carrier_diameter
    2,      // carrier_height
    5.6,    // peg_diameter
    4,      // peg_height
    1,      // top_peg_hole_z_offset
    50,     // handle_length
    42,     // handle_width
    1,      // film_opening_cut_through_extension
    0.5,    // film_opening_frame_fillet
    -65,    // text_etch_y_translate_owner
    -65,    // text_etch_y_translate_type
    5,      // owner_etch_bottom_margin
    5,      // type_etch_top_margin
    20,     // owner_etch_additional_offset
    20,     // type_etch_additional_offset
    13,     // safe_text_margin
    -75,    // multi_material_text_y_offset_owner
    -75     // multi_material_text_y_offset_type
];

/**
 * Beseler 45 Carrier Configuration (Future Implementation)
 * Placeholder for potential future Beseler 45 support
 */
function get_beseler_45_config() = [
    // TODO: Define Beseler 45 specific parameters when implementation is ready
    180,    // carrier_diameter (placeholder)
    2,      // carrier_height (placeholder)
    5.6,    // peg_diameter (placeholder)
    4,      // peg_height (placeholder)
    1,      // top_peg_hole_z_offset (placeholder)
    60,     // handle_length (placeholder)
    50,     // handle_width (placeholder)
    1,      // film_opening_cut_through_extension (placeholder)
    0.5,    // film_opening_frame_fillet (placeholder)
    -65,    // text_etch_y_translate_owner (placeholder)
    -65,    // text_etch_y_translate_type (placeholder)
    5,      // owner_etch_bottom_margin (placeholder)
    5,      // type_etch_top_margin (placeholder)
    20,     // owner_etch_additional_offset (placeholder)
    20,     // type_etch_additional_offset (placeholder)
    13,     // safe_text_margin (placeholder)
    -75,    // multi_material_text_y_offset_owner (placeholder)
    -75     // multi_material_text_y_offset_type (placeholder)
];

/**
 * Test Frame Configuration
 * Generic configuration for test frames - simplified for basic film opening and peg testing
 * Uses minimal parameters needed for the generate_test_frame function
 * 
 * Array indices:
 * [0] = carrier_height (default: 2)
 * [1] = peg_diameter (default: 5.6) 
 * [2] = peg_height (default: 4)
 */
function get_test_frame_config() = [
    2,      // carrier_height - standard thickness
    5.6,    // peg_diameter - standard size 
    4       // peg_height - standard height
];

/**
 * Get carrier type display name for text etching
 * @param carrier_type - String identifier for the carrier type
 * @return Human-readable name for display
 */
function get_carrier_type_display_name(carrier_type) = 
    carrier_type == "omega-d" ? "OMEGA-D" :
    carrier_type == "lpl-saunders-45xx" ? "LPL 45XX" :
    carrier_type == "beseler-23c" ? "BESELER 23C" :
    carrier_type == "beseler-45" ? "BESELER 45" :
    "UNKNOWN";

/**
 * Check if a carrier type supports alignment boards
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier supports alignment boards
 */
function carrier_supports_alignment_board(carrier_type) = 
    carrier_type == "omega-d" || 
    carrier_type == "lpl-saunders-45xx" || 
    carrier_type == "beseler-23c";

/**
 * Get default alignment board type for a carrier
 * @param carrier_type - String identifier for the carrier type
 * @return Default alignment board type string
 */
function get_default_alignment_board_type(carrier_type) = 
    carrier_type == "omega-d" ? "omega" :
    carrier_type == "lpl-saunders-45xx" ? "lpl-saunders" :
    carrier_type == "beseler-23c" ? "beseler-23c" :
    "omega"; // Default fallback

/**
 * Check if a carrier type supports multi-material text printing
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier supports multi-material text
 */
function carrier_supports_multi_material_text(carrier_type) = 
    carrier_type == "omega-d" || 
    carrier_type == "lpl-saunders-45xx" || 
    carrier_type == "beseler-23c";

/**
 * Validate that a carrier type is supported
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier type is valid and supported
 */
function is_valid_carrier_type(carrier_type) = 
    carrier_type == "omega-d" || 
    carrier_type == "lpl-saunders-45xx" || 
    carrier_type == "beseler-23c" ||
    carrier_type == "beseler-45" ||
    // Generic test frame type
    carrier_type == "frameAndPegTest";

/**
 * Get list of all supported carrier types
 * @return Array of all supported carrier type strings
 */
function get_supported_carrier_types() = [
    "omega-d", 
    "lpl-saunders-45xx", 
    "beseler-23c",
    "beseler-45",
    "frameAndPegTest"
];

/**
 * Get carrier-specific film format constraints
 * Some carriers may not support all film formats
 * @param carrier_type - String identifier for the carrier type
 * @return Array of supported film formats, or empty array for no restrictions
 */
function get_carrier_film_format_restrictions(carrier_type) = 
    // Currently no carrier-specific restrictions, but this function
    // provides a place to add them if needed in the future
    [];

/**
 * Check if a carrier type supports test frame generation
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier supports frameAndPegTest modes
 */
function carrier_supports_test_frames(carrier_type) = 
    carrier_type == "omega-d" || 
    carrier_type == "lpl-saunders-45xx" || 
    carrier_type == "beseler-23c";

/**
 * Check if a carrier type is a test frame type
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier type is a test frame variant
 */
function is_test_frame_type(carrier_type) = 
    carrier_type == "frameAndPegTest";

// Validation function - assert that required carrier config exists
module validate_carrier_config(carrier_type) {
    config = get_carrier_config(carrier_type);
    assert(config != undef, str("CONFIGURATION ERROR: Unknown carrier type '", carrier_type, "'. Supported types: ", get_supported_carrier_types()));
    assert(is_valid_carrier_type(carrier_type), str("CONFIGURATION ERROR: Carrier type '", carrier_type, "' is not currently supported."));
}