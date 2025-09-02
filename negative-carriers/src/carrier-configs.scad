// Carrier Configuration System
// Centralizes carrier-specific settings that are NOT base geometry.
// Base shape geometry lives in each carrier's base-shape file.

/**
 * Get the configuration array for a specific carrier type
 * @param carrier_type - String identifier for the carrier type
 * @return Array of configuration parameters specific to that carrier
 */
function get_carrier_config(carrier_type) =
    carrier_type == "omega-d" ? []
    : carrier_type == "lpl-saunders-45xx" ? []
    : carrier_type == "beseler-23c" ? []
    : carrier_type == "beseler-45" ? []
    :
    // Generic test frame type - uses default config values
    carrier_type == "frameAndPegTest" ? get_test_frame_config()
    : undef; // Return undef for unknown carrier types

// ----------------------------------------------------------------------------
// Carrier-independent getters for shared parameters
// ----------------------------------------------------------------------------

// Material thickness for each carrier type
function get_carrier_height(carrier_type) =
    (carrier_type == "omega-d") ? 2
    : (carrier_type == "lpl-saunders-45xx") ? 2
    : (carrier_type == "beseler-23c") ? 2
    : (carrier_type == "frameAndPegTest") ? 2
    : 2;

// Film opening frame fillet (applied to opening edges)
function get_film_opening_frame_fillet(carrier_type) =
    (carrier_type == "omega-d") ? 0.5
    : (carrier_type == "lpl-saunders-45xx") ? 0.5
    : (carrier_type == "beseler-23c") ? 0.5
    : 0.5;

// Alignment screw parameters
function get_alignment_screw_diameter(carrier_type) =
    (carrier_type == "omega-d") ? 2
    : (carrier_type == "lpl-saunders-45xx") ? 2
    : (carrier_type == "beseler-23c") ? 2
    : 2;

// Pattern distances are canonical X and Y spacing for the 4-hole footprint
function get_alignment_screw_pattern_dist_x(carrier_type) =
    (carrier_type == "omega-d") ? 82
    : (carrier_type == "lpl-saunders-45xx") ? 82
    : (carrier_type == "beseler-23c") ? 82
    : 82;

function get_alignment_screw_pattern_dist_y(carrier_type) =
    (carrier_type == "omega-d") ? 113
    : (carrier_type == "lpl-saunders-45xx") ? 113
    : (carrier_type == "beseler-23c") ? 113
    : 113;

// Z offset for top peg holes (varies by carrier style)
function get_top_peg_hole_z_offset(carrier_type) =
    (carrier_type == "omega-d") ? 2
    : (carrier_type == "beseler-23c") ? 1
    : 2;

// ----------------------------------------------------------------------------
// Text etching settings per carrier
// Returned arrays are intentionally small, only for text placement logic
// ----------------------------------------------------------------------------

// Owner text settings per carrier
// Returns [y_translate, bottom_margin, additional_offset?, safe_margin?, multi_material_y_offset?]
function carrier_owner_text_settings(carrier_type) =
    (carrier_type == "omega-d") ? [-90, 5] // simple: [y_translate, bottom_margin]
    : (carrier_type == "lpl-saunders-45xx") ? [-65, 5, 30, 20, -75]
    : (carrier_type == "beseler-23c") ? [-65, 5, 20, 13, -75]
    : [0, 5];

// Type text settings per carrier
// Returns [y_translate, top_margin, additional_offset?, safe_margin?, multi_material_y_offset?]
function carrier_type_text_settings(carrier_type) =
    (carrier_type == "omega-d") ? [-90, 5]
    : (carrier_type == "lpl-saunders-45xx") ? [-65, 5, 30, 20, -75]
    : (carrier_type == "beseler-23c") ? [-65, 5, 20, 13, -75]
    : [0, 5];

// (All LPL base geometry lives in lpl-saunders-base-shape.scad)

// (All Beseler 23C base geometry lives in beseler-23c-base-shape.scad)

// (Beseler 45 not yet implemented)

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
function get_test_frame_config() =
    [
        2, // carrier_height - standard thickness
        5.6, // peg_diameter - standard size 
        4, // peg_height - standard height
    ];

/**
 * Get carrier type display name for text etching
 * @param carrier_type - String identifier for the carrier type
 * @return Human-readable name for display
 */
function get_carrier_type_display_name(carrier_type) =
    carrier_type == "omega-d" ? "OMEGA-D"
    : carrier_type == "lpl-saunders-45xx" ? "LPL 45XX"
    : carrier_type == "beseler-23c" ? "BESELER 23C"
    : carrier_type == "beseler-45" ? "BESELER 45"
    : "UNKNOWN";

/**
 * Check if a carrier type supports alignment boards
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier supports alignment boards
 */
function carrier_supports_alignment_board(carrier_type) =
    carrier_type == "omega-d" || carrier_type == "lpl-saunders-45xx" || carrier_type == "beseler-23c";

/**
 * Get default alignment board type for a carrier
 * @param carrier_type - String identifier for the carrier type
 * @return Default alignment board type string
 */
function get_default_alignment_board_type(carrier_type) =
    carrier_type == "omega-d" ? "omega"
    : carrier_type == "lpl-saunders-45xx" ? "lpl-saunders"
    : carrier_type == "beseler-23c" ? "beseler-23c"
    : "omega"; // Default fallback

/**
 * Check if a carrier type supports multi-material text printing
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier supports multi-material text
 */
function carrier_supports_multi_material_text(carrier_type) =
    carrier_type == "omega-d" || carrier_type == "lpl-saunders-45xx" || carrier_type == "beseler-23c";

/**
 * Validate that a carrier type is supported
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier type is valid and supported
 */
function is_valid_carrier_type(carrier_type) =
    carrier_type == "omega-d" || carrier_type == "lpl-saunders-45xx" || carrier_type == "beseler-23c" || carrier_type == "beseler-45" ||
    // Generic test frame type
    carrier_type == "frameAndPegTest";

/**
 * Get list of all supported carrier types
 * @return Array of all supported carrier type strings
 */
function get_supported_carrier_types() =
    [
        "omega-d",
        "lpl-saunders-45xx",
        "beseler-23c",
        "beseler-45",
        "frameAndPegTest",
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
    carrier_type == "omega-d" || carrier_type == "lpl-saunders-45xx" || carrier_type == "beseler-23c";

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
