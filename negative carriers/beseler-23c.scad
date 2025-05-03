include <BOSL2/std.scad>


// Select the desired film format
filmFormat = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x6", "6x7", "6x8", "6x9", "custom"]
topOrBottom = "bottom"; // ["top", "bottom"]


/* [Hidden] */
carrierDiameter = 160;
carrierHeight = 2;
alignmentCircleOuterDiameter = 120;
alignmentCircleInnerDiameter = 110;
alignmentCircleThickness = 5;
pegZOffset = 1;

handleLength = 50;
handleWidth = 42;

// custom opening height
customFilmFormatHeight = 36;
// custom opening width
customFilmFormatWidth = 24;
// custom film format height (for peg distance)
customFilmFormatPegDistance = 36;

$fn=100;

module alignment_circle() {
    // Major radius R = (OuterD/2 + InnerD/2) / 2 = (120/2 + 110/2) / 2 = (60 + 55) / 2 = 57.5
    // Minor radius r = (OuterD/2 - InnerD/2) / 2 = (60 - 55) / 2 = 2.5
    // Height = 2 * r = 5, which matches alignmentCircleThickness
    color("red") torus(r_maj = alignmentCircleOuterDiameter/4 + alignmentCircleInnerDiameter/4, 
                       r_min = alignmentCircleOuterDiameter/4 - alignmentCircleInnerDiameter/4, 
                       anchor=CENTER);
}

module handle() {
    translate([0, carrierDiameter/2, 0]) color("grey") cuboid([handleWidth, handleLength*1.5, carrierHeight], anchor = CENTER);
}

module base_shape() {
    color("grey") union() {
        cylinder(h=carrierHeight, r=carrierDiameter/2, center = true);
    }
}

// Main logic
if (topOrBottom == "bottom") {
    union() {
        difference() {
            base_shape();
            film_opening();
            alignment_circle();
        }
        pegs_feature();
        handle();
    }
} else { // topOrBottom == "top"
    difference() {
        base_shape();
        film_opening();
        pegs_feature(is_hole = true);
    }
    handle();
}
