// Generic Test Frame Carrier Template
// This module provides parameterized test frame generation for all carrier types
// Called from main carrier.scad with configuration parameters

include <BOSL2/std.scad>
include <common/film-sizes.scad>
include <common/carrier-features.scad>

/**
 * Generic test frame carrier generation module
 * Creates test pieces for validating film opening and peg fit
 * This is a simplified test frame that works for any film format
 *
 * @param config - Configuration array with simplified parameters: [carrier_height, peg_diameter, peg_height]
 * @param film_format - Film format string
 * @param orientation - Film orientation string  
 * @param top_or_bottom - "top" or "bottom" for the test piece
 * @param printed_or_heat_set_pegs - "printed" or "heat_set"
 * @param peg_gap - Peg gap adjustment
 * @param adjust_film_width - Film width adjustment
 * @param adjust_film_height - Film height adjustment
 * @param custom_film_height - Custom film stock height (for custom format)
 * @param custom_film_width - Custom film stock width (for custom format)
 * @param custom_opening_height - Custom opening height (for custom format)
 * @param custom_opening_width - Custom opening width (for custom format)
 */
module generic_test_frame_carrier(
    config,
    film_format,
    orientation,
    top_or_bottom,
    printed_or_heat_set_pegs,
    peg_gap,
    adjust_film_width,
    adjust_film_height,
    custom_film_height,
    custom_film_width,
    custom_opening_height,
    custom_opening_width
) {
    // Extract simplified configuration parameters
    CARRIER_HEIGHT = config[0];
    PEG_DIAMETER = config[1];
    PEG_HEIGHT = config[2];

    // Use standard values for test frames
    CUT_THROUGH_EXTENSION = 1; // Standard extension for all test frames
    FRAME_FILLET = 0.5; // Standard fillet for test frames

    // Get film dimensions using film-sizes.scad functions
    FILM_FORMAT_HEIGHT = get_film_format_height(film_format);
    FILM_FORMAT_WIDTH = get_film_format_width(film_format);
    FILM_FORMAT_PEG_DISTANCE = get_film_format_peg_distance(film_format);

    // Determine actual opening dimensions using carrier-features.scad functions
    opening_width_actual = get_final_opening_width(film_format, orientation, adjust_film_width);
    opening_height_actual = get_final_opening_height(film_format, orientation, adjust_film_height);

    // Determine effective orientation
    effective_orientation = get_effective_orientation(film_format, orientation);

    // Check if the selected format is a "filed" medium format
    IS_FILED_MEDIUM_FORMAT = film_format == "35mm filed" || film_format == "6x4.5 filed" || film_format == "6x6 filed" || film_format == "6x7 filed" || film_format == "6x8 filed" || film_format == "6x9 filed";

    // Internal calculation for peg gap, adjusted for filed formats
    CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - peg_gap) - 1 : (1 - peg_gap);

    // Calculate peg positions using standard Omega-style positioning (works for all carriers)
    _peg_radius = PEG_DIAMETER / 2;
    _film_width_actual_half = (FILM_FORMAT_WIDTH + adjust_film_width) / 2;
    _film_peg_distance_actual_half = FILM_FORMAT_PEG_DISTANCE / 2;

    peg_pos_x_calc = calculate_omega_style_peg_coordinate(
        is_dominant_film_dimension=(effective_orientation == "vertical"),
        film_width_or_equiv_half=_film_width_actual_half,
        film_peg_distance_half=_film_peg_distance_actual_half,
        peg_radius=_peg_radius,
        omega_internal_gap_value=CALCULATED_INTERNAL_PEG_GAP
    );

    peg_pos_y_calc = calculate_omega_style_peg_coordinate(
        is_dominant_film_dimension=(effective_orientation == "horizontal"),
        film_width_or_equiv_half=_film_width_actual_half,
        film_peg_distance_half=_film_peg_distance_actual_half,
        peg_radius=_peg_radius,
        omega_internal_gap_value=CALCULATED_INTERNAL_PEG_GAP
    );

    // Calculate test piece dimensions
    testPiecePadding = 10;
    testPieceWidth = 2 * peg_pos_y_calc + PEG_DIAMETER + testPiecePadding * 2;
    testPieceDepth = 2 * peg_pos_x_calc + PEG_DIAMETER + testPiecePadding * 2;
    test_peg_z_offset = CARRIER_HEIGHT / 2;

    // Generate the test frame
    generate_test_frame(
        _effective_test_piece_role=top_or_bottom,
        _frame_material_height=CARRIER_HEIGHT,
        _film_opening_h=opening_height_actual,
        _film_opening_w=opening_width_actual,
        _film_opening_cut_ext=CUT_THROUGH_EXTENSION,
        _film_opening_f=FRAME_FILLET,
        _peg_style=printed_or_heat_set_pegs,
        _peg_dia_val=PEG_DIAMETER,
        _peg_h_val=PEG_HEIGHT,
        _peg_x_val=peg_pos_x_calc,
        _peg_y_val=peg_pos_y_calc,
        _peg_z_val=test_peg_z_offset,
        _test_cuboid_width=testPieceWidth,
        _test_cuboid_depth=testPieceDepth
    );
}
