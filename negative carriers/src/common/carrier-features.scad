// Common features for negative carriers

include <BOSL2/std.scad>

// Creates the rectangular opening for the film frame.
// Parameters:
//   opening_height: The height of the opening (dimension perpendicular to film travel for roll film).
//   opening_width: The width of the opening (dimension parallel to film travel for roll film).
//   carrier_height: The thickness of the carrier plate.
//   cut_through_extension: Extra height to ensure the cut goes fully through.
//   frame_fillet: The fillet/chamfer radius for the opening edges.
module film_opening(opening_height, opening_width, carrier_height, cut_through_extension, frame_fillet) {
    // Use color for debugging visibility if needed, can be removed later.
    // color("red")
    cuboid([opening_height, opening_width, carrier_height + cut_through_extension], chamfer = frame_fillet, anchor = CENTER);
}

// Creates the registration pegs or corresponding holes.
// Parameters:
//   is_hole: If true, creates holes; otherwise, creates pegs.
//   peg_diameter: The diameter of the pegs/holes.
//   peg_height: The height of the pegs (or depth of holes, effectively).
//   peg_pos_x: The distance of the peg centers from the Y-axis.
//   peg_pos_y: The distance of the peg centers from the X-axis.
//   z_offset: The Z position for the center of the pegs/holes.
module pegs_feature(is_hole = false, peg_diameter, peg_height, peg_pos_x, peg_pos_y, z_offset) {
    radius = is_hole ? peg_diameter/2 + 0.25 : peg_diameter/2; // Add tolerance for holes
    // Add 0.1mm to the peg height to ensure it appears properly in OpenSCAD preview
    effective_peg_height = peg_height + 0.1;

    // Use color for debugging visibility if needed, can be removed later.
    // color("blue")
    union() { // Use union explicitly for clarity
        translate([peg_pos_x, peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center = true);
        translate([peg_pos_x, -peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center = true);
        translate([-peg_pos_x, peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center = true);
        translate([-peg_pos_x, -peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center = true);
    }
}

// Creates holes specifically for M2 heat-set screws.
// The locations are the same as pegs_feature.
// Aims for a ~1.8mm final hole diameter for press-fitting M2 screws with heat.
// The pegs_feature module adds 0.5mm to the diameter for holes (0.25mm to the radius).
// Therefore, to achieve a 1.8mm final diameter, an input diameter of 1.3mm is used (1.8mm - 0.5mm = 1.3mm).
module heat_set_pegs_holes(peg_height, peg_pos_x, peg_pos_y, z_offset) {
    m2_heat_set_input_diameter = 1.6;
    pegs_feature(is_hole = true, peg_diameter = m2_heat_set_input_diameter, peg_height = peg_height, peg_pos_x = peg_pos_x, peg_pos_y = peg_pos_y, z_offset = z_offset);
}

module heat_set_pegs_socket_head_opening(peg_height, peg_pos_x, peg_pos_y, z_offset) {
    m2_heat_set_input_diameter = 3.8;
    pegs_feature(is_hole = true, peg_diameter = m2_heat_set_input_diameter, peg_height = peg_height, peg_pos_x = peg_pos_x, peg_pos_y = peg_pos_y, z_offset = z_offset);
}

// Creates an extruded text shape for etching.
// Assumes the caller will handle positioning (translate) and rotation.
// Parameters:
//   text_string: The text to etch.
//   font: The font face to use.
//   size: The font size.
//   etch_depth: The depth of the etch (extrusion height). Default 1mm.
//   halign: Horizontal alignment ("left", "center", "right").
//   valign: Vertical alignment ("top", "center", "baseline", "bottom").
module text_etch(text_string, font, size, etch_depth = 1, halign="center", valign="center") {
    // Extrude slightly more than depth to ensure cut subtraction works reliably.
    linear_extrude(height = etch_depth + 0.2) {
        text(text_string, font = font, size = size, halign = halign, valign = valign);
    }
}
