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

// NOTE: customFilmFormatHeight, customFilmFormatWidth, customFilmFormatPegDistance 
// should be defined in the file including this one if filmFormat == "custom" is used.

filmFormatHeight = filmFormat == "35mm" ? thirtyFiveFullHeight : filmFormat == "35mm filed" ? thirtyFiveFiledHeight : filmFormat == "35mm full" ? thirtyFiveStandardHeight : filmFormat == "half frame" ? halfFrameHeight : filmFormat == "6x4.5" ? mediumFormat6x45Length : filmFormat == "6x6" ? mediumFormat6x6Length : filmFormat == "6x7" ? mediumFormat6x7Length : filmFormat == "6x8" ? mediumFormat6x8Length : filmFormat == "6x9" ? mediumFormat6x9Length : filmFormat == "4x5" ? fourByFiveHeight : filmFormat == "custom" ? customFilmFormatHeight : 130; // Default or error value
filmFormatWidth = filmFormat == "35mm" ? thirtyFiveStandardWidth : filmFormat == "35mm filed" ? thirtyFiveFiledWidth : filmFormat == "35mm full" ? thirtyFiveStandardWidth : filmFormat == "half frame" ? halfFrameWidth : filmFormat == "6x4.5" ? mediumFormatHeight : filmFormat == "6x6" ? mediumFormatHeight : filmFormat == "6x7" ? mediumFormatHeight : filmFormat == "6x8" ? mediumFormatHeight : filmFormat == "6x9" ? mediumFormatHeight : filmFormat == "4x5" ? fourByFiveWidth : filmFormat == "custom" ? customFilmFormatWidth : 130; // Default or error value
filmFormatPegDistance = filmFormat == "35mm" ? thirtyFiveFullHeight : filmFormat == "35mm filed" ? thirtyFiveFullHeight : filmFormat == "35mm full" ? thirtyFiveFullHeight : filmFormat == "half frame" ? thirtyFiveFullHeight : filmFormat == "6x4.5" ? mediumFormatFullHeight : filmFormat == "6x6" ? mediumFormatFullHeight : filmFormat == "6x7" ? mediumFormatFullHeight : filmFormat == "6x8" ? mediumFormatFullHeight : filmFormat == "6x9" ? mediumFormatFullHeight : filmFormat == "4x5" ? mediumFormatFullHeight : filmFormat == "custom" ? customFilmFormatPegDistance : 130; // Default or error value
