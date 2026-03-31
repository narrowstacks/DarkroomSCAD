// Beseler 23C Base Shape Generator
// Pure geometry generator for Beseler 23C enlarger carrier base shapes
// Handles only the physical shape and handle

include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * Beseler 23C base shape module
 * Generates the characteristic circular Beseler 23C carrier geometry with handle.
 * Uses shared BESELER_23C_DIAMETER and BESELER_23C_HANDLE_WIDTH from carrier-configs.scad.
 *
 * @param config - Configuration array (currently unused; reserved for future per-variant overrides)
 * @param top_or_bottom - "top" or "bottom" (currently no difference, maintained for interface consistency)
 */
module beseler_23c_base_shape(config, top_or_bottom) {
    // Keep carrier height from config to remain consistent with universal assembly calculations
    CARRIER_HEIGHT = get_carrier_height("beseler-23c");

    // Use shared diameter and handle width from carrier-configs.scad
    CARRIER_DIAMETER = BESELER_23C_DIAMETER;
    HANDLE_LENGTH = 50;
    HANDLE_WIDTH = BESELER_23C_HANDLE_WIDTH;

    /**
     * Creates the handle for the Beseler 23C carrier
     */
    module handle() {
        rotate([0, 0, 90]) {
            translate([0, CARRIER_DIAMETER / 2, 0])
                cuboid([HANDLE_WIDTH, HANDLE_LENGTH * 1.5, CARRIER_HEIGHT], anchor=CENTER, rounding=.5);
        }
    }

    // Large body geometry doesn't need high $fn - segments are already small at this scale.
    // $fn=72 on a 160mm circle gives ~7mm segments, well below visible thresholds.
    BODY_FN = 72;

    /**
     * Creates the basic Beseler 23C carrier shape
     */
    module base_geometry() {
        cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, center=true, rounding=.5, $fn=BODY_FN);
    }

    // Generate the complete Beseler 23C base shape with handle
    // render() caches geometry for faster subsequent previews
    render() union() {
        base_geometry();
        handle();
    }
}
