alignmentCircleOuterDiameter = 120;
alignmentCircleInnerDiameter = 110;
alignmentCircleThickness = 5;

module beseler_23c_alignment_board() {
    // Major radius R = (OuterD/2 + InnerD/2) / 2 = (120/2 + 110/2) / 2 = (60 + 55) / 2 = 57.5
    // Minor radius r = (OuterD/2 - InnerD/2) / 2 = (60 - 55) / 2 = 2.5
    // Height = 2 * r = 5, which matches alignmentCircleThickness
    color("red") torus(r_maj = alignmentCircleOuterDiameter/4 + alignmentCircleInnerDiameter/4, 
                       r_min = alignmentCircleOuterDiameter/4 - alignmentCircleInnerDiameter/4, 
                       anchor=CENTER);
}