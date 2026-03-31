// Omega-D Base Shape Generator
// Pure geometry generator for Omega-D enlarger carrier base shapes
// Handles only the physical shape, registration holes, and separation holes

include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * Omega-D base shape module
 * Generates the characteristic Omega-D carrier geometry with registration holes.
 * All geometry constants are defined locally within this module.
 *
 * @param config - Configuration array (currently unused; reserved for future per-variant overrides)
 * @param top_or_bottom - "top" or "bottom" (top includes a separation hole for prying apart)
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

    // Registration hole geometry
    REG_HOLE_DIAMETER = 6.2;
    REG_HOLE_DISTANCE = 130;
    REG_HOLE_TOP_X_OFFSET = 5;    // X offset for the top registration hole
    REG_HOLE_BOTTOM_X_OFFSET = -7; // X offset for the bottom registration hole

    // Slot extension for registration holes (0 = no slot, just a round hole with flat side)
    REG_HOLE_SLOT_LENGTH_EXTENSION = 0;
    // Y offset of the cylindrical end from the slot center
    REG_HOLE_CYL_Y_OFFSET = 3.1;

    /**
     * Creates the basic Omega-D carrier shape
     * Combines circular and rectangular sections with rounded edges
     */
    // Large body geometry doesn't need high $fn - segments are already small at this scale.
    // $fn=72 on a 168mm circle gives ~7.3mm segments, well below visible thresholds.
    BODY_FN = 72;

    module base_geometry() {
        union() {
                cylinder(h=CARRIER_HEIGHT, r=CARRIER_CIRCLE_DIAMETER / 2, center=true, $fn=BODY_FN);
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
     * Creates a single registration hole (slot + cylinder)
     * @param x_offset - X offset for this hole position
     * @param x_sign - Direction multiplier (+1 for top, -1 for bottom)
     */
    module reg_hole(x_offset, x_sign) {
        hole_x = x_offset + x_sign * (REG_HOLE_DISTANCE / 2 + REG_HOLE_DIAMETER / 2);
        hole_y = -REG_HOLE_DISTANCE / 2;
        cut_height = CARRIER_HEIGHT + 1;
        union() {
            translate([hole_x, hole_y, 0])
                cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, cut_height], anchor=CENTER);
            translate([hole_x, hole_y + REG_HOLE_CYL_Y_OFFSET, 0])
                cylinder(h=cut_height, r=REG_HOLE_DIAMETER / 2, center=true);
        }
    }

    /**
     * Creates registration holes for Omega-D enlarger alignment
     */
    module registration_holes() {
        translate([0, -1.5, 0]) {
            reg_hole(REG_HOLE_TOP_X_OFFSET, 1);
            reg_hole(REG_HOLE_BOTTOM_X_OFFSET, -1);
        }
    }

    // Separation hole position and size - located at the bottom-left corner
    // of the carrier for inserting a tool to pry top and bottom apart
    SEPARATION_HOLE_X = -115;
    SEPARATION_HOLE_Y = -70;
    SEPARATION_HOLE_RADIUS = 10;

    /**
     * Creates a separation hole for the top carrier
     * Allows inserting a tool to separate top and bottom carrier halves
     */
    module separation_hole() {
        translate([SEPARATION_HOLE_X, SEPARATION_HOLE_Y, 0])
            cylinder(h=CARRIER_HEIGHT + 1, r=SEPARATION_HOLE_RADIUS, center=true);
    }

    // Generate the complete Omega-D base shape with all subtractions
    // render() caches geometry for faster subsequent previews
    render() difference() {
        base_geometry();
        registration_holes();

        // Add separation hole only for top carriers
        if (top_or_bottom == "top") {
            separation_hole();
        }
    }
}
