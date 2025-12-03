// Test Frame Base Shape Generator
// Pure geometry generator for test frame base shapes
// Handles only the basic test frame geometry

include <BOSL2/std.scad>

/**
 * Test frame base shape module
 * Generates simple test frame geometry for fit validation
 *
 * @param config - Configuration array containing test frame parameters:
 *   [0] = base_width (default varies)
 *   [1] = peg_diameter (for calculating frame size)
 *   [2] = peg_height (default varies)
 * @param top_or_bottom - "top" or "bottom"
 * @param opening_width - Film opening width (for frame size calculation)
 * @param opening_height - Film opening height (for frame size calculation)
 * @param peg_pos_x - Peg X position (for frame size calculation)
 * @param peg_pos_y - Peg Y position (for frame size calculation)
 */
module test_frame_base_shape(config, top_or_bottom, opening_width, opening_height, peg_pos_x, peg_pos_y) {
    // Extract configuration parameters
    PEG_DIAMETER = config[1];

    // Calculate test frame dimensions
    testPiecePadding = 10;
    testPieceWidth = 2 * peg_pos_y + PEG_DIAMETER + testPiecePadding * 2;
    testPieceDepth = 2 * peg_pos_x + PEG_DIAMETER + testPiecePadding * 2;
    CARRIER_HEIGHT = 2; // Standard test frame height

    // Generate simple rectangular test frame
    color("grey")
        cuboid([testPieceDepth, testPieceWidth, CARRIER_HEIGHT], anchor=CENTER, rounding=1);
}
