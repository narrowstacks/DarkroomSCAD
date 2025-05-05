include <BOSL2/std.scad>
/* [Film Format] */
filmFormat = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x6", "6x7", "6x8", "6x9", "custom"]

/* [Customization] */
// Name to etch on the carrier
ownerName = "AFFORDS";
// Type of film holder to etch on the carrier
typeName = "FILED35";
// Subtract to increase the gap between the pegs, add to decrease the gap. Default 1 allows for little wiggle.
pegGap = 1; 

/* [Top or Bottom] */
topOrBottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]

/* [Hidden] */
// film sizes
thirtyFiveFullHeight = 37;
mediumFormatFullHeight = 61;

// 120/220 film height
mediumFormatHeight = 56;
// 6x4.5 film length
mediumFormat6x45Length = 41.5;
// 6x6 film length
mediumFormat6x6Length = 56;
// 6x7 film length
mediumFormat6x7Length = 70;
// 6x8 film length
mediumFormat6x8Length = 77;
// 6x9 film length
mediumFormat6x9Length = 84;

// 4x5 film height
fourByFiveHeight = 127;
// 4x5 film width
fourByFiveWidth = 102;
// 35mm film height
thirtyFiveStandardHeight = 36;
// 35mm film width
thirtyFiveStandardWidth = 24;
// 35mm filed carrier film height
thirtyFiveFiledHeight = 38;
// 35mm filed carrier film width
thirtyFiveFiledWidth = 27;
// half frame width
halfFrameWidth = 24;
// half frame height
halfFrameHeight = 18;

carrierLength = 202;
carrierWidth = 139;
carrierHeight = 2;
carrierCircleDiameter = 168;
carrierRectOffset = 13.5;
carrierFillet = 3;
frameFillet = 0.5;

pegDiameter = 5.6;
pegHeight = 4;

// registration holes
regHoleDiameter = 6.2;
regHoleDistance = 130;
regHoleXLength = 10;
regHoleOffset = 4.5;

// alignment hole screws
alignmentScrewDiameter = 2;
alignmentScrewDistanceX = 113;
alignmentScrewDistanceY = 82;

// General constants
cutThroughExtension = 1; // ensures difference operations cut fully through
regHoleSlotLengthExtension = 3; // extends the length of the reg hole slots
regHoleCylYOffset = 4.5; // Y offset for the cylindrical part of the reg holes
topPegHoleZOffset = 2; // Z offset for the peg holes in the top carrier part

$fn=100;

filmFormatHeight = filmFormat == "35mm" ? thirtyFiveFullHeight : filmFormat == "35mm filed" ? thirtyFiveFiledHeight : filmFormat == "35mm full" ? thirtyFiveStandardHeight : filmFormat == "half frame" ? halfFrameHeight : filmFormat == "6x4.5" ? mediumFormat6x45Length : filmFormat == "6x6" ? mediumFormat6x6Length : filmFormat == "6x7" ? mediumFormat6x7Length : filmFormat == "6x8" ? mediumFormat6x8Length : filmFormat == "6x9" ? mediumFormat6x9Length : filmFormat == "6x12" ? mediumFormat6x12Length : filmFormat == "6x17" ? mediumFormat6x17Length : filmFormat == "4x5" ? fourByFiveHeight : filmFormat == "custom" ? customFilmFormatHeight : 130;
filmFormatWidth = filmFormat == "35mm" ? thirtyFiveStandardWidth : filmFormat == "35mm filed" ? thirtyFiveFiledWidth : filmFormat == "35mm full" ? thirtyFiveStandardWidth : filmFormat == "half frame" ? halfFrameWidth : filmFormat == "6x4.5" ? mediumFormatHeight : filmFormat == "6x6" ? mediumFormatHeight : filmFormat == "6x7" ? mediumFormatHeight : filmFormat == "6x8" ? mediumFormatHeight : filmFormat == "6x9" ? mediumFormatHeight : filmFormat == "6x12" ? mediumFormatHeight : filmFormat == "6x17" ? mediumFormatHeight : filmFormat == "4x5" ? fourByFiveWidth : filmFormat == "custom" ? customFilmFormatWidth : 130;
filmFormatPegDistance = filmFormat == "35mm" ? thirtyFiveFullHeight : filmFormat == "35mm filed" ? thirtyFiveFullHeight : filmFormat == "35mm full" ? thirtyFiveFullHeight : filmFormat == "half frame" ? thirtyFiveFullHeight : filmFormat == "6x4.5" ? mediumFormatFullHeight : filmFormat == "6x6" ? mediumFormatFullHeight : filmFormat == "6x7" ? mediumFormatFullHeight : filmFormat == "6x8" ? mediumFormatFullHeight : filmFormat == "6x9" ? mediumFormatFullHeight : filmFormat == "6x12" ? mediumFormatFullHeight : filmFormat == "6x17" ? mediumFormatFullHeight : filmFormat == "4x5" ? mediumFormatFullHeight : filmFormat == "custom" ? customFilmFormatPegDistance : 130;

// Calculate Z offset for pegs/holes based on topOrBottom
pegZOffset = topOrBottom == "bottom" ? carrierHeight / 2 : carrierHeight - topPegHoleZOffset;

module owner_name() {
    // Extrude the text slightly to allow for subtraction
    linear_extrude(height = 1) {
        rotate([0, 0, 270])
        translate([0, -100, carrierHeight/2]) // Position the text to cut into the top surface
            text(ownerName, font = "Futura", size = 10, halign = "center", valign = "center");
    }
}

module type_name() {
    // Extrude the text slightly to allow for subtraction
    linear_extrude(height = 1) {
        rotate([0, 0, 270])
        translate([-40, -100, carrierHeight/2]) // Position the text to cut into the top surface
            text(typeName, font = "Futura", size = 10, halign = "center", valign = "center");
    }
}


module base_shape() {
    color("grey") union() {
        cylinder(h=carrierHeight, r=carrierCircleDiameter/2, center = true);
        translate([-carrierRectOffset, 0, 0]) cuboid([carrierLength, carrierWidth, carrierHeight], anchor = CENTER, rounding=4, edges=[[0,0,0,0], [0,0,0,0], [1,1,1,1]]);
    }
}

module film_opening() {
    color("red") cuboid([filmFormatHeight, filmFormatWidth, carrierHeight + cutThroughExtension ], chamfer = .5, anchor = CENTER);
}

module alignment_screw_holes() {
    color("red") translate([alignmentScrewDistanceY/2, alignmentScrewDistanceX/2, 0]) cylinder(h=carrierHeight + cutThroughExtension, r=alignmentScrewDiameter/2, center = true);
    color("red") translate([-alignmentScrewDistanceY/2, alignmentScrewDistanceX/2, 0]) cylinder(h=carrierHeight + cutThroughExtension, r=alignmentScrewDiameter/2, center = true);
    color("red") translate([alignmentScrewDistanceY/2, -alignmentScrewDistanceX/2, 0]) cylinder(h=carrierHeight + cutThroughExtension, r=alignmentScrewDiameter/2, center = true);
    color("red") translate([-alignmentScrewDistanceY/2, -alignmentScrewDistanceX/2, 0]) cylinder(h=carrierHeight + cutThroughExtension, r=alignmentScrewDiameter/2, center = true);
}

module registration_holes() {
    color("red") translate([regHoleDistance/2 + regHoleDiameter/2, -regHoleDistance/2, 0]) cuboid([regHoleDiameter, regHoleDiameter + regHoleSlotLengthExtension, carrierHeight + cutThroughExtension], anchor = CENTER);
    color("red") translate([-regHoleDistance/2 - regHoleDiameter/2, -regHoleDistance/2, 0]) cuboid([regHoleDiameter, regHoleDiameter + regHoleSlotLengthExtension, carrierHeight + cutThroughExtension], anchor = CENTER);
    color("red") translate([regHoleDistance/2 + regHoleDiameter/2, -regHoleDistance/2 + regHoleCylYOffset, 0]) cylinder(h=carrierHeight + cutThroughExtension, r=regHoleDiameter/2, center = true);
    color("red") translate([-regHoleDistance/2 - regHoleDiameter/2, -regHoleDistance/2 + regHoleCylYOffset, 0]) cylinder(h=carrierHeight + cutThroughExtension, r=regHoleDiameter/2, center = true);
}

module pegs_feature(is_hole = false) {
    radius = is_hole ? pegDiameter/2 + 0.25 : pegDiameter/2;
    // Use correct z_offset based on whether it's top or bottom/test
    z_offset = topOrBottom == "top" ? pegZOffset : carrierHeight / 2;
    color("blue") {
        translate([filmFormatWidth/2 + pegDiameter/2, -filmFormatPegDistance/2 - pegDiameter/2 + pegGap, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
        translate([filmFormatWidth/2 + pegDiameter/2, filmFormatPegDistance/2 + pegDiameter/2 - pegGap, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
        translate([-filmFormatWidth/2 - pegDiameter/2, -filmFormatPegDistance/2 - pegDiameter/2 + pegGap, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
        translate([-filmFormatWidth/2 - pegDiameter/2, filmFormatPegDistance/2 + pegDiameter/2 - pegGap, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
    }
}

// Main logic
if (topOrBottom == "bottom") {
    union() {
        difference() {
            base_shape();
            film_opening();
            registration_holes();
            alignment_screw_holes();
            translate([0, -35, 0]) owner_name();
            translate([0, 0, 0]) type_name();
        }
        pegs_feature(); // Add pegs
    }
} else if (topOrBottom == "frameAndPegTestBottom" || topOrBottom == "frameAndPegTestTop") {
    // Create a smaller base for the test piece, slightly larger than the film opening + pegs
    testPiecePadding = 8; // Add padding around
    testPieceWidth = filmFormatWidth + pegDiameter * 2 + testPiecePadding * 2;
    testPieceHeight = filmFormatPegDistance + pegDiameter * 2 + testPiecePadding * 2;

    difference() {
        // Center the test piece
        cuboid([testPieceHeight, testPieceWidth, carrierHeight], anchor = CENTER);
        film_opening();
        // Subtract holes if it's the top test piece
        if (topOrBottom == "frameAndPegTestTop") {
            pegs_feature(is_hole = true);
        }
    }
    // Add pegs if it's the bottom test piece
    if (topOrBottom == "frameAndPegTestBottom") {
        pegs_feature();
    }
} else { // topOrBottom == "top"
    difference() {
        base_shape();
        film_opening();
        registration_holes();
        pegs_feature(is_hole = true); // Subtract holes
        translate([0, -35, 0]) owner_name();
        translate([0, 0, 0]) type_name();
    }
}
