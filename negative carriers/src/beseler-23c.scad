// !! READ README.md BEFORE USING !!

include <BOSL2/std.scad>
include <film-sizes.scad> // Include the film size definitions
include <common-carrier-features.scad> // Include common carrier features

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

/* [Film Opening Parameters] */
// Extra distance for the film opening cut to ensure it goes through the material.
Film_Opening_Cut_Through_Extension = 1; // [mm]
// Fillet radius for the film opening edges.
Film_Opening_Frame_Fillet = 0.5; // [mm]

/* [Carrier Type Name Source] */
// Enable or disable the type name etching
Enable_Type_Name_Etch = true; // [true, false]
Type_Name = "Carrier Type"; // ["Carrier Type", "Custom"]
// Custom type name, if Type Name is "custom"
Custom_Type_Name = "CUSTOM";

/* [Adjustments] */
// Leave at 0 for default gap. Measured in mm. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.

Peg_Gap = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film width, subtract (use negative values) to decrease it.
Adjust_Film_Width = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film height, subtract (use negative values) to decrease it.
Adjust_Film_Height = 0;

/* [Carrier Etchings] */
// Font to use for the etchings
Fontface = "Futura";
// Font size for etchings
Font_Size = 10;

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

// Determine actual opening dimensions based on orientation
opening_width_raw = get_film_format_width(Film_Format) + Adjust_Film_Width;
opening_height_raw = get_film_format_height(Film_Format) + Adjust_Film_Height;

opening_width_actual = Orientation == "vertical" ? opening_width_raw : opening_height_raw;
opening_height_actual = Orientation == "vertical" ? opening_height_raw : opening_width_raw;

$fn=200;

module alignment_circle() {
    // Major radius R = (OuterD/2 + InnerD/2) / 2 = (120/2 + 110/2) / 2 = (60 + 55) / 2 = 57.5
    // Minor radius r = (OuterD/2 - InnerD/2) / 2 = (60 - 55) / 2 = 2.5
    // Height = 2 * r = 5, which matches alignmentCircleThickness
    color("red") torus(r_maj = alignmentCircleOuterDiameter/4 + alignmentCircleInnerDiameter/4, 
                       r_min = alignmentCircleOuterDiameter/4 - alignmentCircleInnerDiameter/4, 
                       anchor=CENTER);
}

module handle() {
    translate([0, carrierDiameter/2, 0]) color("grey") cuboid([handleWidth, handleLength*1.5, carrierHeight], anchor = CENTER, rounding = .5);
}

module base_shape() {
    color("grey") union() {
        cyl(h=carrierHeight, r=carrierDiameter/2, center = true, rounding = .5);
    }
}

// Main logic
if (Top_or_Bottom == "bottom") {
    union() {
        difference() {
            base_shape();
            film_opening(
                opening_height = opening_height_actual,
                opening_width = opening_width_actual,
                carrier_height = carrierHeight,
                cut_through_extension = Film_Opening_Cut_Through_Extension,
                frame_fillet = Film_Opening_Frame_Fillet
            );
            
        }
        difference() {
            translate([0, 0, carrierHeight/2]) alignment_circle();
            translate([0, 0, -2]) base_shape();
            }

        // pegs_feature();
        
        handle();
    }
} else { // topOrBottom == "top"
    difference() {
        base_shape();
        film_opening(
            opening_height = opening_height_actual,
            opening_width = opening_width_actual,
            carrier_height = carrierHeight,
            cut_through_extension = Film_Opening_Cut_Through_Extension,
            frame_fillet = Film_Opening_Frame_Fillet
        );
        // pegs_feature(is_hole = true);
    }
    handle();
}
