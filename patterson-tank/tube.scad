/* Setup parameters */
// The number of 35mm reels to fit in the tube. Rule of thumb: 1 medium format reel = ~1.5 35mm reels (round up to 2).
Number_Of_Reels = 2;

/* [Hidden] */
$fn = 100;

THIRTYFIVEMM_REEL_HEIGHT = 42;
TUBE_LENGTH = 43 * Number_Of_Reels;
TUBE_THICKNESS = 1.55;
TUBE_OUTER_DIAMETER = 25.35;
TUBE_INNER_DIAMETER = TUBE_OUTER_DIAMETER - TUBE_THICKNESS * 2;
BASE_HEIGHT_LOWER = 2.2;
BASE_HEIGHT_HIGHER = 3.4 - BASE_HEIGHT_LOWER;
BASE_LOWER_DIAMETER = 39.6;
BASE_HIGHER_DIAMETER = 34.8;
INNER_BOTTOM_CUTOUT_DIAMETER = 30;
ROTARY_STICK_HOLDER_LENGTH = (TUBE_INNER_DIAMETER - 8) / 2;
ROTARY_STICK_HOLDER_WIDTH = 2;
ROTARY_STICK_HOLDER_HEIGHT = 15;

module tube(length, outer_diameter, inner_diameter, thickness) {
    total_base_height = BASE_HEIGHT_LOWER + BASE_HEIGHT_HIGHER;

    union() {
        difference() {
            union() {
                // Main tube positioned so it starts at top of bases
                translate([0, 0, total_base_height + length / 2]) cylinder(h=length, d=outer_diameter, center=true, $fn=100);
                // Lower base at z=0
                cylinder(h=BASE_HEIGHT_LOWER, d=BASE_LOWER_DIAMETER, $fn=100);
                // Higher base on top of lower base
                translate([0, 0, BASE_HEIGHT_LOWER]) cylinder(h=BASE_HEIGHT_HIGHER, d=BASE_HIGHER_DIAMETER, $fn=100);
            }
            // Inner cutout for entire tube length plus bases
            cylinder(h=total_base_height + length, d=inner_diameter, $fn=100);
            // Bottom cutout
            cylinder(h=BASE_HEIGHT_LOWER / 2, d=INNER_BOTTOM_CUTOUT_DIAMETER, $fn=100);
        }

        // Rotary stick holders - two opposite each other inside the tube near the top
        for (angle = [0, 180]) {
            rotate([0, 0, angle])
                translate([inner_diameter / 2 - ROTARY_STICK_HOLDER_LENGTH, -ROTARY_STICK_HOLDER_WIDTH / 2, total_base_height + length - 15 - ROTARY_STICK_HOLDER_HEIGHT])
                    cube([ROTARY_STICK_HOLDER_LENGTH, ROTARY_STICK_HOLDER_WIDTH, ROTARY_STICK_HOLDER_HEIGHT]);
        }
    }
}

tube(TUBE_LENGTH, TUBE_OUTER_DIAMETER, TUBE_INNER_DIAMETER, TUBE_THICKNESS);
