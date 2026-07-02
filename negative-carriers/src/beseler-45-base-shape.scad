// Beseler 45 Base Shape Generator
// Pure geometry generator for Beseler 45 enlarger carrier base shapes
// Handles only the physical shape and handle

// BOSL2 is included once at the entry point (carrier.scad) — OpenSCAD re-parses
// every include with no dedup, so re-including the ~80k-line library here would
// add seconds per render. Uncomment to render/preview this file by itself:
// include <BOSL2/std.scad>
include <carrier-configs.scad>

/**
 * Beseler 45 base shape module
 * Generates the round Beseler 45 carrier body with a handle at the top (+Y).
 * The handle sits opposite the (conceptual) hinge edge so the 4x5 landscape
 * opening's long edges land on the top/bottom. Uses shared BESELER_45_DIAMETER
 * and BESELER_45_HANDLE_WIDTH from carrier-configs.scad.
 *
 * @param config - Configuration array (currently unused; reserved for future overrides)
 * @param top_or_bottom - "top" or "bottom" (no geometric difference; kept for interface consistency)
 */
module beseler_45_base_shape(config, top_or_bottom) {
    CARRIER_HEIGHT = get_carrier_height("beseler-45");

    CARRIER_DIAMETER = BESELER_45_DIAMETER;   // 210
    HANDLE_WIDTH = BESELER_45_HANDLE_WIDTH;   // 29
    HANDLE_LENGTH = 50.5;                     // protruding length beyond the disc edge

    // Handle at the top (+Y). The cuboid is 2*HANDLE_LENGTH long and centred on
    // the disc edge, so it protrudes exactly HANDLE_LENGTH and overlaps the disc
    // by the same amount for a clean manifold union.
    module handle() {
        translate([0, CARRIER_DIAMETER / 2, 0])
            cuboid([HANDLE_WIDTH, HANDLE_LENGTH * 2, CARRIER_HEIGHT], anchor=CENTER, rounding=.5);
    }

    // $fn=72 on a 210mm circle gives ~9mm segments, well below visible thresholds.
    BODY_FN = 72;

    module base_geometry() {
        cyl(h=CARRIER_HEIGHT, r=CARRIER_DIAMETER / 2, center=true, rounding=.5, $fn=BODY_FN);
    }

    // render() caches geometry for faster subsequent previews
    render() union() {
        base_geometry();
        handle();
    }
}
