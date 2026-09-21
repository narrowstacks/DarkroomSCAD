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
    // The glass carrier's real config (plate size, pocket play, finger notch)
    // is built by carrier.scad from its customizer parameters via
    // omega_d_glass_config(); this entry only marks the type as known.
    : carrier_type == "omega-d-glass" ? []
    : carrier_type == "lpl-saunders-45xx" ? []
    : carrier_type == "beseler-23c" ? []
    : carrier_type == "beseler-45" ? []
    :
    // Generic test frame type - uses default config values
    carrier_type == "frameAndPegTest" ? get_test_frame_config()
    : undef; // Return undef for unknown carrier types

// ----------------------------------------------------------------------------
// Universal carrier constants (same for all carriers)
// Using constants instead of per-carrier functions reduces code duplication
// ----------------------------------------------------------------------------

UNIVERSAL_CARRIER_HEIGHT = 2;
UNIVERSAL_FILM_OPENING_FRAME_FILLET = 0.5;
UNIVERSAL_ALIGNMENT_SCREW_DIAMETER = 2;

// ----------------------------------------------------------------------------
// Alignment-board screw footprint: the four holes the carrier gets when the
// board is NOT fused, so it can be screwed onto the separately printed board.
// The screws have to land on the BOARD's material, so the pattern is a
// property of the board type (dist = full center-to-center spacing; holes at
// (±dist_x/2, ±dist_y/2)):
//   omega:        127mm square frame. (±41, ±56.5) sits on its rails, inside
//                 its own 4mm holes at (±42, ±57).
//   lpl-saunders: two chord rails of a 161.5mm disc at |x| = 60.5..75.4 (the
//                 121mm slot removes everything between them). x = ±68 is the
//                 rail centre; the rail spans |y| <= 43.5 there, so y = ±35
//                 leaves ~7mm to its (chamfered) edge.
//   beseler-23c:  5mm-wide ring at r = 55..60 (torus, see
//                 beseler-23c-alignment-board.scad). Holes on the ring's
//                 centre-line (r = 57.5) on the diagonals, which keeps them
//                 as far as possible from the film opening's corners in
//                 either orientation.
// ----------------------------------------------------------------------------
OMEGA_BOARD_SCREW_PATTERN_DIST_X = 82;
OMEGA_BOARD_SCREW_PATTERN_DIST_Y = 113;
LPL_SAUNDERS_BOARD_SCREW_PATTERN_DIST_X = 136;
LPL_SAUNDERS_BOARD_SCREW_PATTERN_DIST_Y = 70;
BESELER_23C_BOARD_SCREW_RADIUS = 57.5; // = TORUS_MAJOR_RADIUS of the 23C board
BESELER_23C_BOARD_SCREW_PATTERN_DIST = 2 * BESELER_23C_BOARD_SCREW_RADIUS * cos(45); // 81.32
// Kept for callers that still read the old names (the omega pattern).
UNIVERSAL_ALIGNMENT_SCREW_PATTERN_DIST_X = OMEGA_BOARD_SCREW_PATTERN_DIST_X;
UNIVERSAL_ALIGNMENT_SCREW_PATTERN_DIST_Y = OMEGA_BOARD_SCREW_PATTERN_DIST_Y;

// Board types that get a screw footprint on the carrier when not fused.
function alignment_board_has_screw_footprint(alignment_board_type) =
    alignment_board_type == "omega"
    || alignment_board_type == "lpl-saunders"
    || alignment_board_type == "beseler-23c";

// Getter functions maintained for backward compatibility (return universal values)
function get_carrier_height(carrier_type) =
    (carrier_type == "beseler-45") ? BESELER_45_THICKNESS
    : (carrier_type == "omega-d-glass") ? OMEGA_D_GLASS_THICKNESS
    : UNIVERSAL_CARRIER_HEIGHT;
function get_film_opening_frame_fillet(carrier_type) = UNIVERSAL_FILM_OPENING_FRAME_FILLET;
function get_alignment_screw_diameter(carrier_type) = UNIVERSAL_ALIGNMENT_SCREW_DIAMETER;
// The glass carrier has its own pattern (the omega one would land inside its
// 4x5 opening); every other carrier takes the pattern of the board it's
// screwed onto.
function get_alignment_screw_pattern_dist_x(carrier_type, alignment_board_type = "omega") =
    (carrier_type == "omega-d-glass") ? OMEGA_D_GLASS_SCREW_PATTERN_DIST_X
    : (alignment_board_type == "lpl-saunders") ? LPL_SAUNDERS_BOARD_SCREW_PATTERN_DIST_X
    : (alignment_board_type == "beseler-23c") ? BESELER_23C_BOARD_SCREW_PATTERN_DIST
    : OMEGA_BOARD_SCREW_PATTERN_DIST_X;
function get_alignment_screw_pattern_dist_y(carrier_type, alignment_board_type = "omega") =
    (carrier_type == "omega-d-glass") ? OMEGA_D_GLASS_SCREW_PATTERN_DIST_Y
    : (alignment_board_type == "lpl-saunders") ? LPL_SAUNDERS_BOARD_SCREW_PATTERN_DIST_Y
    : (alignment_board_type == "beseler-23c") ? BESELER_23C_BOARD_SCREW_PATTERN_DIST
    : OMEGA_BOARD_SCREW_PATTERN_DIST_Y;

// Z offset for top peg holes (varies by carrier style)
function get_top_peg_hole_z_offset(carrier_type) =
    (carrier_type == "omega-d") ? 2
    : (carrier_type == "beseler-23c") ? 1
    // 2.5mm-thick board: offset 2 (not the 23c's 1) so the top film-peg holes
    // punch fully through — a 1 would leave them blind at this thickness.
    : (carrier_type == "beseler-45") ? 2
    : 2;

// ----------------------------------------------------------------------------
// Text etching settings per carrier
// Returns [y_translate, carrier_edge_extent, edge_margin]
//   y_translate: pre-rotation Y position (becomes post-rotation X for rotated carriers)
//   carrier_edge_extent: carrier boundary distance from center at the text position
//   edge_margin: minimum gap between text and carrier edge (mm)
// Each text is positioned so its outermost edge is edge_margin from the carrier boundary,
// using textmetrics to measure actual text width. Independent of film opening size.
// ----------------------------------------------------------------------------

// Unified text settings lookup (owner and type use identical positioning)
// Values: [y_translate, carrier_edge_extent, edge_margin]
//   y_translate: pre-rotation Y position; for 270°-rotated carriers this becomes the
//                post-rotation X offset from center (negative = toward handle side)
//   carrier_edge_extent: distance from center to carrier boundary at text position (mm)
//   edge_margin: minimum gap between text edge and carrier boundary (mm)
function _get_text_settings(carrier_type) =
    (carrier_type == "omega-d" || carrier_type == "omega-d-glass") ? [-90, 69.5, 5] // rect section is 139mm wide, edge at ~69.5
    : (carrier_type == "lpl-saunders-45xx") ? [-65, 85, 5] // 215mm diameter, text near handle side
    : (carrier_type == "beseler-23c") ? [-65, 60, 5]   // 160mm diameter, text on handle
    : (carrier_type == "beseler-45") ? [0, 105, 5]     // 210mm diameter, text on left handle (unused: calculate_text_position has a dedicated beseler-45 arm)
    : [0, 60, 5];

// Owner and type text use the same positioning config
function carrier_owner_text_settings(carrier_type) = _get_text_settings(carrier_type);
function carrier_type_text_settings(carrier_type) = _get_text_settings(carrier_type);

// (All LPL base geometry lives in lpl-saunders-base-shape.scad)

// Omega-D glass plate carrier (single piece, base geometry in
// omega-d-glass-base-shape.scad). One slab as thick as a top+bottom pair.
OMEGA_D_GLASS_THICKNESS = 2 * UNIVERSAL_CARRIER_HEIGHT;
// Alignment-board screw footprint for the glass carrier. The universal 82x113
// pattern (±41, ±56.5) lands inside the 95x120 4x5 film opening — and inside
// the 4x5 board's own cutout — so this carrier uses its own pattern that sits
// on solid rail of both: x = ±56 is between the pocket wall (±51) and the
// board edge (63.5), clear of the 4x5 board cutout (|x| < 52.5); y = ±40 keeps
// clear of the finger notch at any corner and of the board's corner cuts.
OMEGA_D_GLASS_SCREW_PATTERN_DIST_X = 112;
OMEGA_D_GLASS_SCREW_PATTERN_DIST_Y = 80;
// Clearance hole in the separately printed board (screws thread into the carrier)
OMEGA_D_GLASS_BOARD_SCREW_CLEARANCE_DIA = 2.4;

// Beseler 23C handle constants shared between base-shape and text positioning
// (base geometry lives in beseler-23c-base-shape.scad)
BESELER_23C_DIAMETER = 160;
BESELER_23C_HANDLE_WIDTH = 42;

// Beseler 45 handle constants shared between base-shape and text positioning
// (base geometry lives in beseler-45-base-shape.scad)
BESELER_45_DIAMETER = 210;
BESELER_45_HANDLE_WIDTH = 29;
// The Beseler 45 carrier thickness is .5 mm thicker than other carriers
BESELER_45_THICKNESS = 2.5;

// Beseler 45 fixed corner alignment/stacking pegs (independent of film format).
// The bottom board carries the pegs, which protrude DOWN ONLY to seat into the
// enlarger. The top board's matching corner holes are stacking holes: they
// receive the down-pegs of another carrier stacked on top.
BESELER_45_ALIGN_PEG_SPACING = 119.7;      // center-to-center square (peg at ±59.85)
BESELER_45_ALIGN_PEG_DIAMETER = 4.6;       // peg diameter
BESELER_45_ALIGN_PEG_HOLE_DIAMETER = 6;    // top-board clearance-hole diameter
BESELER_45_ALIGN_PEG_DOWN = 2;             // protrusion below the bottom face (enlarger)
BESELER_45_ALIGN_PEG_UP = 0;               // no protrusion above the top face (down-only peg)

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
    : carrier_type == "omega-d-glass" ? "OMEGA-D GLASS"
    : carrier_type == "lpl-saunders-45xx" ? "LPL 45XX"
    : carrier_type == "beseler-23c" ? "BESELER 23C"
    : carrier_type == "beseler-45" ? "BESELER 45"
    : "UNKNOWN";

// ----------------------------------------------------------------------------
// Carrier feature support
// These carriers have full feature support (alignment boards, text, test frames)
// ----------------------------------------------------------------------------

// Helper to check if carrier has full feature support
function _is_full_feature_carrier(carrier_type) =
    carrier_type == "omega-d" || carrier_type == "lpl-saunders-45xx" || carrier_type == "beseler-23c";

/**
 * Check if a carrier type supports alignment boards
 */
function carrier_supports_alignment_board(carrier_type) = _is_full_feature_carrier(carrier_type);

/**
 * Check if a carrier type supports multi-material text printing
 */
function carrier_supports_multi_material_text(carrier_type) = _is_full_feature_carrier(carrier_type);

/**
 * Get default alignment board type for a carrier
 */
function get_default_alignment_board_type(carrier_type) =
    carrier_type == "omega-d" || carrier_type == "omega-d-glass" ? "omega"
    : carrier_type == "lpl-saunders-45xx" ? "lpl-saunders"
    : carrier_type == "beseler-23c" ? "beseler-23c"
    : "omega"; // Default fallback

/**
 * Validate that a carrier type is supported
 * @param carrier_type - String identifier for the carrier type
 * @return true if the carrier type is valid and supported
 */
function is_valid_carrier_type(carrier_type) =
    carrier_type == "omega-d" || carrier_type == "omega-d-glass" || carrier_type == "lpl-saunders-45xx" || carrier_type == "beseler-23c" || carrier_type == "beseler-45" ||
    // Generic test frame type
    carrier_type == "frameAndPegTest";

/**
 * Get list of all supported carrier types
 * @return Array of all supported carrier type strings
 */
function get_supported_carrier_types() =
    [
        "omega-d",
        "omega-d-glass",
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
 */
function carrier_supports_test_frames(carrier_type) = _is_full_feature_carrier(carrier_type);

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
