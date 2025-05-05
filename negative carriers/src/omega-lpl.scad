include <BOSL2/std.scad>
/* [Film Format] */
filmFormat = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "custom"]

/* [Customization] */
// Name to etch on the carrier
ownerName = "AFFORDS";
// Type of film holder to etch on the carrier
// typeNames = ["FILED35", "FILED645", "FILED66", "FILED67", "FILED68", "FILED69", "FILED612", "FILED617", "FILED45", "CUSTOM"]; // Removed: Use typeNameSource instead

/* [Carrier Type Name Source] */
typeNameSource = "Carrier Type"; // ["Carrier Type", "Custom"]
orientation = "vertical"; // ["vertical", "horizontal"]


// Custom type name
customTypeName = "CUSTOM";
// Enter 0 for default gap. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.
pegGap = 0;

/* [Orientation] */

// Check if the selected format is a "filed" medium format
isFiledMediumFormat = filmFormat == "6x4.5 filed" ||
                      filmFormat == "6x6 filed" ||
                      filmFormat == "6x7 filed" ||
                      filmFormat == "6x8 filed" ||
                      filmFormat == "6x9 filed";

// Internal calculation based on user input, adjusted for filed formats
calculatedInternalPegGap = isFiledMediumFormat ? (1 - pegGap) - 1 : (1 - pegGap);

/* [Top or Bottom] */
topOrBottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]

/* [Hidden] */
// film sizes
thirtyFiveFullHeight = 37;
mediumFormatFullHeight = 61;

// 120/220 film height
mediumFormatHeight = 56;
mediumFormatFiledHeight = 58;
// 6x4.5 film length
mediumFormat6x45Length = 41.5;
mediumFormat6x45FiledLength = 43.5;
// 6x6 film length
mediumFormat6x6Length = 56;
mediumFormat6x6FiledLength = 58;
// 6x7 film length
mediumFormat6x7Length = 70;
mediumFormat6x7FiledLength = 72;
// 6x8 film length
mediumFormat6x8Length = 77;
mediumFormat6x8FiledLength = 79;
// 6x9 film length
mediumFormat6x9Length = 84;
mediumFormat6x9FiledLength = 86;

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

// Custom film format defaults (adjust as needed)
customFilmFormatHeight = 50;
customFilmFormatWidth = 50;
customFilmFormatPegDistance = 61; // Defaulting to medium format height

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
regHoleCylYOffset = 4.6; // Y offset for the cylindrical part of the reg holes
topPegHoleZOffset = 2; // Z offset for the peg holes in the top carrier part

$fn=100;

filmFormatHeight = filmFormat == "35mm" ? thirtyFiveFullHeight :
                   filmFormat == "35mm filed" ? thirtyFiveFiledHeight :
                   filmFormat == "35mm full" ? thirtyFiveStandardHeight :
                   filmFormat == "half frame" ? halfFrameHeight :
                   filmFormat == "6x4.5" ? mediumFormat6x45Length :
                   filmFormat == "6x4.5 filed" ? mediumFormat6x45FiledLength :
                   filmFormat == "6x6" ? mediumFormat6x6Length :
                   filmFormat == "6x6 filed" ? mediumFormat6x6FiledLength :
                   filmFormat == "6x7" ? mediumFormat6x7Length :
                   filmFormat == "6x7 filed" ? mediumFormat6x7FiledLength :
                   filmFormat == "6x8" ? mediumFormat6x8Length :
                   filmFormat == "6x8 filed" ? mediumFormat6x8FiledLength :
                   filmFormat == "6x9" ? mediumFormat6x9Length :
                   filmFormat == "6x9 filed" ? mediumFormat6x9FiledLength :
                   filmFormat == "4x5" ? fourByFiveHeight :
                   filmFormat == "custom" ? customFilmFormatHeight :
                   130; // Default/fallback
filmFormatWidth = filmFormat == "35mm" ? thirtyFiveStandardWidth :
                  filmFormat == "35mm filed" ? thirtyFiveFiledWidth :
                  filmFormat == "35mm full" ? thirtyFiveStandardWidth :
                  filmFormat == "half frame" ? halfFrameWidth :
                  filmFormat == "6x4.5" ? mediumFormatHeight :
                  filmFormat == "6x4.5 filed" ? mediumFormatFiledHeight :
                  filmFormat == "6x6" ? mediumFormatHeight :
                  filmFormat == "6x6 filed" ? mediumFormatFiledHeight :
                  filmFormat == "6x7" ? mediumFormatHeight :
                  filmFormat == "6x7 filed" ? mediumFormatFiledHeight :
                  filmFormat == "6x8" ? mediumFormatHeight :
                  filmFormat == "6x8 filed" ? mediumFormatFiledHeight :
                  filmFormat == "6x9" ? mediumFormatHeight :
                  filmFormat == "6x9 filed" ? mediumFormatFiledHeight :
                  filmFormat == "4x5" ? fourByFiveWidth :
                  filmFormat == "custom" ? customFilmFormatWidth :
                  130; // Default/fallback
filmFormatPegDistance = filmFormat == "35mm" ? thirtyFiveFullHeight :
                        filmFormat == "35mm filed" ? thirtyFiveFullHeight :
                        filmFormat == "35mm full" ? thirtyFiveFullHeight :
                        filmFormat == "half frame" ? thirtyFiveFullHeight :
                        // For medium format, calculate distance based on desired inner edge spacing
                        filmFormat == "6x4.5" ? mediumFormatFullHeight :
                        filmFormat == "6x4.5 filed" ? mediumFormatFullHeight :
                        filmFormat == "6x6" ? mediumFormatFullHeight :
                        filmFormat == "6x6 filed" ? mediumFormatFullHeight :
                        filmFormat == "6x7" ? mediumFormatFullHeight :
                        filmFormat == "6x7 filed" ? mediumFormatFullHeight :
                        filmFormat == "6x8" ? mediumFormatFullHeight :
                        filmFormat == "6x8 filed" ? mediumFormatFullHeight :
                        filmFormat == "6x9" ? mediumFormatFullHeight :
                        filmFormat == "6x9 filed" ? mediumFormatFullHeight :
                        filmFormat == "6x12" ? mediumFormatFullHeight :
                        filmFormat == "6x17" ? mediumFormatFullHeight :
                        filmFormat == "4x5" ? mediumFormatFullHeight : // Use medium format height for 4x5 peg distance base
                        filmFormat == "custom" ? customFilmFormatPegDistance :
                        130; // Default/fallback

// Select the appropriate type name based on filmFormat and typeNameSource
// selectedTypeName = filmFormat == "custom" ? customTypeName : filmFormat; // Old logic
// selectedTypeName = typeNameSource == "Custom" ? customTypeName : filmFormat; // Previous logic
selectedTypeName = typeNameSource == "Custom" ? customTypeName :
                   filmFormat == "35mm" ? "35MM" :
                   filmFormat == "35mm filed" ? "FILED35" :
                   filmFormat == "35mm full" ? "FULL35" :
                   filmFormat == "half frame" ? "HALF" :
                   filmFormat == "6x4.5" ? "6X45" :
                   filmFormat == "6x4.5 filed" ? "FILED645" :
                   filmFormat == "6x6" ? "6X6" :
                   filmFormat == "6x6 filed" ? "FILED66" :
                   filmFormat == "6x7" ? "6X7" :
                   filmFormat == "6x7 filed" ? "FILED67" :
                   filmFormat == "6x8" ? "6X8" :
                   filmFormat == "6x8 filed" ? "FILED68" :
                   filmFormat == "6x9" ? "6X9" :
                   filmFormat == "6x9 filed" ? "FILED69" :
                   filmFormat == "6x12" ? "6X12" :
                   filmFormat == "6x17" ? "6X17" :
                   filmFormat == "4x5" ? "4X5" :
                   filmFormat; // Fallback to original name if not mapped

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
            text(selectedTypeName, font = "Futura", size = 10, halign = "center", valign = "center");
    }
}


module base_shape() {
    color("grey") union() {
        cylinder(h=carrierHeight, r=carrierCircleDiameter/2, center = true);
        translate([-carrierRectOffset, 0, 0]) cuboid([carrierLength, carrierWidth, carrierHeight], anchor = CENTER, rounding=4, edges=[[0,0,0,0], [0,0,0,0], [1,1,1,1]]);
    }
}

module film_opening() {
    openingHeight = orientation == "vertical" ? filmFormatHeight : filmFormatWidth;
    openingWidth = orientation == "vertical" ? filmFormatWidth : filmFormatHeight;
    color("red") cuboid([openingHeight, openingWidth, carrierHeight + cutThroughExtension ], chamfer = .5, anchor = CENTER);
}

module alignment_screw_holes(is_dent = false, dent_depth = 1) {
    hole_height = is_dent ? dent_depth : carrierHeight + cutThroughExtension;
    z_pos = is_dent ? -carrierHeight / 2 : 0; // Start dents from the bottom, center through-holes
    use_center = !is_dent; // Only center through-holes
    hole_radius = is_dent ? alignmentScrewDiameter/2 + 0.25 : alignmentScrewDiameter/2;

    color("red") translate([alignmentScrewDistanceY/2, alignmentScrewDistanceX/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
    color("red") translate([-alignmentScrewDistanceY/2, alignmentScrewDistanceX/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
    color("red") translate([alignmentScrewDistanceY/2, -alignmentScrewDistanceX/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
    color("red") translate([-alignmentScrewDistanceY/2, -alignmentScrewDistanceX/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
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

    // Calculate peg positions based on orientation
    pegPosX = orientation == "vertical" ?
                (filmFormatWidth/2 + pegDiameter/2) :
                (filmFormatPegDistance/2 + pegDiameter/2 - calculatedInternalPegGap); // Adjusted distance along X for horizontal

    pegPosY = orientation == "vertical" ?
                (filmFormatPegDistance/2 + pegDiameter/2 - calculatedInternalPegGap) : // Adjusted distance along Y for vertical
                (filmFormatWidth/2 + pegDiameter/2); // Width along Y for horizontal

    color("blue") {
        translate([pegPosX, pegPosY, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
        translate([pegPosX, -pegPosY, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
        translate([-pegPosX, pegPosY, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
        translate([-pegPosX, -pegPosY, z_offset]) cylinder(h=pegHeight, r=radius, center = true);
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

    // Calculate required dimensions based on orientation
    pegPosX_test = orientation == "vertical" ?
                (filmFormatWidth/2 + pegDiameter/2) :
                (filmFormatPegDistance/2 + pegDiameter/2 - calculatedInternalPegGap);
    pegPosY_test = orientation == "vertical" ?
                (filmFormatPegDistance/2 + pegDiameter/2 - calculatedInternalPegGap) :
                (filmFormatWidth/2 + pegDiameter/2);

    // Test piece dimensions based on max extent of pegs
    testPieceWidth = 2 * pegPosY_test + testPiecePadding * 2;
    testPieceHeight = 2 * pegPosX_test + testPiecePadding * 2;

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
        alignment_screw_holes(is_dent = true, dent_depth = 1); // Top part gets 1mm dents
        translate([0, -35, 0]) owner_name();
        translate([0, 0, 0]) type_name();
    }
}
