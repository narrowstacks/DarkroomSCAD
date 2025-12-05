/* [Hidden] */
// Film stock physical dimensions (full film width including perforations/edges)
thirtyFiveFullHeight = 37;      // 35mm film strip width
thirtyFiveStandardWidth=24;
mediumFormatFullHeight = 62;    // 120/220 film width
mediumFormatStandardHeight = 56;
mediumFormatFiledHeight = 58;
fourByFiveFullWidth = 102;      // 4x5 sheet film width
fourByFiveFullHeight = 127;     // 4x5 sheet film height

// Custom film format defaults
customFilmFormatHeight = 37;
customFilmFormatWidth = 37;
customFilmFormatPegDistance = 37;

// Film format lookup table
// Each entry: [format_name, height, width, peg_distance, type_name]
// - height: opening height (frame length direction)
// - width: opening width (film strip width direction)
// - peg_distance: distance for alignment pegs (based on film stock width)
// - type_name: label for etching
FILM_FORMATS = [
    // 35mm formats
    ["35mm",        37,   thirtyFiveStandardWidth,  thirtyFiveFullHeight, "35MM"],      // Standard 35mm frame
    ["35mm filed",  40,   28,  thirtyFiveFullHeight, "FILED35"],   // Filed/enlarged opening
    ["35mm full",   36,   thirtyFiveStandardWidth,  thirtyFiveFullHeight, "FULL35"],    // Full frame
    ["half frame",  18,   thirtyFiveStandardWidth,  thirtyFiveFullHeight, "HALF"],      // Half frame (portrait orientation)

    // Medium format (120/220) - height is frame length, width is 56mm (or 58 filed)
    ["6x4.5",       41.5, mediumFormatStandardHeight,  mediumFormatFullHeight, "6x4.5"],
    ["6x4.5 filed", 43.5, mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x4.5"],
    ["6x6",         mediumFormatStandardHeight,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x6"],
    ["6x6 filed",   mediumFormatFiledHeight,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x6"],
    ["6x7",         70,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x7"],
    ["6x7 filed",   72,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x7"],
    ["6x8",         77,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x8"],
    ["6x8 filed",   79,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x8"],
    ["6x9",         84,   mediumFormatStandardHeight,  mediumFormatFullHeight, "6x9"],
    ["6x9 filed",   86,   mediumFormatFiledHeight,  mediumFormatFullHeight, "F6x9"],

    // Large format
    ["4x5",         120,  95,  fourByFiveFullWidth, "4X5"],
];

// Index constants for FILM_FORMATS table
_FF_NAME = 0;
_FF_HEIGHT = 1;
_FF_WIDTH = 2;
_FF_PEG_DIST = 3;
_FF_TYPE_NAME = 4;

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

// Function to get the type name for etching
function get_film_format_type_name(format) =
    let(entry = _find_film_format(format))
    entry != undef ? entry[_FF_TYPE_NAME]
        : format == "custom" ? "CUSTOM"
        : format; // Fallback to format name

// Function to determine the selected type name for etching (backward compatible)
function get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format) =
    Type_Name == "Custom" ? Custom_Type_Name : get_film_format_type_name(Film_Format);
