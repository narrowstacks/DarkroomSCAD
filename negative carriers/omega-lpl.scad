include <BOSL2/std.scad>
$fn=100;

// carrier dimensions
carrierLength = 202;
carrierWidth = 139;
carrierHeight = 2;
carrierCircleDiameter = 168;
carrierRectOffset = 13.5;
carrierFillet = 3;
frameFillet = 0.5;

// carrier pegs
pegDiameter = 5.6;
pegHeight = 4;

// registration holes
regHoleDiameter = 6;
regHoleDistance = 130;
regHoleXLength = 10;
regHole1DistToCorner = 35;
regHole2DistToCorner = 1;

// film sizes
thirtyFiveFullHeight = 35;
mediumFormatFullHeight = 61;

mediumFormatHeight = 56;
mediumFormat6x45Length = 41.5;
mediumFormat6x6Length = 56;
mediumFormat6x7Length = 70;
mediumFormat6x8Length = 77;
mediumFormat6x9Length = 84;
mediumFormat6x12Length = 118;
mediumFormat6x17Length = 168;

thirtyFiveStandardHeight = 36;
thirtyFiveStandardWidth = 24;

thirtyFiveFiledHeight = 38;
thirtyFiveFiledWidth = 27;

halfFrameWidth = 24;
halfFrameHeight = 18;

fourByFiveHeight = 127;
fourByFiveWidth = 102;

// adjustable parameters. if user selects a format, the carrier will be cut to fit that format.
formatsList = ["35mm", "35mm filed", "35mm full", "half frame", "6x4.5", "6x6", "6x7", "6x8", "6x9", "6x12", "6x17", "4x5"];
filmFormat = "35mm";

filmFormatHeight = filmFormat == "35mm" ? thirtyFiveFullHeight : filmFormat == "35mm filed" ? thirtyFiveFiledHeight : filmFormat == "35mm full" ? thirtyFiveStandardHeight : filmFormat == "half frame" ? halfFrameHeight : filmFormat == "6x4.5" ? mediumFormat6x45Length : filmFormat == "6x6" ? mediumFormat6x6Length : filmFormat == "6x7" ? mediumFormat6x7Length : filmFormat == "6x8" ? mediumFormat6x8Length : filmFormat == "6x9" ? mediumFormat6x9Length : filmFormat == "6x12" ? mediumFormat6x12Length : filmFormat == "6x17" ? mediumFormat6x17Length : fourByFiveHeight;
filmFormatWidth = filmFormat == "35mm" ? thirtyFiveStandardWidth : filmFormat == "35mm filed" ? thirtyFiveFiledWidth : filmFormat == "35mm full" ? thirtyFiveStandardWidth : filmFormat == "half frame" ? halfFrameWidth : filmFormat == "6x4.5" ? mediumFormatHeight : filmFormat == "6x6" ? mediumFormatHeight : filmFormat == "6x7" ? mediumFormatHeight : filmFormat == "6x8" ? mediumFormatHeight : filmFormat == "6x9" ? mediumFormatHeight : filmFormat == "6x12" ? mediumFormatHeight : filmFormat == "6x17" ? mediumFormatHeight : fourByFiveWidth;
filmFormatPegDistance = filmFormat == "35mm" ? thirtyFiveFullHeight : filmFormat == "35mm filed" ? thirtyFiveFullHeight : filmFormat == "35mm full" ? thirtyFiveFullHeight : filmFormat == "half frame" ? thirtyFiveFullHeight : filmFormat == "6x4.5" ? mediumFormatFullHeight : filmFormat == "6x6" ? mediumFormatFullHeight : filmFormat == "6x7" ? mediumFormatFullHeight : filmFormat == "6x8" ? mediumFormatFullHeight : filmFormat == "6x9" ? mediumFormatFullHeight : filmFormat == "6x12" ? mediumFormatFullHeight : filmFormat == "6x17" ? mediumFormatFullHeight : filmFormat == "4x5" ? mediumFormatFullHeight : 130;
union() {
    difference() {
    union() {
        cylinder(h=carrierHeight, r=carrierCircleDiameter/2, center = true);
        translate([-carrierRectOffset, 0, 0]) cuboid([carrierLength, carrierWidth, carrierHeight], anchor = CENTER);
    }
    cuboid([filmFormatHeight, filmFormatWidth, carrierHeight + 1 ], chamfer = .5, anchor = CENTER);
    }
    translate([filmFormatWidth/2 + pegDiameter/2, -filmFormatPegDistance/2 - pegDiameter/2, carrierHeight/2]) cylinder(h=pegHeight, r=pegDiameter/2, center = true);
    translate([filmFormatWidth/2 + pegDiameter/2, filmFormatPegDistance/2 + pegDiameter/2, carrierHeight/2]) cylinder(h=pegHeight, r=pegDiameter/2, center = true);
    translate([-filmFormatWidth/2 - pegDiameter/2, -filmFormatPegDistance/2 - pegDiameter/2, carrierHeight/2]) cylinder(h=pegHeight, r=pegDiameter/2, center = true);
    translate([-filmFormatWidth/2 - pegDiameter/2, filmFormatPegDistance/2 + pegDiameter/2, carrierHeight/2]) cylinder(h=pegHeight, r=pegDiameter/2, center = true);
}