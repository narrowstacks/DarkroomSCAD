// LPL Saunders Base Shape Generator
// Pure geometry generator for LPL Saunders 45xx enlarger carrier base shapes
// Handles only the physical shape, edge cuts, and handle

include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * LPL Saunders base shape module
 * Generates the characteristic circular LPL Saunders carrier geometry with edge cuts and handle.
 * All geometry constants are defined locally within this module.
 *
 * @param config - Configuration array (currently unused; reserved for future per-variant overrides)
 * @param top_or_bottom - "top" or "bottom" (affects handle Y position mirroring)
 */
module lpl_saunders_base_shape(config, top_or_bottom) {
    // Keep carrier height from config to remain consistent with universal assembly calculations
    CARRIER_HEIGHT = get_carrier_height("lpl-saunders-45xx");

    // Base geometry constants (moved from carrier-configs)
    CARRIER_DIAMETER = 215;
    HANDLE_WIDTH = 60;
    HANDLE_HEIGHT = 40;
    HANDLE_X_OFFSET = 10;
    EDGE_CUTS_WIDTH = 120;
    EDGE_CUTS_HEIGHT = 120;
    EDGE_CUTS_DISTANCE = 149.135;

    /**
     * Creates edge cuts for the LPL Saunders carrier
     * Cuts on all 4 sides to create the characteristic flat edges
     */
    module carrier_edge_cuts() {
        for (mult = [-1, 1]) {
            translate([0, mult * EDGE_CUTS_DISTANCE, 0])
                cuboid([EDGE_CUTS_WIDTH, EDGE_CUTS_HEIGHT, CARRIER_HEIGHT + 0.1], anchor=CENTER);
            translate([mult * EDGE_CUTS_DISTANCE, 0, 0])
                cuboid([EDGE_CUTS_HEIGHT, EDGE_CUTS_WIDTH, CARRIER_HEIGHT + 0.1], anchor=CENTER);
        }
    }

    // Large body geometry doesn't need high $fn - segments are already small at this scale.
    // $fn=72 on a 215mm circle gives ~9.4mm segments, well below visible thresholds.
    BODY_FN = 72;

    /**
     * Creates the basic LPL Saunders carrier shape
     */
    module base_geometry() {
        difference() {
            cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, anchor=CENTER, $fn=BODY_FN);
            carrier_edge_cuts();
        }
    }

    /**
     * Creates the handle for the LPL Saunders carrier
     * Handle Y position is mirrored between top and bottom carriers
     */
    module handle() {
        y_sign = (top_or_bottom == "top") ? 1 : -1;
        translate([-(CARRIER_DIAMETER / 2), y_sign * HANDLE_X_OFFSET, 0])
            cuboid(
                [HANDLE_WIDTH, HANDLE_HEIGHT, CARRIER_HEIGHT],
                anchor=CENTER, rounding=2,
                edges=[FWD + RIGHT, BACK + LEFT, FWD + LEFT, BACK + RIGHT]
            );
    }

    // Generate the complete LPL Saunders base shape with handle
    // render() caches geometry for faster subsequent previews
    render() union() {
        base_geometry();
        handle();
    }
}
