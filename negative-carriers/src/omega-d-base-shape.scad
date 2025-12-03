// Omega-D Base Shape Generator
// Pure geometry generator for Omega-D enlarger carrier base shapes
// Handles only the physical shape, registration holes, and separation holes

include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * Omega-D base shape module
 * Generates the characteristic Omega-D carrier geometry with registration holes
 *
 * @param config - Configuration array containing Omega-D specific parameters:
 *   [0] = carrier_length (default: 202)
 *   [1] = carrier_width (default: 139)
 *   [2] = carrier_height (default: 2)
 *   [3] = carrier_circle_diameter (default: 168)
 *   [4] = carrier_rect_offset (default: 13.5)
 *   [5] = carrier_fillet (default: 5)
 *   [9] = reg_hole_diameter (default: 6.2)
 *   [10] = reg_hole_distance (default: 130)
 *   [11] = reg_hole_x_length (default: 5)
 *   [12] = reg_hole_offset (default: 4.5)
 *   [13] = reg_hole_top_x_offset (default: 5)
 *   [14] = reg_hole_bottom_x_offset (default: -7)
 * @param top_or_bottom - "top" or "bottom" (affects separation hole inclusion)
 */
module omega_d_base_shape(config, top_or_bottom) {
    // Use internal constants for base geometry to avoid relying on global config indices
    // Keep carrier height from config to remain consistent with universal assembly calculations
    CARRIER_HEIGHT = get_carrier_height("omega-d");

    // Base geometry constants (moved from carrier-configs)
    CARRIER_LENGTH = 202;
    CARRIER_WIDTH = 139;
    CARRIER_CIRCLE_DIAMETER = 168;
    CARRIER_RECT_OFFSET = 13.5;
    CARRIER_FILLET = 5;

    // Registration hole geometry (moved from carrier-configs)
    REG_HOLE_DIAMETER = 6.2;
    REG_HOLE_DISTANCE = 130;
    REG_HOLE_X_LENGTH = 5;
    REG_HOLE_OFFSET = 4.5;
    REG_HOLE_TOP_X_OFFSET = 5;
    REG_HOLE_BOTTOM_X_OFFSET = -7;

    // Constants
    CUT_THROUGH_EXTENSION = 1;
    REG_HOLE_SLOT_LENGTH_EXTENSION = 0;
    REG_HOLE_CYL_Y_OFFSET = 3.1;

    /**
     * Creates the basic Omega-D carrier shape
     * Combines circular and rectangular sections with rounded edges
     */
    module base_geometry() {
        union() {
                cylinder(h=CARRIER_HEIGHT, r=CARRIER_CIRCLE_DIAMETER / 2, center=true);
                translate([-CARRIER_RECT_OFFSET, 0, 0])
                    cuboid(
                        [CARRIER_LENGTH, CARRIER_WIDTH, CARRIER_HEIGHT],
                        anchor=CENTER,
                        rounding=CARRIER_FILLET,
                        edges=[
                            [0, 0, 0, 0],
                            [0, 0, 0, 0],
                            [1, 1, 1, 1],
                        ]
                    );
            }
    }

    /**
     * Creates registration holes for Omega-D enlarger alignment
     */
    module registration_holes() {
        translate([0, -1.5, 0]) {
            // Top registration hole
            union() {
                translate([REG_HOLE_TOP_X_OFFSET + (REG_HOLE_DISTANCE / 2) + REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2, 0])
                    cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor=CENTER);
                translate([REG_HOLE_TOP_X_OFFSET + (REG_HOLE_DISTANCE / 2) + REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2 + REG_HOLE_CYL_Y_OFFSET, 0])
                    cylinder(h=CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=REG_HOLE_DIAMETER / 2, center=true);
            }
            // Bottom registration hole
            union() {
                translate([REG_HOLE_BOTTOM_X_OFFSET - (REG_HOLE_DISTANCE / 2) - REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2, 0])
                    cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor=CENTER);
                translate([REG_HOLE_BOTTOM_X_OFFSET - (REG_HOLE_DISTANCE / 2) - REG_HOLE_DIAMETER / 2, -REG_HOLE_DISTANCE / 2 + REG_HOLE_CYL_Y_OFFSET, 0])
                    cylinder(h=CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=REG_HOLE_DIAMETER / 2, center=true);
            }
        }
    }

    /**
     * Creates a separation hole for the top carrier
     */
    module separation_hole() {
        translate([-115, -70, 0]) {
            cylinder(h=CARRIER_HEIGHT + 1, r=10, center=true);
        }
    }

    // Generate the complete Omega-D base shape with all subtractions
    difference() {
        base_geometry();
        registration_holes();

        // Add separation hole only for top carriers
        if (top_or_bottom == "top") {
            separation_hole();
        }
    }
}
