// LPL Saunders Base Shape Generator
// Pure geometry generator for LPL Saunders 45xx enlarger carrier base shapes
// Handles only the physical shape, edge cuts, and handle

include <BOSL2/std.scad>

/**
 * LPL Saunders base shape module
 * Generates the characteristic circular LPL Saunders carrier geometry with edge cuts and handle
 *
 * @param config - Configuration array containing LPL Saunders specific parameters:
 *   [0] = carrier_diameter (default: 215)
 *   [1] = carrier_height (default: 2)
 *   [2] = handle_width (default: 60)
 *   [3] = handle_height (default: 40)
 *   [4] = handle_x_offset (default: 10)
 *   [5] = edge_cuts_width (default: 120)
 *   [6] = edge_cuts_height (default: 120)
 *   [7] = edge_cuts_distance (default: 149.135)
 * @param top_or_bottom - "top" or "bottom" (affects handle positioning)
 */
module lpl_saunders_base_shape(config, top_or_bottom) {
    // Extract configuration parameters
    CARRIER_DIAMETER = config[0];
    CARRIER_HEIGHT = config[1];
    HANDLE_WIDTH = config[2];
    HANDLE_HEIGHT = config[3];
    HANDLE_X_OFFSET = config[4];
    EDGE_CUTS_WIDTH = config[5];
    EDGE_CUTS_HEIGHT = config[6];
    EDGE_CUTS_DISTANCE = config[7];

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
    module base_geometry() {
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

    // Generate the complete LPL Saunders base shape with handle
    union() {
        base_geometry();
        handle();
    }
}

/**
 * Wrapper function that can be called as base_shape_module parameter
 */
module lpl_saunders_base_shape_wrapper() {
    // This will be called from universal carrier assembly with config in scope
    lpl_saunders_base_shape(config, top_or_bottom);
}
