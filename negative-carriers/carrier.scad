// !! READ README.md BEFORE USING !!

// BOSL2 is included ONCE here at the entry point. OpenSCAD re-parses every
// `include`d file (no dedup), and BOSL2/std.scad is ~80k lines — including it
// in each sub-file cost ~1.7s of redundant parsing per render. Sub-files under
// src/ rely on this entry-point include (or the outline.scad wrapper in the web
// project's gen-carrier-outlines), so they no longer include BOSL2 themselves.
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
// Film size definitions
include <src/common/film-sizes.scad>
// Common features shared by all carriers
include <src/common/carrier-features.scad>
// Omega style alignment board
include <src/common/omega-d-alignment-board.scad>
// LPL Saunders style alignment board
include <src/common/lpl-saunders-alignment-board.scad>
// Text etching functionality
include <src/common/text-etching.scad>

// Carrier configuration system
include <src/carrier-configs.scad>
// Universal carrier assembly system
include <src/common/universal-carrier-assembly.scad>
// Base shape generators
include <src/omega-d-base-shape.scad>
include <src/omega-d-glass-base-shape.scad>
include <src/lpl-saunders-base-shape.scad>
include <src/beseler-23c-base-shape.scad>
include <src/beseler-45-base-shape.scad>
include <src/test-frame-base-shape.scad>

/* [Carrier Type] */
// "omega-d-glass" is a single-piece Omega-D carrier with a pocket for a 4x5 glass plate (see the Glass Plate Carrier section)
Carrier_Type = "omega-d"; // ["omega-d", "omega-d-glass", "lpl-saunders-45xx", "beseler-23c", "beseler-45", "frameAndPegTest"]
// Orientation of the film in the carrier. A 4x5 sheet is locked to horizontal (long edge across the carrier) except on the Omega-D carriers, where the alignment board and its screw holes turn with it.
Orientation = "vertical"; // ["vertical", "horizontal"]
/* [Film Format Selection] */
Film_Format = "35mm"; // ["35mm", "35mm filed", "half frame", "half frame filed", "6x4.5", "6x4.5 filed", "6x6", "6x6 filed", "6x7", "6x7 filed", "6x8", "6x8 filed", "6x9", "6x9 filed", "4x5", "custom"]
// Consecutive frames the opening spans (one exposure prints them side by side). Ignored for 4x5 and custom.
Frame_Count = 1; // [1, 2, 3, 4]

/* [Carrier Options] */
// Top or bottom of the carrier
Top_or_Bottom = "bottom"; // ["top", "bottom"]
// Include the alignment board?
Alignment_Board = true; // [true, false]
Alignment_Board_Type = "omega"; // ["omega", "lpl-saunders", "beseler-23c"]
// Flip bottom carriers to printable orientation (rotate 180° on X-axis)
Flip_Bottom_For_Printing = true; // [true, false]

// Printed or heat-set pegs? Heat set pegs required when including alignment board.
Printed_or_Heat_Set_Pegs = "heat_set"; // ["printed", "heat_set"]
// Heat-set pegs only: the machine screw (e.g. M2x4 socket head) that threads into the bottom carrier and whose head registers the top. Sizes both holes.
Heat_Set_Screw_Size = "M2"; // ["M2", "M2.5", "M3"]
// Heat-set pegs only: the screw's head style. The top carrier's hole clears the head (its diameter is the standard max for the size), so it must match the screws you actually use. "custom" uses Heat_Set_Screw_Head_Diameter.
Heat_Set_Screw_Head = "socket"; // ["socket": Socket cap (ISO 4762), "button": Button (ISO 7380), "pan": Pan (ISO 7045), "cheese": Cheese (ISO 1207), "custom": Custom diameter]
// Heat-set pegs only: the measured head diameter (mm, calipers across the head) when Heat_Set_Screw_Head is "custom". The top hole adds 0.5mm clearance.
Heat_Set_Screw_Head_Diameter = 3.8;


/* [Custom Film Format] */
// Actual film stock width (for peg positioning)
Custom_Film_Width = 37;
// Actual film stock height (for film handling)
Custom_Film_Height = 37;
// Film opening width (the visible/cropped area)
Custom_Opening_Width = 24;
// Film opening height (the visible/cropped area)
Custom_Opening_Height = 36;

/* [Glass Plate Carrier] */
// Only used by Carrier_Type "omega-d-glass": one 4mm slab (two carrier halves' worth) with a pocket on top that holds a 4x5 glass plate, no film pegs, and screw holes for a separately printed alignment board (export it with _Render_Alignment_Board_Only). Set Film_Format to "4x5" for the matching opening.
// Plate size across the carrier, the short edge (mm)
Glass_Plate_Width = 101;
// Plate size along the carrier width, the long edge (mm)
Glass_Plate_Length = 126;
// Thickest plate the pocket must take (mm); 4x5 dry plates run 1.8-2.0
Glass_Plate_Thickness = 2;
// Clearance between the plate and the pocket wall, per side (mm)
Glass_Plate_Side_Play = 0.5;
// Extra pocket depth beyond the plate thickness (mm), so the plate never stands proud
Glass_Plate_Depth_Play = 0.2;
// Diameter of the circular finger notch at a pocket corner that lets you lift the plate out (0 = none)
Glass_Notch_Diameter = 16;
// Pocket corner that gets the finger notch ("handle" = the -X handle side)
Glass_Notch_Corner = "handle-lower"; // ["handle-lower", "handle-upper", "far-lower", "far-upper", "none"]
// Material left under the finger notch (mm); 0 cuts it through
Glass_Notch_Floor = 0.6;
// How far the notch reaches under the plate edge (mm) for a nail to hook it; keep below the rim between pocket and opening (3.5mm for 4x5)
Glass_Notch_Reach = 2.5;
// Counterbore depth (mm) for the screw heads in the separately printed alignment board, cut from the face the screws go in from, so the heads sit mostly inside the 1.7mm board (0 = none). Sized for the peg screw head + 0.5mm. Leave at least ~0.7mm of board under the head.
Glass_Board_Screw_Counterbore = 1; // [0:0.1:1.2]

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
Fontface = "Lucida Console";
// Font size for etchings
Font_Size = 10;
// Depth for etching
TEXT_ETCH_DEPTH = 1;

/* [Text Position Offsets] */
// Adjust text location relative to carrier defaults (mm)
Owner_Text_X_Offset = 0; // negative=left, positive=right
Owner_Text_Y_Offset = 0; // negative=down, positive=up
Type_Text_X_Offset = 0; // negative=left, positive=right
Type_Text_Y_Offset = 0; // negative=down, positive=up

/* [Multi-Material Text] */
// Render text as separate parts for multi-material printing
Text_As_Separate_Parts = false; // [true, false]
// Desired slicer layer height (mm)
Layer_Height_mm = 0.27;
// Number of layers for text thickness (multiple of layer height)
Text_Layer_Multiple = 1;

/* [Output Selector] */
// Select which part to render when exporting STLs
_WhichPart = "All"; // ["All", "Base", "OwnerText", "TypeText"]
// Render ONLY the standalone alignment board (of Alignment_Board_Type; the glass
// carrier's screw-on board for omega-d-glass) as its own printable part,
// independent of the carrier. Use it to export the board separately when it
// isn't fused into the carrier. NOT in a [Hidden] group on purpose: OpenSCAD
// parameter sets (-p/-P, which the web app uses) skip Hidden variables.
_Render_Alignment_Board_Only = false; // [true, false]

/* [Adjustments] */
// Leave at 0 for default gap. Measured in mm. Add positive values to increase the gap between pegs and film edge, subtract (use negative values) to decrease it. Default 0 allows for little wiggle.
Peg_Gap = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film width, subtract (use negative values) to decrease it.
Adjust_Film_Width = 0;
// Leave at 0 for no adjustment. Measured in mm. Add positive values to increase the film height, subtract (use negative values) to decrease it.
Adjust_Film_Height = 0;
// Heat-set pegs only. Added to the diameter (mm) of the bottom carrier's screw holes, which the screw threads into (default M2: 1.9mm). Use +0.1..0.2 if the screw won't start, negative if it spins freely.
Heat_Set_Thread_Hole_Adjust = 0;
// Heat-set pegs only. Added to the diameter (mm) of the top carrier's screw-head clearance holes (head diameter + 0.5; M2 socket cap: 4.3mm).
Heat_Set_Head_Hole_Adjust = 0;

/* [Render Quality] */
// Use "preview" for faster F5 preview, "final" for smooth F6 renders
Render_Quality = "final"; // ["final", "preview"]

/* [Hidden] */
// Variable resolution: 32 for preview speed, 100 for final quality
$fn = (Render_Quality == "final") ? 100 : 32;

// ============================================================================
// MAIN CARRIER GENERATION LOGIC
// ============================================================================

// Validate the selected carrier type
validate_carrier_config(Carrier_Type);

// 4x5 honours the Orientation toggle only on the carriers that can take the sheet turned (the Omega-D ones); elsewhere it is locked to horizontal
effective_orientation = get_effective_orientation(Film_Format, Orientation, Carrier_Type);

// Get configuration for the selected carrier type (now minimal; base geometry lives in carrier files)
// The glass carrier's config carries its pocket/notch parameters from the
// customizer; its pocket turns with the sheet.
carrier_config = (Carrier_Type == "omega-d-glass")
    ? omega_d_glass_config(
        Glass_Plate_Width, Glass_Plate_Length, Glass_Plate_Thickness,
        Glass_Plate_Side_Play, Glass_Plate_Depth_Play,
        Glass_Notch_Diameter, Glass_Notch_Corner, Glass_Notch_Floor, Glass_Notch_Reach,
        effective_orientation
    )
    : get_carrier_config(Carrier_Type);

// Generate carrier type name for etching (the glass carrier says so, e.g. "4X5 GLASS")
_FORMAT_TYPE_NAME = get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format, Frame_Count);
SELECTED_TYPE_NAME = (Carrier_Type == "omega-d-glass" && Type_Name != "Custom")
    ? str(_FORMAT_TYPE_NAME, " GLASS")
    : _FORMAT_TYPE_NAME;

// ============================================================================
// UNIFIED FILM OPENING AND PEG CALCULATIONS
// ============================================================================

// Calculate film opening dimensions once for all carriers
adjusted_opening_height = get_custom_aware_opening_height(Film_Format, Orientation, Adjust_Film_Height, Custom_Film_Height, Custom_Film_Width, Custom_Opening_Height, Frame_Count, Carrier_Type);
adjusted_opening_width = get_custom_aware_opening_width(Film_Format, Orientation, Adjust_Film_Width, Custom_Film_Height, Custom_Film_Width, Custom_Opening_Width, Frame_Count, Carrier_Type);

// Get peg diameter from config (index varies by carrier type)
peg_diameter = (Carrier_Type == "frameAndPegTest") ? carrier_config[1] : DEFAULT_PEG_DIAMETER;

// Calculate peg positions once for all carriers using unified approach
peg_positions = calculate_unified_peg_positions(
    film_format_str=Film_Format,
    orientation_str=Orientation,
    peg_diameter=peg_diameter,
    peg_gap_val=Peg_Gap,
    adjust_film_width_val=Adjust_Film_Width,
    adjust_film_height_val=Adjust_Film_Height,
    positioning_style="omega", // Use omega style for all carriers for consistency
    film_peg_distance=get_film_format_peg_distance(Film_Format, Custom_Film_Width),
    carrier_type=Carrier_Type
);

peg_pos_x_calc = peg_positions[0];
peg_pos_y_calc = peg_positions[1];

// Heat-set peg screw holes, resolved once from the customizer settings
// (bottom: thread-forming hole; top: head clearance). Ignored for printed pegs.
heat_set_thread_hole_dia_calc = heat_set_thread_hole_dia(Heat_Set_Screw_Size, Heat_Set_Thread_Hole_Adjust);
heat_set_head_hole_dia_calc = heat_set_head_hole_dia(Heat_Set_Screw_Size, Heat_Set_Screw_Head, Heat_Set_Screw_Head_Diameter, Heat_Set_Head_Hole_Adjust);

// ============================================================================
// CARRIER DISPATCH LOGIC
// ============================================================================

// Helper module to avoid repeating 27 parameters for each carrier type
module dispatch_to_universal_assembly(
    _top_or_bottom = Top_or_Bottom,
    _peg_style = Printed_or_Heat_Set_Pegs,
    _alignment_board = Alignment_Board,
    _alignment_board_type = Alignment_Board_Type,
    _flip_bottom = Flip_Bottom_For_Printing,
    _enable_owner_etch = Enable_Owner_Name_Etch,
    _owner_name = Owner_Name,
    _enable_type_etch = Enable_Type_Name_Etch,
    _type_name = SELECTED_TYPE_NAME,
    _text_as_separate = Text_As_Separate_Parts
) {
    universal_carrier_assembly(
        config=carrier_config,
        carrier_type=Carrier_Type,
        top_or_bottom=_top_or_bottom,
        printed_or_heat_set_pegs=_peg_style,
        heat_set_thread_hole_dia=heat_set_thread_hole_dia_calc,
        heat_set_head_hole_dia=heat_set_head_hole_dia_calc,
        alignment_board=_alignment_board,
        alignment_board_type=_alignment_board_type,
        flip_bottom_for_printing=_flip_bottom,
        enable_owner_name_etch=_enable_owner_etch,
        owner_name=_owner_name,
        enable_type_name_etch=_enable_type_etch,
        selected_type_name=_type_name,
        fontface=Fontface,
        font_size=Font_Size,
        text_etch_depth=TEXT_ETCH_DEPTH,
        text_as_separate_parts=_text_as_separate,
        layer_height_mm=Layer_Height_mm,
        text_layer_multiple=Text_Layer_Multiple,
        which_part=_WhichPart,
        opening_height=adjusted_opening_height,
        opening_width=adjusted_opening_width,
        peg_pos_x=peg_pos_x_calc,
        peg_pos_y=peg_pos_y_calc,
        film_format_for_arrows=Film_Format,
        orientation_for_arrows=Orientation,
        owner_text_offset=[Owner_Text_X_Offset, Owner_Text_Y_Offset],
        type_text_offset=[Type_Text_X_Offset, Type_Text_Y_Offset]
    );
}

// Dispatch to appropriate carrier assembly
if (_Render_Alignment_Board_Only) {
    // Standalone alignment board: render just the board so it can be printed
    // separately (e.g. when using printed pegs, where it can't be fused).
    // Film_Format (and, for 4x5, the effective orientation) is passed so the omega
    // board gets the widened board opening, turned as when fused.
    if (Carrier_Type == "omega-d-glass") {
        // The glass carrier's board is screwed on: cut its clearance holes to match,
        // counterbored on the outer face for the screw heads.
        omega_d_glass_alignment_board(
            Film_Format, effective_orientation,
            heat_set_clearance_hole_dia(Heat_Set_Screw_Size), heat_set_head_hole_dia_calc, Glass_Board_Screw_Counterbore);
    } else {
        // Screwed on through the carrier's footprint holes: give the board the
        // matching pilot holes, at the same thread-forming size as the peg holes.
        instantiate_alignment_board_by_type(Alignment_Board_Type, Film_Format, effective_orientation, pilot_holes=true, pilot_dia=heat_set_thread_hole_dia_calc);
    }
} else if (Carrier_Type == "omega-d" || Carrier_Type == "lpl-saunders-45xx" || Carrier_Type == "beseler-23c") {
    // Standard carriers use all user-specified options
    dispatch_to_universal_assembly();
} else if (Carrier_Type == "omega-d-glass") {
    // Glass plate carrier: a single piece (there is no top half), no film pegs
    // (the pocket locates the plate), the alignment board is never fused (it is
    // screwed on, so the carrier only gets the screw footprint), and it is not
    // flipped for printing: the pocket must face up to print without supports.
    if (Top_or_Bottom == "top")
        echo("Glass plate carrier is a single piece; Top_or_Bottom is ignored.");
    if (Alignment_Board)
        echo("Glass plate carrier: alignment board is screwed on, not fused; export it separately with _Render_Alignment_Board_Only.");
    dispatch_to_universal_assembly(
        _top_or_bottom="bottom",
        _peg_style="none",
        _alignment_board=false,
        _alignment_board_type="omega",
        _flip_bottom=false
    );
} else if (Carrier_Type == "beseler-45") {
    // Beseler 45: no alignment board — the fixed corner pegs align it in the enlarger.
    dispatch_to_universal_assembly(
        _alignment_board=false,
        _alignment_board_type="none"
    );
} else if (is_test_frame_type(Carrier_Type)) {
    // Test frames have simplified options (no alignment board, no text)
    dispatch_to_universal_assembly(
        _alignment_board=false,
        _alignment_board_type="none",
        _flip_bottom=false,
        _enable_owner_etch=false,
        _owner_name="",
        _enable_type_etch=false,
        _type_name="",
        _text_as_separate=false
    );
} else {
    assert(false, str("CARRIER TYPE ERROR: Unknown carrier type '", Carrier_Type, "'. Supported types: ", get_supported_carrier_types()));
}
