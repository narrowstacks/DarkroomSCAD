// !! READ ME BEFORE USING !!

// - You MUST use the nightly build of OpenSCAD to use this file.
//      The latest nightly build can be found further down the page at https://openscad.org/downloads.html
// - This file is not compatible with the stable release of OpenSCAD.
// - You also must have the BOSL2 library installed.
//      The BOSL2 library can be found at https://github.com/revarbat/BOSL2
// - You must also have the film-sizes.scad file installed in the same directory as this file.
// - In the OpenSCAD preferences, under "Features", enable textmetrics.
// - In the OpenSCAD preferences, change the 3D rendering engine to "Manifold (new/fast)" to greatly speed up the rendering of this file.

include <BOSL2/std.scad>
include <film-sizes.scad> // Include the film size definitions
/* [Carrier Top or Bottom Selection] */
Top_or_Bottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]
/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]

/* [Customization] */
// Name to etch on the carrier
Owner_Name = "AFFORDS";
// Orientation of the film in the carrier
Orientation = "vertical"; // ["vertical", "horizontal"]

/* [Carrier Type Name Source] */
Type_Name = "Carrier Type"; // ["Carrier Type", "Custom"]
// Custom type name, if Type Name is "custom"
Custom_Type_Name = "CUSTOM";
// Font to use for the type name (must be font installed on your OS)
Fontface = "Futura";
// Font size for the type name
Font_Size = 10;

/* [Hidden] */
CARRIER_LENGTH = 202;
CARRIER_WIDTH = 139;
CARRIER_HEIGHT = 2;
CARRIER_CIRCLE_DIAMETER = 168;
CARRIER_RECT_OFFSET = 13.5;
CARRIER_FILLET = 3;
FRAME_FILLET = 0.5;

PEG_DIAMETER = 5.6;
PEG_HEIGHT = 4;

// registration holes
REG_HOLE_DIAMETER = 6.2;
REG_HOLE_DISTANCE = 130;
REG_HOLE_X_LENGTH = 10;
REG_HOLE_OFFSET = 4.5;

// alignment hole screws
ALIGNMENT_SCREW_DIAMETER = 2;
ALIGNMENT_SCREW_DISTANCE_X = 113;
ALIGNMENT_SCREW_DISTANCE_Y = 82;

// General constants
CUT_THROUGH_EXTENSION = 1; // ensures difference operations cut fully through
REG_HOLE_SLOT_LENGTH_EXTENSION = 3; // extends the length of the reg hole slots
REG_HOLE_CYL_Y_OFFSET = 4.6; // Y offset for the cylindrical part of the reg holes
TOP_PEG_HOLE_Z_OFFSET = 2; // Z offset for the peg holes in the top carrier part

// Arrow dimensions for etching
ARROW_LENGTH = 8;
ARROW_WIDTH = 5;
ARROW_ETCH_DEPTH = 0.5;

// Custom type name

// Enter 0 for default gap. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.
PEG_GAP = 0;

// Check if the selected format is a "filed" medium format
IS_FILED_MEDIUM_FORMAT = Film_Format == "6x4.5 filed" ||
    Film_Format == "6x6 filed" ||
    Film_Format == "6x7 filed" ||
    Film_Format == "6x8 filed" ||
    Film_Format == "6x9 filed";

// Internal calculation based on user input, adjusted for filed formats
CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - PEG_GAP) - 1 : (1 - PEG_GAP);

$fn=100;

Film_Format_HEIGHT = Film_Format == "35mm" ? thirtyFiveFullHeight :
    Film_Format == "35mm filed" ? thirtyFiveFiledHeight :
    Film_Format == "35mm full" ? thirtyFiveStandardHeight :
    Film_Format == "half frame" ? halfFrameHeight :
    Film_Format == "6x4.5" ? mediumFormat6x45Length :
    Film_Format == "6x4.5 filed" ? mediumFormat6x45FiledLength :
    Film_Format == "6x6" ? mediumFormat6x6Length :
    Film_Format == "6x6 filed" ? mediumFormat6x6FiledLength :
    Film_Format == "6x7" ? mediumFormat6x7Length :
    Film_Format == "6x7 filed" ? mediumFormat6x7FiledLength :
    Film_Format == "6x8" ? mediumFormat6x8Length :
    Film_Format == "6x8 filed" ? mediumFormat6x8FiledLength :
    Film_Format == "6x9" ? mediumFormat6x9Length :
    Film_Format == "6x9 filed" ? mediumFormat6x9FiledLength :
    Film_Format == "4x5" ? fourByFiveHeight :
    Film_Format == "custom" ? customFilmFormatHeight :
                   130; // Default/fallback
Film_Format_WIDTH = Film_Format == "35mm" ? thirtyFiveStandardWidth :
    Film_Format == "35mm filed" ? thirtyFiveFiledWidth :
    Film_Format == "35mm full" ? thirtyFiveStandardWidth :
    Film_Format == "half frame" ? halfFrameWidth :
    Film_Format == "6x4.5" ? mediumFormatHeight :
    Film_Format == "6x4.5 filed" ? mediumFormatFiledHeight :
    Film_Format == "6x6" ? mediumFormatHeight :
    Film_Format == "6x6 filed" ? mediumFormatFiledHeight :
    Film_Format == "6x7" ? mediumFormatHeight :
    Film_Format == "6x7 filed" ? mediumFormatFiledHeight :
    Film_Format == "6x8" ? mediumFormatHeight :
    Film_Format == "6x8 filed" ? mediumFormatFiledHeight :
    Film_Format == "6x9" ? mediumFormatHeight :
    Film_Format == "6x9 filed" ? mediumFormatFiledHeight :
    Film_Format == "4x5" ? fourByFiveWidth :
    Film_Format == "custom" ? customFilmFormatWidth :
                  130; // Default/fallback
Film_Format_PEG_DISTANCE = Film_Format == "35mm" ? thirtyFiveFullHeight :
    Film_Format == "35mm filed" ? thirtyFiveFullHeight :
    Film_Format == "35mm full" ? thirtyFiveFullHeight :
    Film_Format == "half frame" ? thirtyFiveFullHeight :
    // For medium format, calculate distance based on desired inner edge spacing
    Film_Format == "6x4.5" ? mediumFormatFullHeight :
    Film_Format == "6x4.5 filed" ? mediumFormatFullHeight :
    Film_Format == "6x6" ? mediumFormatFullHeight :
    Film_Format == "6x6 filed" ? mediumFormatFullHeight :
    Film_Format == "6x7" ? mediumFormatFullHeight :
    Film_Format == "6x7 filed" ? mediumFormatFullHeight :
    Film_Format == "6x8" ? mediumFormatFullHeight :
    Film_Format == "6x8 filed" ? mediumFormatFullHeight :
    Film_Format == "6x9" ? mediumFormatFullHeight :
    Film_Format == "6x9 filed" ? mediumFormatFullHeight :
    Film_Format == "6x12" ? mediumFormatFullHeight :
    Film_Format == "6x17" ? mediumFormatFullHeight :
    Film_Format == "4x5" ? fourByFiveFullWidth : // Use film width for 4x5 peg distance base
    Film_Format == "custom" ? customFilmFormatPegDistance :
    130; // Default/fallback

// Select the appropriate type name based on Film_Format and typeNameSource
// selectedTypeName = Film_Format == "custom" ? customTypeName : Film_Format; // Old logic
// selectedTypeName = typeNameSource == "Custom" ? customTypeName : Film_Format; // Previous logic
SELECTED_TYPE_NAME = Type_Name == "Custom" ? Custom_Type_Name :
    Film_Format == "35mm" ? "35MM" :
    Film_Format == "35mm filed" ? "FILED35" :
    Film_Format == "35mm full" ? "FULL35" :
    Film_Format == "half frame" ? "HALF" :
    Film_Format == "6x4.5" ? "645" :
    Film_Format == "6x4.5 filed" ? "FILED645" :
    Film_Format == "6x6" ? "66" :
    Film_Format == "6x6 filed" ? "FILED66" :
    Film_Format == "6x7" ? "67" :
    Film_Format == "6x7 filed" ? "FILED67" :
    Film_Format == "6x8" ? "68" :
    Film_Format == "6x8 filed" ? "FILED68" :
    Film_Format == "6x9" ? "69" :
    Film_Format == "6x9 filed" ? "FILED69" :
    Film_Format == "4x5" ? "4X5" :
    Film_Format; // Fallback to original name if not mapped

// Calculate Z offset for pegs/holes based on topOrBottom
PEG_Z_OFFSET = Top_or_Bottom == "bottom" ? CARRIER_HEIGHT / 2 : CARRIER_HEIGHT - TOP_PEG_HOLE_Z_OFFSET;

/* [Hidden] */
// Calculate the actual type name string first
_SELECTED_TYPE_NAME_FOR_METRICS = Type_Name == "Custom" ? Custom_Type_Name :
    Film_Format == "35mm" ? "35MM" :
    Film_Format == "35mm filed" ? "FILED35" :
    Film_Format == "35mm full" ? "FULL35" :
    Film_Format == "half frame" ? "HALF" :
    Film_Format == "6x4.5" ? "6X45" :
    Film_Format == "6x4.5 filed" ? "FILED645" :
    Film_Format == "6x6" ? "6X6" :
    Film_Format == "6x6 filed" ? "FILED66" :
    Film_Format == "6x7" ? "6X7" :
    Film_Format == "6x7 filed" ? "FILED67" :
    Film_Format == "6x8" ? "6X8" :
    Film_Format == "6x8 filed" ? "FILED68" :
    Film_Format == "6x9" ? "6X9" :
    Film_Format == "6x9 filed" ? "FILED69" :
    Film_Format == "6x12" ? "6X12" :
    Film_Format == "6x17" ? "6X17" :
    Film_Format == "4x5" ? "4X5" :
    Film_Format; // Fallback

// Get text metrics
owner_metrics = textmetrics(text=Owner_Name, font=Fontface, size=10, halign="center", valign="center");
type_metrics = textmetrics(text=_SELECTED_TYPE_NAME_FOR_METRICS, font=Fontface, size=10, halign="center", valign="center");
// echo(str("Owner Name Metrics: ", owner_metrics));
// echo(str("Type Name Metrics (", _SELECTED_TYPE_NAME_FOR_METRICS, "): ", type_metrics));

// Define Safe Area (based on the rectangular part of base_shape)
// Rectangle Center: [-CARRIER_RECT_OFFSET, 0]
// Rectangle Size: [CARRIER_LENGTH, CARRIER_WIDTH]
safe_rect_center_x = -CARRIER_RECT_OFFSET;
safe_rect_size_x = CARRIER_LENGTH;
safe_rect_size_y = CARRIER_WIDTH;
safe_min_x = safe_rect_center_x - safe_rect_size_x / 2;
safe_max_x = safe_rect_center_x + safe_rect_size_x / 2;
safe_min_y = -safe_rect_size_y / 2;
safe_max_y = safe_rect_size_y / 2;
// echo(str("Safe Area X: [", safe_min_x, ", ", safe_max_x, "]"));
// echo(str("Safe Area Y: [", safe_min_y, ", ", safe_max_y, "]"));

// Calculate final bounding boxes (after rotation and translation)
// Text is rotated 270 degrees, so original text width (size[0]) becomes Y extent,
// and original text height (size[1]) becomes X extent.

// Owner Name Module Transform: rotate([0, 0, 270]) translate([0, -100, ...]) -> Text Center at [-100, 0]
// Instantiation Transform: translate([0, -35, 0])
// Final Center: [-100, -35]
owner_rotated_size_x = owner_metrics.size[1]; // text height
owner_rotated_size_y = owner_metrics.size[0]; // text width
owner_center_x = -100;
owner_center_y = -35;
owner_min_x = owner_center_x - owner_rotated_size_x / 2;
owner_max_x = owner_center_x + owner_rotated_size_x / 2;
owner_min_y = owner_center_y - owner_rotated_size_y / 2;
owner_max_y = owner_center_y + owner_rotated_size_y / 2;
// echo(str("Owner Name Final BBox X: [", owner_min_x, ", ", owner_max_x, "]"));
// echo(str("Owner Name Final BBox Y: [", owner_min_y, ", ", owner_max_y, "]"));

// Type Name Module Transform: rotate([0, 0, 270]) translate([-40, -100, ...]) -> Text Center at [-100, 40]
// Instantiation Transform: translate([0, 0, 0])
// Final Center: [-100, 40]
type_rotated_size_x = type_metrics.size[1]; // text height
type_rotated_size_y = type_metrics.size[0]; // text width
type_center_x = -100;
type_center_y = 40;
type_min_x = type_center_x - type_rotated_size_x / 2;
type_max_x = type_center_x + type_rotated_size_x / 2;
type_min_y = type_center_y - type_rotated_size_y / 2;
type_max_y = type_center_y + type_rotated_size_y / 2;
// echo(str("Type Name Final BBox X: [", type_min_x, ", ", type_max_x, "]"));
// echo(str("Type Name Final BBox Y: [", type_min_y, ", ", type_max_y, "]"));

// Check bounds and assert if text goes outside the safe rectangular area
assert(owner_min_x >= safe_min_x && owner_max_x <= safe_max_x,
       str("ERROR: Owner Name '", Owner_Name, "' X dimension [", owner_min_x, ", ", owner_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider shortening the name or adjusting position."));
assert(owner_min_y >= safe_min_y && owner_max_y <= safe_max_y,
       str("ERROR: Owner Name '", Owner_Name, "' Y dimension [", owner_min_y, ", ", owner_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider shortening the name or adjusting position."));
assert(type_min_x >= safe_min_x && type_max_x <= safe_max_x,
       str("ERROR: Type Name '", _SELECTED_TYPE_NAME_FOR_METRICS, "' X dimension [", type_min_x, ", ", type_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider adjusting position."));
assert(type_min_y >= safe_min_y && type_max_y <= safe_max_y,
       str("ERROR: Type Name '", _SELECTED_TYPE_NAME_FOR_METRICS, "' Y dimension [", type_min_y, ", ", type_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider adjusting position."));
/* [/Text Boundary Checks] */


module owner_name_etch() {
    // Extrude the text slightly to allow for subtraction
    linear_extrude(height = 1) {
        rotate([0, 0, 270])
        translate([30, -95, CARRIER_HEIGHT/2]) // Position the text to cut into the top surface
            text(Owner_Name, font = Fontface, size = 10, halign = "right", valign = "top");
    }
}

module type_name_etch() {
    // Extrude the text slightly to allow for subtraction
    linear_extrude(height = 1) {
        rotate([0, 0, 270])
        translate([-30, -95, CARRIER_HEIGHT/2]) // Position the text to cut into the top surface
            text(SELECTED_TYPE_NAME, font = Fontface, size = 10, halign = "right", valign = "top");
    }
}


module base_shape() {
    color("grey") union() {
        cylinder(h=CARRIER_HEIGHT, r=CARRIER_CIRCLE_DIAMETER/2, center = true);
        translate([-CARRIER_RECT_OFFSET, 0, 0]) cuboid([CARRIER_LENGTH, CARRIER_WIDTH, CARRIER_HEIGHT], anchor = CENTER, rounding=CARRIER_FILLET, edges=[[0,0,0,0], [0,0,0,0], [1,1,1,1]]);
    }
}

module film_opening() {
    effective_orientation = (Film_Format == "4x5") ? "vertical" : Orientation;
    openingHeight = effective_orientation == "vertical" ? Film_Format_HEIGHT : Film_Format_WIDTH;
    openingWidth = effective_orientation == "vertical" ? Film_Format_WIDTH : Film_Format_HEIGHT;
    color("red") cuboid([openingHeight, openingWidth, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION ], chamfer = FRAME_FILLET, anchor = CENTER);
}

module alignment_screw_holes(is_dent = false, dent_depth = 1) {
    hole_height = is_dent ? dent_depth : CARRIER_HEIGHT + CUT_THROUGH_EXTENSION;
    z_pos = is_dent ? -CARRIER_HEIGHT / 2 : 0; // Start dents from the bottom, center through-holes
    use_center = !is_dent; // Only center through-holes
    hole_radius = is_dent ? ALIGNMENT_SCREW_DIAMETER/2 + 0.25 : ALIGNMENT_SCREW_DIAMETER/2;

    color("red") translate([ALIGNMENT_SCREW_DISTANCE_Y/2, ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
    color("red") translate([-ALIGNMENT_SCREW_DISTANCE_Y/2, ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
    color("red") translate([ALIGNMENT_SCREW_DISTANCE_Y/2, -ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
    color("red") translate([-ALIGNMENT_SCREW_DISTANCE_Y/2, -ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_height, r=hole_radius, center = use_center);
}

module registration_holes() {
    color("red") translate([REG_HOLE_DISTANCE/2 + REG_HOLE_DIAMETER/2, -REG_HOLE_DISTANCE/2, 0]) cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
    color("red") translate([-REG_HOLE_DISTANCE/2 - REG_HOLE_DIAMETER/2, -REG_HOLE_DISTANCE/2, 0]) cuboid([REG_HOLE_DIAMETER, REG_HOLE_DIAMETER + REG_HOLE_SLOT_LENGTH_EXTENSION, CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
    color("red") translate([REG_HOLE_DISTANCE/2 + REG_HOLE_DIAMETER/2, -REG_HOLE_DISTANCE/2 + REG_HOLE_CYL_Y_OFFSET, 0]) cylinder(h=CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=REG_HOLE_DIAMETER/2, center = true);
    color("red") translate([-REG_HOLE_DISTANCE/2 - REG_HOLE_DIAMETER/2, -REG_HOLE_DISTANCE/2 + REG_HOLE_CYL_Y_OFFSET, 0]) cylinder(h=CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=REG_HOLE_DIAMETER/2, center = true);
}

module pegs_feature(is_hole = false) {
    radius = is_hole ? PEG_DIAMETER/2 + 0.25 : PEG_DIAMETER/2;
    // Use correct z_offset based on whether it's top or bottom/test
    z_offset = Top_or_Bottom == "top" ? PEG_Z_OFFSET : CARRIER_HEIGHT / 2;
    effective_orientation = (Film_Format == "4x5") ? "vertical" : Orientation;

    // Calculate peg positions based on Orientation
    pegPosX = effective_orientation == "vertical" ?
                (Film_Format_WIDTH/2 + PEG_DIAMETER/2) :
                (Film_Format_PEG_DISTANCE/2 + PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP); // Adjusted distance along X for horizontal

    pegPosY = effective_orientation == "vertical" ?
                (Film_Format_PEG_DISTANCE/2 + PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP) : // Adjusted distance along Y for vertical
                (Film_Format_WIDTH/2 + PEG_DIAMETER/2); // Width along Y for horizontal

    color("blue") {
        translate([pegPosX, pegPosY, z_offset]) cylinder(h=PEG_HEIGHT, r=radius, center = true);
        translate([pegPosX, -pegPosY, z_offset]) cylinder(h=PEG_HEIGHT, r=radius, center = true);
        translate([-pegPosX, pegPosY, z_offset]) cylinder(h=PEG_HEIGHT, r=radius, center = true);
        translate([-pegPosX, -pegPosY, z_offset]) cylinder(h=PEG_HEIGHT, r=radius, center = true);
    }
}

// Module to create a left-pointing arrow shape for etching
module arrow_etch(etch_depth = 0.5, length = 5, width = 3) {
    // Centered around [0,0] for easier placement later
    // Tip at [-length/2, 0], Base at [length/2, +/- width/2]
    translate([-10 ,0, .5]) // Position Z base at the top surface
    linear_extrude(height = etch_depth) // Extrude upwards
        polygon(points=[ [-length/2, 0], [length/2, width/2], [length/2, -width/2] ]);
}

// Main logic
if (Top_or_Bottom == "bottom") {
    union() {
        difference() {
            base_shape();
            film_opening();
            registration_holes();
            alignment_screw_holes();
            translate([0, -35, 0]) owner_name_etch();
            translate([0, 0, 0]) type_name_etch();

            // Add arrow etch for 6x6 formats
            if (Film_Format == "6x6" || Film_Format == "6x6 filed") {
                arrowOffset = 5; // Distance from opening edge to arrow tip
                if (Orientation == "vertical") {
                    // Arrow points right (-->), placed to the right of the opening
                    currentOpeningWidth = Film_Format_WIDTH; // Width along X
                    arrowPosX = 0; // Center X of arrow
                    arrowPosY = currentOpeningWidth / 2 + arrowOffset + ARROW_LENGTH / 2;
                    translate([arrowPosX + 10, -arrowPosY , 0])
                        arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                } else { // Orientation == "vertical"
                    // Arrow points down (v), placed below the opening
                    currentOpeningHeight = Film_Format_HEIGHT; // Height along Y
                    arrowPosX = 0; // Center X
                    arrowPosY = -currentOpeningHeight / 2 - arrowOffset - ARROW_LENGTH / 2; // Center Y of arrow
                    translate([arrowPosX, arrowPosY, 0])
                    rotate([0, 0, 90]) // Point down
                        arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                }
            }
        }
        pegs_feature(); // Add pegs
    }
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    // Create a smaller base for the test piece, slightly larger than the film opening + pegs
    testPiecePadding = 8; // Add padding around

    // Calculate required dimensions based on Orientation
    effective_orientation_test = (Film_Format == "4x5") ? "vertical" : Orientation;
    pegPosX_test = effective_orientation_test == "vertical" ?
                (Film_Format_WIDTH/2 + PEG_DIAMETER/2) :
                (Film_Format_PEG_DISTANCE/2 + PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP);
    pegPosY_test = effective_orientation_test == "vertical" ?
                (Film_Format_PEG_DISTANCE/2 + PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP) :
                (Film_Format_WIDTH/2 + PEG_DIAMETER/2);

    // Test piece dimensions based on max extent of pegs
    testPieceWidth = 2 * pegPosY_test + testPiecePadding * 2;
    testPieceHeight = 2 * pegPosX_test + testPiecePadding * 2;

    difference() {
        // Center the test piece
        cuboid([testPieceHeight, testPieceWidth, CARRIER_HEIGHT], anchor = CENTER);
        film_opening();
        // Subtract holes if it's the top test piece
        if (Top_or_Bottom == "frameAndPegTestTop") {
            pegs_feature(is_hole = true);
        }
    }
    // Add pegs if it's the bottom test piece
    if (Top_or_Bottom == "frameAndPegTestBottom") {
        pegs_feature();
    }
} else { // topOrBottom == "top"
    difference() {
        base_shape();
        film_opening();
        registration_holes();
        pegs_feature(is_hole = true); // Subtract holes
        alignment_screw_holes(is_dent = true, dent_depth = 1); // Top part gets 1mm dents
        translate([0, -35, 0]) owner_name_etch();
        translate([0, 0, 0]) type_name_etch();
    }
}
