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
include <common-carrier-features.scad> // Include common features

/* [Carrier Options] */
// Top or bottom of the carrier
Top_or_Bottom = "bottom"; // ["top", "bottom", "frameAndPegTestBottom", "frameAndPegTestTop"]
// Orientation of the film in the carrier
Orientation = "vertical"; // ["vertical", "horizontal"]

/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]

/* [Customization] */
// Enable or disable the owner name etching
Enable_Owner_Name_Etch = true; // [true, false]
// Name to etch on the carrier
Owner_Name = "NAME";

/* [Carrier Type Name Source] */
// Enable or disable the type name etching
Enable_Type_Name_Etch = true; // [true, false]
Type_Name = "Carrier Type"; // ["Carrier Type", "Custom"]
// Custom type name, if Type Name is "custom"
Custom_Type_Name = "CUSTOM";

/* [Name and Format Etchings Settings] */
// Font to use for the etchings
Fontface = "Futura";
// Font size for etchings
Font_Size = 10;
// Depth for etching
TEXT_ETCH_DEPTH = 1; 





/* [Adjustments] */
// Leave at 0 for default gap. Measured in mm. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.
Peg_Gap = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film width, subtract (use negative values) to decrease it.
Adjust_Film_Width = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film height, subtract (use negative values) to decrease it.
Adjust_Film_Height = 0;



/* [Hidden] */
OMEGA_D_CARRIER_LENGTH = 202;
OMEGA_D_CARRIER_WIDTH = 139;
OMEGA_D_CARRIER_HEIGHT = 2;
OMEGA_D_CARRIER_CIRCLE_DIAMETER = 168;
OMEGA_D_CARRIER_RECT_OFFSET = 13.5;
OMEGA_D_CARRIER_FILLET = 3;
OMEGA_D_FRAME_FILLET = 0.5;

OMEGA_D_PEG_DIAMETER = 5.6;
OMEGA_D_PEG_HEIGHT = 4;

// registration holes
OMEGA_D_REG_HOLE_DIAMETER = 6.2;
OMEGA_D_REG_HOLE_DISTANCE = 130;
OMEGA_D_REG_HOLE_X_LENGTH = 10;
OMEGA_D_REG_HOLE_OFFSET = 4.5;

// alignment hole screws
OMEGA_D_ALIGNMENT_SCREW_DIAMETER = 2;
OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X = 113;
OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y = 82;

// General constants
CUT_THROUGH_EXTENSION = 1; // ensures difference operations cut fully through
OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION = 3; // extends the length of the reg hole slots
OMEGA_D_REG_HOLE_CYL_Y_OFFSET = 4.6; // Y offset for the cylindrical part of the reg holes
OMEGA_D_TOP_PEG_HOLE_Z_OFFSET = 2; // Z offset for the peg holes in the top carrier part

// Arrow dimensions for etching
ARROW_LENGTH = 8;
ARROW_WIDTH = 5;
ARROW_ETCH_DEPTH = 0.5;



// Check if the selected format is a "filed" medium format
IS_FILED_MEDIUM_FORMAT = Film_Format == "6x4.5 filed" ||
    Film_Format == "6x6 filed" ||
    Film_Format == "6x7 filed" ||
    Film_Format == "6x8 filed" ||
    Film_Format == "6x9 filed";

// Internal calculation based on user input, adjusted for filed formats
CALCULATED_INTERNAL_PEG_GAP = IS_FILED_MEDIUM_FORMAT ? (1 - Peg_Gap) - 1 : (1 - Peg_Gap);

$fn=100;

// Get film dimensions by calling functions from film-sizes.scad
FILM_FORMAT_HEIGHT = get_film_format_height(Film_Format);
FILM_FORMAT_WIDTH = get_film_format_width(Film_Format);
FILM_FORMAT_PEG_DISTANCE = get_film_format_peg_distance(Film_Format);

// Assert that the functions returned valid values (not undef)
assert(FILM_FORMAT_HEIGHT != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
assert(FILM_FORMAT_WIDTH != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));
assert(FILM_FORMAT_PEG_DISTANCE != undef, str("Unknown or unsupported Film_Format selected: ", Film_Format));

// Select the appropriate type name based on Film_Format and typeNameSource
// selectedTypeName = Film_Format == "custom" ? customTypeName : Film_Format; // Old logic
// selectedTypeName = typeNameSource == "Custom" ? customTypeName : Film_Format; // Previous logic
SELECTED_TYPE_NAME = Type_Name == "Custom" ? Custom_Type_Name :
    Film_Format == "35mm" ? "35MM" :
    Film_Format == "35mm filed" ? "FILED35" :
    Film_Format == "35mm full" ? "FULL35" :
    Film_Format == "half frame" ? "HALF" :
    Film_Format == "6x4.5" ? "6x4.5" :
    Film_Format == "6x4.5 filed" ? "F6x4.5" :
    Film_Format == "6x6" ? "6x6" :
    Film_Format == "6x6 filed" ? "F6x6" :
    Film_Format == "6x7" ? "6x7" :
    Film_Format == "6x7 filed" ? "F6x7" :
    Film_Format == "6x8" ? "6x8" :
    Film_Format == "6x8 filed" ? "F6x8" :
    Film_Format == "6x9" ? "6x9" :
    Film_Format == "6x9 filed" ? "F6x9" :
    Film_Format == "4x5" ? "4X5" :
    Film_Format; // Fallback to original name if not mapped

// Calculate Z offset for pegs/holes based on topOrBottom
PEG_Z_OFFSET = Top_or_Bottom == "bottom" ? OMEGA_D_CARRIER_HEIGHT / 2 : OMEGA_D_CARRIER_HEIGHT - OMEGA_D_TOP_PEG_HOLE_Z_OFFSET;

/* [Hidden] */
// Calculate the actual type name string first
// The following block defining _SELECTED_TYPE_NAME_FOR_METRICS is removed.

// Get text metrics
owner_metrics = textmetrics(text=Owner_Name, font=Fontface, size=10, halign="center", valign="center");
type_metrics = textmetrics(text=SELECTED_TYPE_NAME, font=Fontface, size=10, halign="center", valign="center");
// echo(str("Owner Name Metrics: ", owner_metrics));
// echo(str("Type Name Metrics (", SELECTED_TYPE_NAME, "): ", type_metrics));

// Define Safe Area (based on the rectangular part of base_shape)
// Rectangle Center: [-CARRIER_RECT_OFFSET, 0]
// Rectangle Size: [OMEGA_D_CARRIER_LENGTH, OMEGA_D_CARRIER_WIDTH]
safe_rect_center_x = -OMEGA_D_CARRIER_RECT_OFFSET;
safe_rect_size_x = OMEGA_D_CARRIER_LENGTH;
safe_rect_size_y = OMEGA_D_CARRIER_WIDTH;
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
       str("ERROR: Type Name '", SELECTED_TYPE_NAME, "' X dimension [", type_min_x, ", ", type_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider adjusting position."));
assert(type_min_y >= safe_min_y && type_max_y <= safe_max_y,
       str("ERROR: Type Name '", SELECTED_TYPE_NAME, "' Y dimension [", type_min_y, ", ", type_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider adjusting position."));

module base_shape() {
    color("grey") union() {
        cylinder(h=OMEGA_D_CARRIER_HEIGHT, r=OMEGA_D_CARRIER_CIRCLE_DIAMETER/2, center = true);
        translate([-OMEGA_D_CARRIER_RECT_OFFSET, 0, 0]) cuboid([OMEGA_D_CARRIER_LENGTH, OMEGA_D_CARRIER_WIDTH, OMEGA_D_CARRIER_HEIGHT], anchor = CENTER, rounding=OMEGA_D_CARRIER_FILLET, edges=[[0,0,0,0], [0,0,0,0], [1,1,1,1]]);
    }
}

module alignment_screw_holes(is_dent = false, dent_depth = 1) {
    // hole_height = is_dent ? dent_depth : OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION; // Removed, height calculated in cylinder call
    // For dents, place their base at the bottom surface. For through-holes, center them vertically.
    z_pos = is_dent ? (-OMEGA_D_CARRIER_HEIGHT / 2) - 0.1 : 0;
    // use_center = true; // Removed, centering determined by is_dent
    hole_radius = is_dent ? OMEGA_D_ALIGNMENT_SCREW_DIAMETER/2 + 0.25 : OMEGA_D_ALIGNMENT_SCREW_DIAMETER/2;
    // Make the dent cylinder slightly taller to ensure subtraction // Removed effective_hole_height logic
    // effective_hole_height = is_dent ? dent_depth + 0.1 : hole_height;

    hole_h = is_dent ? dent_depth : OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION;
    use_center = !is_dent; // Center only if it's a through-hole

    // color("red")
    translate([OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
    // color("red")
    translate([-OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
    // color("red")
    translate([OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, -OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
    // color("red")
    translate([-OMEGA_D_ALIGNMENT_SCREW_DISTANCE_Y/2, -OMEGA_D_ALIGNMENT_SCREW_DISTANCE_X/2, z_pos])
        cylinder(h=hole_h, r=hole_radius, center = use_center);
}

module registration_holes() {
    color("red") translate([OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2, 0]) cuboid([OMEGA_D_REG_HOLE_DIAMETER, OMEGA_D_REG_HOLE_DIAMETER + OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION, OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
    color("red") translate([-OMEGA_D_REG_HOLE_DISTANCE/2 - OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2, 0]) cuboid([OMEGA_D_REG_HOLE_DIAMETER, OMEGA_D_REG_HOLE_DIAMETER + OMEGA_D_REG_HOLE_SLOT_LENGTH_EXTENSION, OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION], anchor = CENTER);
    color("red") translate([OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_CYL_Y_OFFSET, 0]) cylinder(h=OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=OMEGA_D_REG_HOLE_DIAMETER/2, center = true);
    color("red") translate([-OMEGA_D_REG_HOLE_DISTANCE/2 - OMEGA_D_REG_HOLE_DIAMETER/2, -OMEGA_D_REG_HOLE_DISTANCE/2 + OMEGA_D_REG_HOLE_CYL_Y_OFFSET, 0]) cylinder(h=OMEGA_D_CARRIER_HEIGHT + CUT_THROUGH_EXTENSION, r=OMEGA_D_REG_HOLE_DIAMETER/2, center = true);
}

// Module to create a left-pointing arrow shape for etching
module arrow_etch(etch_depth = 0.5, length = 5, width = 3) {
    // Centered around [0,0] for easier placement later
    // Tip at [-length/2, 0], Base at [length/2, +/- width/2]
    translate([-10 ,0, .5]) // Position Z base at the top surface
    linear_extrude(height = etch_depth + 0.1) // Extrude upwards
        polygon(points=[ [-length/2, 0], [length/2, width/2], [length/2, -width/2] ]);
}

// Calculate values needed for generic modules
// Film Opening Dimensions
effective_orientation = (Film_Format == "4x5") ? "vertical" : Orientation;
calculated_opening_height = effective_orientation == "vertical" ? FILM_FORMAT_HEIGHT : FILM_FORMAT_WIDTH;
calculated_opening_width = effective_orientation == "vertical" ? FILM_FORMAT_WIDTH : FILM_FORMAT_HEIGHT;
adjusted_opening_height = calculated_opening_height + Adjust_Film_Height;
adjusted_opening_width = calculated_opening_width + Adjust_Film_Width;

// Peg Feature Dimensions
peg_z_offset_calc = Top_or_Bottom == "top" ? PEG_Z_OFFSET : OMEGA_D_CARRIER_HEIGHT / 2;
// Calculate peg positions based on Orientation and Film Format
peg_pos_x_calc = effective_orientation == "vertical" ?
            (FILM_FORMAT_WIDTH/2 + OMEGA_D_PEG_DIAMETER/2) :
            (FILM_FORMAT_PEG_DISTANCE/2 + OMEGA_D_PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP);
peg_pos_y_calc = effective_orientation == "vertical" ?
            (FILM_FORMAT_PEG_DISTANCE/2 + OMEGA_D_PEG_DIAMETER/2 - CALCULATED_INTERNAL_PEG_GAP) :
            (FILM_FORMAT_WIDTH/2 + OMEGA_D_PEG_DIAMETER/2);

// Text Etch Positions & Parameters
owner_etch_bottom_margin = 5;
owner_etch_bottom_position = safe_max_y - owner_etch_bottom_margin;
// Position vector for translate() before calling text_etch for Owner Name
// Adjust Z to position the *base* of the extrusion correctly for subtraction
owner_etch_z_pos = OMEGA_D_CARRIER_HEIGHT / 2 - (TEXT_ETCH_DEPTH + 0.1);
owner_etch_pos = [owner_etch_bottom_position, -95, owner_etch_z_pos];
owner_etch_rot = [0, 0, 270]; // Rotation vector for rotate() before calling text_etch

type_etch_top_margin = 5;
type_etch_top_position = safe_min_y + type_etch_top_margin;
// Position vector for translate() before calling text_etch for Type Name
// Adjust Z to position the *base* of the extrusion correctly for subtraction
type_etch_z_pos = OMEGA_D_CARRIER_HEIGHT / 2 - (TEXT_ETCH_DEPTH + 0.1);
type_etch_pos = [type_etch_top_position, -95, type_etch_z_pos];
type_etch_rot = [0, 0, 270]; // Rotation vector for rotate() before calling text_etch


// Main logic
if (Top_or_Bottom == "bottom") {
    union() {
        difference() {
            base_shape();
            // Use generic film_opening
            film_opening(
                opening_height = adjusted_opening_height,
                opening_width = adjusted_opening_width,
                carrier_height = OMEGA_D_CARRIER_HEIGHT,
                cut_through_extension = CUT_THROUGH_EXTENSION,
                frame_fillet = OMEGA_D_FRAME_FILLET
            );
            registration_holes();
            alignment_screw_holes();
            if (Enable_Owner_Name_Etch) {
                // Use generic text_etch for owner name, applying transforms before the call
                rotate(owner_etch_rot) translate(owner_etch_pos)
                    text_etch(
                        text_string = Owner_Name,
                        font = Fontface,
                        size = Font_Size,
                        etch_depth = TEXT_ETCH_DEPTH, // Pass calculated depth
                        halign = "right",
                        valign = "top"
                    );
            }
            if (Enable_Type_Name_Etch) {
                // Use generic text_etch for type name, applying transforms before the call
                rotate(type_etch_rot) translate(type_etch_pos)
                    text_etch(
                        text_string = SELECTED_TYPE_NAME,
                        font = Fontface,
                        size = Font_Size,
                        etch_depth = TEXT_ETCH_DEPTH, // Pass calculated depth
                        halign = "left",
                        valign = "top"
                    );
            }

            // Add arrow etch for 6x6 formats
            if (Film_Format == "6x6" || Film_Format == "6x6 filed") {
                arrowOffset = 5; // Distance from opening edge to arrow tip
                if (Orientation == "vertical") {
                    // Arrow points right (-->), placed to the right of the opening
                    currentOpeningWidth = FILM_FORMAT_WIDTH; // Width along X
                    arrowPosX = 0; // Center X of arrow
                    arrowPosY = currentOpeningWidth / 2 + arrowOffset + ARROW_LENGTH / 2;
                    translate([arrowPosX + 10, -arrowPosY , 0])
                        arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                } else { // Orientation == "horizontal"
                    // Arrow points down (v), placed below the opening
                    currentOpeningHeight = FILM_FORMAT_HEIGHT; // Height along Y
                    arrowPosX = 0; // Center X
                    arrowPosY = -currentOpeningHeight / 2 - arrowOffset - ARROW_LENGTH / 2; // Center Y of arrow
                    translate([arrowPosX, arrowPosY, 0])
                    rotate([0, 0, 90]) // Point down
                        arrow_etch(etch_depth=ARROW_ETCH_DEPTH, length=ARROW_LENGTH, width=ARROW_WIDTH);
                }
            }
        }
        // Use generic pegs_feature for pegs
        pegs_feature(
            is_hole = false,
            peg_diameter = OMEGA_D_PEG_DIAMETER,
            peg_height = OMEGA_D_PEG_HEIGHT,
            peg_pos_x = peg_pos_x_calc,
            peg_pos_y = peg_pos_y_calc,
            z_offset = peg_z_offset_calc // Use calculated z_offset for bottom
        );
    }
} else if (Top_or_Bottom == "frameAndPegTestBottom" || Top_or_Bottom == "frameAndPegTestTop") {
    // Create a smaller base for the test piece, slightly larger than the film opening + pegs
    testPiecePadding = 10; // Add padding around

    // Test piece dimensions based on max extent of pegs
    testPieceWidth = 2 * peg_pos_y_calc + testPiecePadding * 2;
    testPieceHeight = 2 * peg_pos_x_calc + testPiecePadding * 2;
    // Z offset for pegs/holes in test frames should be centered
    test_peg_z_offset = OMEGA_D_CARRIER_HEIGHT / 2;

    difference() {
        // Center the test piece
        cuboid([testPieceHeight, testPieceWidth, OMEGA_D_CARRIER_HEIGHT], anchor = CENTER);
        // Use generic film_opening
        film_opening(
            opening_height = adjusted_opening_height,
            opening_width = adjusted_opening_width,
            carrier_height = OMEGA_D_CARRIER_HEIGHT,
            cut_through_extension = CUT_THROUGH_EXTENSION,
            frame_fillet = OMEGA_D_FRAME_FILLET
        );
        // Subtract holes if it's the top test piece
        if (Top_or_Bottom == "frameAndPegTestTop") {
            // Use generic pegs_feature for holes
             pegs_feature(
                is_hole = true,
                peg_diameter = OMEGA_D_PEG_DIAMETER,
                peg_height = OMEGA_D_PEG_HEIGHT,
                peg_pos_x = peg_pos_x_calc,
                peg_pos_y = peg_pos_y_calc,
                z_offset = test_peg_z_offset // Correct Z offset for test frame
             );
        }
    }
    // Add pegs if it's the bottom test piece
    if (Top_or_Bottom == "frameAndPegTestBottom") {
        // Use generic pegs_feature for pegs
         pegs_feature(
            is_hole = false,
            peg_diameter = OMEGA_D_PEG_DIAMETER,
            peg_height = OMEGA_D_PEG_HEIGHT,
            peg_pos_x = peg_pos_x_calc,
            peg_pos_y = peg_pos_y_calc,
            z_offset = test_peg_z_offset // Correct Z offset for test frame
         );
    }
} else { // topOrBottom == "top"
    difference() {
        base_shape();
        // Use generic film_opening
        film_opening(
            opening_height = adjusted_opening_height,
            opening_width = adjusted_opening_width,
            carrier_height = OMEGA_D_CARRIER_HEIGHT,
            cut_through_extension = CUT_THROUGH_EXTENSION,
            frame_fillet = OMEGA_D_FRAME_FILLET
        );
        registration_holes();
        // Use generic pegs_feature for holes
        pegs_feature(
            is_hole = true,
            peg_diameter = OMEGA_D_PEG_DIAMETER,
            peg_height = OMEGA_D_PEG_HEIGHT,
            peg_pos_x = peg_pos_x_calc,
            peg_pos_y = peg_pos_y_calc,
            z_offset = peg_z_offset_calc // Use calculated z_offset for top
        );
        alignment_screw_holes(is_dent = true, dent_depth = 1); // Top part gets 1mm dents
        if (Enable_Owner_Name_Etch) {
            // Use generic text_etch for owner name
            rotate(owner_etch_rot) translate(owner_etch_pos)
                text_etch(
                    text_string = Owner_Name,
                    font = Fontface,
                    size = Font_Size,
                    etch_depth = owner_etch_depth,
                    halign = "right",
                    valign = "top"
                );
        }
        if (Enable_Type_Name_Etch) {
             // Use generic text_etch for type name
             rotate(type_etch_rot) translate(type_etch_pos)
                text_etch(
                    text_string = SELECTED_TYPE_NAME,
                    font = Fontface,
                    size = Font_Size,
                    etch_depth = type_etch_depth,
                    halign = "left",
                    valign = "top"
                );
        }
    }
}
