alignmentCircleOuterDiameter = 120;
alignmentCircleInnerDiameter = 110;

// Torus dimensions derived from outer/inner diameters
// Major radius: midpoint between outer and inner radii
TORUS_MAJOR_RADIUS = (alignmentCircleOuterDiameter + alignmentCircleInnerDiameter) / 4; // 57.5
// Minor radius: half the difference between outer and inner radii (cross-section radius)
TORUS_MINOR_RADIUS = (alignmentCircleOuterDiameter - alignmentCircleInnerDiameter) / 4; // 2.5

module beseler_23c_alignment_board() {
    render() translate([0, 0, .5]) {
        torus(r_maj=TORUS_MAJOR_RADIUS, r_min=TORUS_MINOR_RADIUS, anchor=CENTER);
    }
}
