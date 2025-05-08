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

// Function to determine effective orientation, especially for "4x5"
function get_effective_orientation(film_format_str, orientation_str) =
    (film_format_str == "4x5") ? "vertical" : orientation_str;

// Function to calculate base opening height based on effective orientation and film dimensions
function get_calculated_opening_height(eff_orientation, film_actual_h, film_actual_w) =
    eff_orientation == "vertical" ? film_actual_h : film_actual_w;

// Function to calculate base opening width based on effective orientation and film dimensions
function get_calculated_opening_width(eff_orientation, film_actual_h, film_actual_w) =
    eff_orientation == "vertical" ? film_actual_w : film_actual_h;

// Generic function to apply an adjustment to a dimension
function get_adjusted_dimension(base_dim, adjustment_val) =
    base_dim + adjustment_val;

// Function to get the final, adjusted opening height after considering film format, orientation, and adjustments
function get_final_opening_height(film_format_str, orientation_str, adjust_h_val) = 
    let (
        _film_h_raw = get_film_format_height(film_format_str),
        _film_w_raw = get_film_format_width(film_format_str),
        _eff_orientation = get_effective_orientation(film_format_str, orientation_str),
        _calc_opening_h = get_calculated_opening_height(_eff_orientation, _film_h_raw, _film_w_raw)
    )
    get_adjusted_dimension(_calc_opening_h, adjust_h_val);

// Function to get the final, adjusted opening width after considering film format, orientation, and adjustments
function get_final_opening_width(film_format_str, orientation_str, adjust_w_val) = 
    let (
        _film_h_raw = get_film_format_height(film_format_str),
        _film_w_raw = get_film_format_width(film_format_str),
        _eff_orientation = get_effective_orientation(film_format_str, orientation_str),
        _calc_opening_w = get_calculated_opening_width(_eff_orientation, _film_h_raw, _film_w_raw)
    )
    get_adjusted_dimension(_calc_opening_w, adjust_w_val);

// Function to calculate Z offset for pegs/holes
// is_top_piece: boolean (true if "top" part, false otherwise)
// z_value_for_top: the Z offset value if it's the top piece
// z_value_for_bottom: the Z offset value if it's the bottom piece
function get_peg_z_offset(is_top_piece, z_value_for_top, z_value_for_bottom) =
    is_top_piece ? z_value_for_top : z_value_for_bottom;

// Function to calculate a peg coordinate (either X or Y) based on Omega-style rules
// is_dominant_film_dimension:
//      For X-coord: true if effective_orientation is "vertical" (X uses film width).
//      For Y-coord: true if effective_orientation is "horizontal" (Y uses film width).
// film_width_or_equiv_half: (e.g., FILM_FORMAT_WIDTH / 2)
// film_peg_distance_half: (e.g., FILM_FORMAT_PEG_DISTANCE / 2)
// peg_radius: (e.g., OMEGA_D_PEG_DIAMETER / 2)
// omega_internal_gap_value: The calculated internal gap (e.g., CALCULATED_INTERNAL_PEG_GAP).
//                           This gap is SUBTRACTED when film_peg_distance is used.
function calculate_omega_style_peg_coordinate(is_dominant_film_dimension, film_width_or_equiv_half, film_peg_distance_half, peg_radius, omega_internal_gap_value) =
    is_dominant_film_dimension ?
        (film_width_or_equiv_half + peg_radius) : // No gap applied here in Omega style for dominant film dimension
        (film_peg_distance_half + peg_radius - omega_internal_gap_value);

// Module to generate peg features (printed pegs or holes for pegs/inserts)
// Parameters:
//   _top_or_bottom: "top" or "bottom"
//   _printed_or_heat_set: "printed" or "heat_set"
//   _peg_dia: Diameter of the peg (used for printed pegs and clearance holes)
//   _peg_h: Height of the peg
//   _peg_x: X position of peg centers
//   _peg_y: Y position of peg centers
//   _z_off: Z offset for the pegs/holes
//   _is_subtraction_pass: true if generating holes for subtraction, false for generating solid pegs
module generate_peg_features(
    _top_or_bottom,
    _printed_or_heat_set,
    _peg_dia,
    _peg_h,
    _peg_x,
    _peg_y,
    _z_off,
    _is_subtraction_pass
) {
    if (_is_subtraction_pass) {
        // Logic for subtractions (holes)
        if (_top_or_bottom == "top") {
            if (_printed_or_heat_set == "printed") {
                // Clearance holes for printed pegs (which are on the bottom piece)
                pegs_feature(
                    is_hole = true,
                    peg_diameter = _peg_dia,
                    peg_height = _peg_h,
                    peg_pos_x = _peg_x,
                    peg_pos_y = _peg_y,
                    z_offset = _z_off
                );
            } else { // "heat_set" pegs chosen, top piece needs socket head openings
                heat_set_pegs_socket_head_opening(
                    peg_height = _peg_h, // Uses its own diameter logic for M2 socket head
                    peg_pos_x = _peg_x,
                    peg_pos_y = _peg_y,
                    z_offset = _z_off
                );
            }
        } else { // Bottom piece, for subtractions (only for heat-set inserts)
            if (_printed_or_heat_set == "heat_set") {
                // Holes for heat-set inserts
                heat_set_pegs_holes(
                    peg_height = _peg_h, // Uses its own diameter logic for M2 heat-set insert
                    peg_pos_x = _peg_x,
                    peg_pos_y = _peg_y,
                    z_offset = _z_off
                );
            }
        }
    } else {
        // Logic for additions (printed pegs on bottom piece)
        if (_top_or_bottom == "bottom" && _printed_or_heat_set == "printed") {
            pegs_feature(
                is_hole = false, // Create pegs
                peg_diameter = _peg_dia,
                peg_height = _peg_h,
                peg_pos_x = _peg_x,
                peg_pos_y = _peg_y,
                z_offset = _z_off
            );
        }
    }
}

// Module to instantiate a specific alignment board based on type string
// The caller is responsible for positioning (translate) and coloring.
module instantiate_alignment_board_by_type(board_type_str) {
    if (board_type_str == "omega") {
        omega_d_alignment_board_no_screws(); // From common/omega-d-alignment-board.scad
    } else if (board_type_str == "lpl-saunders") {
        lpl_saunders_alignment_board();    // From common/lpl-saunders-alignment-board.scad
    } else if (board_type_str == "beseler-23c") {
        // Assuming a module like `beseler_23c_alignment_board()` exists in common/beseler-23c-alignment-board.scad
        // If the actual module is just `alignment_circle()`, this might need adjustment
        // or Beseler carriers will call `alignment_circle()` directly.
        beseler_23c_alignment_board(); 
    } else {
        echo(str("Warning: Unknown alignment board type specified: ", board_type_str));
    }
}
