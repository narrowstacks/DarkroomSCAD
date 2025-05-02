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

halfFrameHeight = 24;
halfFrameWidth = 18;

fourByFiveHeight = 127;
fourByFiveWidth = 102;

cylinder(h=carrierHeight, r=carrierCircleDiameter/2, center = true);
cube([carrierLength, carrierWidth, carrierHeight], center = true);