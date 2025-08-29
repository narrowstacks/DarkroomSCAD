/* [Hidden] */
// film type measurements
thirtyFiveFullHeight = 37;
mediumFormatFullHeight = 62;
fourByFiveFullWidth = 102;
fourByFiveFullHeight = 127;

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

// Matt6x12Plus film length
Matt6x12PlusLength = 125;
Matt6x12PlusFiledLength = 128;

// 4x5 film height
fourByFiveHeight = 120;
// 4x5 film width
fourByFiveWidth = 95;

// 35mm film height
thirtyFiveStandardHeight = 36;
thirtyFiveStandardWidth = 24;

// 35mm filed carrier
thirtyFiveFiledHeight = 38;
thirtyFiveFiledWidth = 27;

// half frame width
halfFrameWidth = 24;
halfFrameHeight = 18;

// Custom film format defaults (matching 35mm format for consistent behavior)
customFilmFormatHeight = 37;
customFilmFormatWidth = 37;
customFilmFormatPegDistance = 37; // Default to 35mm dimensions for consistency

// Function to get the film format height based on the selected format string
// For custom format, pass custom_film_height parameter to override default
function get_film_format_height(format, custom_film_height = undef) =
    format == "35mm" ? thirtyFiveFullHeight
    : format == "35mm filed" ? thirtyFiveFiledHeight
    : format == "35mm full" ? thirtyFiveStandardHeight
    : format == "half frame" ? halfFrameHeight
    : format == "6x4.5" ? mediumFormat6x45Length
    : format == "6x4.5 filed" ? mediumFormat6x45FiledLength
    : format == "6x6" ? mediumFormat6x6Length
    : format == "6x6 filed" ? mediumFormat6x6FiledLength
    : format == "6x7" ? mediumFormat6x7Length
    : format == "6x7 filed" ? mediumFormat6x7FiledLength
    : format == "6x8" ? mediumFormat6x8Length
    : format == "6x8 filed" ? mediumFormat6x8FiledLength
    : format == "6x9" ? mediumFormat6x9Length
    : format == "6x9 filed" ? mediumFormat6x9FiledLength
    : format == "4x5" ? fourByFiveHeight
    : format == "custom" ? (custom_film_height != undef ? custom_film_height : customFilmFormatHeight)
    : undef; // Indicate error for unknown format

// Function to get the film format width based on the selected format string  
// For custom format, pass custom_film_width parameter to override default
function get_film_format_width(format, custom_film_width = undef) =
    format == "35mm" ? thirtyFiveStandardWidth
    : format == "35mm filed" ? thirtyFiveFiledWidth
    : format == "35mm full" ? thirtyFiveStandardWidth
    : format == "half frame" ? halfFrameWidth
    : format == "6x4.5" ? mediumFormatHeight
    : format == "6x4.5 filed" ? mediumFormatFiledHeight
    : format == "6x6" ? mediumFormatHeight
    : format == "6x6 filed" ? mediumFormatFiledHeight
    : format == "6x7" ? mediumFormatHeight
    : format == "6x7 filed" ? mediumFormatFiledHeight
    : format == "6x8" ? mediumFormatHeight
    : format == "6x8 filed" ? mediumFormatFiledHeight
    : format == "6x9" ? mediumFormatHeight
    : format == "6x9 filed" ? mediumFormatFiledHeight
    : format == "4x5" ? fourByFiveWidth
    : format == "custom" ? (custom_film_width != undef ? custom_film_width : customFilmFormatWidth)
    : undef; // Indicate error for unknown format

// Function to get the peg distance based on the selected format string
// For custom format, pass custom_film_width parameter (peg distance = film width for custom)
function get_film_format_peg_distance(format, custom_film_width = undef) =
    format == "35mm" ? thirtyFiveFullHeight
    : format == "35mm filed" ? thirtyFiveFullHeight
    : format == "35mm full" ? thirtyFiveFullHeight
    : format == "half frame" ? thirtyFiveFullHeight
    : format == "6x4.5" ? mediumFormatFullHeight
    : format == "6x4.5 filed" ? mediumFormatFullHeight
    : format == "6x6" ? mediumFormatFullHeight
    : format == "6x6 filed" ? mediumFormatFullHeight
    : format == "6x7" ? mediumFormatFullHeight
    : format == "6x7 filed" ? mediumFormatFullHeight
    : format == "6x8" ? mediumFormatFullHeight
    : format == "6x8 filed" ? mediumFormatFullHeight
    : format == "6x9" ? mediumFormatFullHeight
    : format == "6x9 filed" ? mediumFormatFullHeight
    : format == "6x12" ? mediumFormatFullHeight
    : // Keep potential future formats
    format == "6x17" ? mediumFormatFullHeight
    : // Keep potential future formats
    format == "4x5" ? fourByFiveFullWidth
    : // Use film width for 4x5 peg distance base
    format == "custom" ? (custom_film_width != undef ? custom_film_width : customFilmFormatPegDistance)
    : undef; // Indicate error for unknown format

// Function to determine the selected type name for etching
function get_selected_type_name(Type_Name, Custom_Type_Name, Film_Format) =
    Type_Name == "Custom" ? Custom_Type_Name
    : Film_Format == "35mm" ? "35MM"
    : Film_Format == "35mm filed" ? "FILED35"
    : Film_Format == "35mm full" ? "FULL35"
    : Film_Format == "half frame" ? "HALF"
    : Film_Format == "6x4.5" ? "6x4.5"
    : Film_Format == "6x4.5 filed" ? "F6x4.5"
    : Film_Format == "6x6" ? "6x6"
    : Film_Format == "6x6 filed" ? "F6x6"
    : Film_Format == "6x7" ? "6x7"
    : Film_Format == "6x7 filed" ? "F6x7"
    : Film_Format == "6x8" ? "6x8"
    : Film_Format == "6x8 filed" ? "F6x8"
    : Film_Format == "6x9" ? "6x9"
    : Film_Format == "6x9 filed" ? "F6x9"
    : Film_Format == "4x5" ? "4X5"
    : Film_Format == "custom" ? "CUSTOM"
    : Film_Format; // Fallback to original name if not mapped
