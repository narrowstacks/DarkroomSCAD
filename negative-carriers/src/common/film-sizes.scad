/* [Hidden] */
// Actual film stock widths across the strip / sheet (mm).
FILM_135_STOCK_WIDTH = 35;      // ISO 1007: 34.98 +/-0.03
FILM_120_STOCK_WIDTH = 61.5;    // ISO 732: 61.5 (-0.5/+0)
FILM_4X5_STOCK_WIDTH = 101.6;   // nominal 4in; cut sheets run ~100.5-101.5

// Peg distance = stock width + 2 * (PEG_DISTANCE_BIAS + FILM_EDGE_CLEARANCE).
// calculate_internal_peg_gap (carrier-features.scad) subtracts the 1mm bias
// back per side, so the pegs' inner faces land FILM_EDGE_CLEARANCE outside the
// film edge (+ Peg_Gap). The clearance equals PEG_HOLE_TOLERANCE so the top
// piece's oversized peg hole also clears the film. The 120 and 4x5 values used
// to omit the bias (62 / 102), which put the pegs 1mm inside the film per side.
PEG_DISTANCE_BIAS = 1;
FILM_EDGE_CLEARANCE = 0.25;
_PEG_DISTANCE_PAD = 2 * (PEG_DISTANCE_BIAS + FILM_EDGE_CLEARANCE); // 2.5

// Film stock physical dimensions (full film width including perforations/edges)
thirtyFiveFullHeight = FILM_135_STOCK_WIDTH + _PEG_DISTANCE_PAD;    // 37.5
thirtyFiveStandardWidth=24;
mediumFormatFullHeight = FILM_120_STOCK_WIDTH + _PEG_DISTANCE_PAD;  // 64
mediumFormatStandardHeight = 56;
mediumFormatFiledHeight = 58;
fourByFiveFullWidth = FILM_4X5_STOCK_WIDTH + _PEG_DISTANCE_PAD;     // 104.1
fourByFiveFullHeight = 127;     // 4x5 sheet film height

// Custom film format defaults
customFilmFormatHeight = 37;
customFilmFormatWidth = 37;
customFilmFormatPegDistance = 37;

// Frame pitch along the strip (image length + inter-frame gap), i.e. the
// center-to-center distance of consecutive frames. Multi-frame openings
// (Frame_Count > 1) grow by one pitch per extra frame. Filed variants share
// the unfiled pitch: filing reveals rebate, it doesn't move the frames.
FRAME_PITCH_135 = 38;               // 8 perforations x 4.75mm
FRAME_PITCH_HALF_FRAME = 19;        // 4 perforations
FRAME_GAP_120 = 3;                  // typical inter-frame gap on 120 (camera dependent, ~2-4mm)

// Film format lookup table
// Each entry: [format_name, height, width, peg_distance, type_name, frame_pitch]
// - height: opening height (frame length direction)
// - width: opening width (film strip width direction)
// - peg_distance: distance for alignment pegs (based on film stock width)
// - type_name: label for etching
// - frame_pitch: center-to-center frame spacing along the strip (0 = single
//   frame only; 4x5 sheets have no "next frame")
FILM_FORMATS = [
    // 35mm formats
    ["35mm",        36,   thirtyFiveStandardWidth,  thirtyFiveFullHeight, "35MM", FRAME_PITCH_135],      // Standard 35mm frame (exact 36x24 image; was 37 by accident of reusing the strip-width constant)
    ["35mm filed",  40,   28,  thirtyFiveFullHeight, "FILED35", FRAME_PITCH_135],   // Filed/enlarged opening
    ["half frame",  18,   thirtyFiveStandardWidth,  thirtyFiveFullHeight, "HALF", FRAME_PITCH_HALF_FRAME],      // Half frame (portrait orientation)
    ["half frame filed", 21, 28, thirtyFiveFullHeight, "FILEDHALF", FRAME_PITCH_HALF_FRAME], // Filed half frame (19mm pitch + 2, same rebate reveal as 35mm filed)

    // Medium format (120/220) - height is frame length, width is 56mm (or 58 filed)
    ["6x4.5",       41.5, mediumFormatStandardHeight,  mediumFormatFullHeight, "6x4.5", 41.5 + FRAME_GAP_120],
    ["6x4.5 filed", 43.5, mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x4.5", 41.5 + FRAME_GAP_120],
    ["6x6",         mediumFormatStandardHeight,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x6", mediumFormatStandardHeight + FRAME_GAP_120],
    ["6x6 filed",   mediumFormatFiledHeight,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x6", mediumFormatStandardHeight + FRAME_GAP_120],
    ["6x7",         70,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x7", 70 + FRAME_GAP_120],
    ["6x7 filed",   72,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x7", 70 + FRAME_GAP_120],
    ["6x8",         77,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x8", 77 + FRAME_GAP_120],
    ["6x8 filed",   79,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x8", 77 + FRAME_GAP_120],
    ["6x9",         84,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x9", 84 + FRAME_GAP_120],
    ["6x9 filed",   86,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x9", 84 + FRAME_GAP_120],

    // Large format
    ["4x5",         120,  95,  fourByFiveFullWidth, "4X5", 0],
];

// Index constants for FILM_FORMATS table
_FF_NAME = 0;
_FF_HEIGHT = 1;
_FF_WIDTH = 2;
_FF_PEG_DIST = 3;
_FF_TYPE_NAME = 4;
_FF_FRAME_PITCH = 5;

// Core lookup function - returns the format entry or undef if not found
function _find_film_format(format) =
    let(matches = [for (f = FILM_FORMATS) if (f[_FF_NAME] == format) f])
    len(matches) > 0 ? matches[0] : undef;

// Unified function to get all film format dimensions
// Returns: [height, width, peg_distance] or undef for unknown format
function get_film_format(format, custom_height = undef, custom_width = undef) =
    let(entry = _find_film_format(format))
    entry != undef
        ? [entry[_FF_HEIGHT], entry[_FF_WIDTH], entry[_FF_PEG_DIST]]
        : format == "custom"
            ? [
                custom_height != undef ? custom_height : customFilmFormatHeight,
                custom_width != undef ? custom_width : customFilmFormatWidth,
                custom_width != undef ? custom_width : customFilmFormatPegDistance
              ]
            : undef;

// Backward-compatible accessor functions
function get_film_format_height(format, custom_film_height = undef) =
    get_film_format(format, custom_film_height)[0];

function get_film_format_width(format, custom_film_width = undef) =
    get_film_format(format, undef, custom_film_width)[1];

function get_film_format_peg_distance(format, custom_film_width = undef) =
    get_film_format(format, undef, custom_film_width)[2];

// Frame pitch along the strip for a format (0 for single-frame-only formats
// such as 4x5 sheets, and for "custom", which sizes its opening directly).
function get_film_format_frame_pitch(format) =
    let(entry = _find_film_format(format))
    entry != undef ? entry[_FF_FRAME_PITCH] : 0;

// Effective frame count: formats without a pitch can't span frames, so they
// always render as a single frame regardless of Frame_Count.
function get_effective_frame_count(format, frame_count = 1) =
    (get_film_format_frame_pitch(format) > 0 && frame_count > 1) ? frame_count : 1;

// Function to get the type name for etching. Multi-frame openings get an
// " X<n>" suffix (e.g. "35MM X2") so the carrier reads what it holds.
function get_film_format_type_name(format, frame_count = 1) =
    let(
        entry = _find_film_format(format),
        base = entry != undef ? entry[_FF_TYPE_NAME]
            : format == "custom" ? "CUSTOM"
            : format, // Fallback to format name
        n = get_effective_frame_count(format, frame_count)
    ) n > 1 ? str(base, " X", n) : base;

// Function to determine the selected type name for etching (backward compatible)
function get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format, Frame_Count = 1) =
    Type_Name == "Custom" ? Custom_Type_Name : get_film_format_type_name(Film_Format, Frame_Count);
