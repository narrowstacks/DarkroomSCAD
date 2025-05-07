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
// Calculate values needed for generic modules
// Film Opening Dimensions
effective_orientation = (Film_Format == "4x5") ? "vertical" : Orientation;
calculated_opening_height = effective_orientation == "vertical" ? FILM_FORMAT_HEIGHT : FILM_FORMAT_WIDTH;
calculated_opening_width = effective_orientation == "vertical" ? FILM_FORMAT_WIDTH : FILM_FORMAT_HEIGHT;

opening_height_actual = Orientation == "vertical" ? calculated_opening_height : calculated_opening_width;
opening_width_actual = Orientation == "vertical" ? calculated_opening_width : calculated_opening_height;

// Carrier Dimensions
carrierHeight = 2;
carrierDiameter = 215;

// Peg Dimensions
pegDiameter = 10;
pegDistance = 100;