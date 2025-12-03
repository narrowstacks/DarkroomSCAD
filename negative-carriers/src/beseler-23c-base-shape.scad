// Beseler 23C Base Shape Generator
// Pure geometry generator for Beseler 23C enlarger carrier base shapes
// Handles only the physical shape and handle

include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * Beseler 23C base shape module
 * Generates the characteristic circular Beseler 23C carrier geometry with handle
 *
 * @param config - Configuration array containing Beseler 23C specific parameters:
 *   [0] = carrier_diameter (default: 160)
 *   [1] = carrier_height (default: 2)
 *   [5] = handle_length (default: 50)
 *   [6] = handle_width (default: 42)
 * @param top_or_bottom - "top" or "bottom" (currently no difference, but maintained for consistency)
 */
module beseler_23c_base_shape(config, top_or_bottom) {
    // Keep carrier height from config to remain consistent with universal assembly calculations
    CARRIER_HEIGHT = get_carrier_height("beseler-23c");

    // Base geometry constants (moved from carrier-configs)
    CARRIER_DIAMETER = 160;
    HANDLE_LENGTH = 50;
    HANDLE_WIDTH = 42;

    /**
     * Creates the handle for the Beseler 23C carrier
     */
    module handle() {
        rotate([0, 0, 90]) {
            translate([0, CARRIER_DIAMETER / 2, 0])
                color("grey")
                    cuboid([HANDLE_WIDTH, HANDLE_LENGTH * 1.5, CARRIER_HEIGHT], anchor=CENTER, rounding=.5);
        }
    }

    /**
     * Creates the basic Beseler 23C carrier shape
     */
    module base_geometry() {
        color("grey")
            union() {
                cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, center=true, rounding=.5);
            }
    }

    // Generate the complete Beseler 23C base shape with handle
    union() {
        base_geometry();
        handle();
    }
}
