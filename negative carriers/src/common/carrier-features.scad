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

// Creates a solid text body (no over-extrusion) for multi-material parts.
// Parameters mirror text_etch, but height is exact with no extra.
module text_solid(text_string, font, size, height, halign="center", valign="center") {
    linear_extrude(height = height) {
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

// Module to process a carrier-specific base shape (passed as children(0))
// by adding standard film opening and peg features.
module carrier_base_processing(
    _top_or_bottom,             // "top" or "bottom"
    _carrier_material_height,   // Height of the carrier plate material
    // Film Opening Parameters
    _opening_height_param,
    _opening_width_param,
    _opening_cut_through_ext_param,
    _opening_fillet_param,
    // Peg Feature Parameters (passed to generate_peg_features)
    _peg_style_param,         // "printed" or "heat_set"
    _peg_diameter_param,
    _peg_actual_height_param, // The actual height for the peg geometry
    _peg_pos_x_param,
    _peg_pos_y_param,
    _peg_z_offset_param       // Calculated Z offset for pegs/holes
) {
    difference() {
        children(0); // Expects the carrier-specific base_shape() module call here

        // Standard film opening
        film_opening(
            opening_height = _opening_height_param,
            opening_width = _opening_width_param,
            carrier_height = _carrier_material_height,
            cut_through_extension = _opening_cut_through_ext_param,
            frame_fillet = _opening_fillet_param
        );

        // Subtractive peg features (holes)
        generate_peg_features(
            _top_or_bottom = _top_or_bottom,
            _printed_or_heat_set = _peg_style_param,
            _peg_dia = _peg_diameter_param,
            _peg_h = _peg_actual_height_param,
            _peg_x = _peg_pos_x_param,
            _peg_y = _peg_pos_y_param,
            _z_off = _peg_z_offset_param,
            _is_subtraction_pass = true
        );
    }

    // Additive peg features (e.g., printed pegs, if applicable based on internal logic of generate_peg_features)
    generate_peg_features(
        _top_or_bottom = _top_or_bottom,
        _printed_or_heat_set = _peg_style_param,
        _peg_dia = _peg_diameter_param,
        _peg_h = _peg_actual_height_param,
        _peg_x = _peg_pos_x_param,
        _peg_y = _peg_pos_y_param,
        _z_off = _peg_z_offset_param,
        _is_subtraction_pass = false // Create solid pegs if conditions within generate_peg_features are met
    );
}

// Module to generate a standardized test frame for checking film fit and peg alignment.
module generate_test_frame(
    _effective_test_piece_role, // "top" or "bottom", defines how pegs/holes are made
    _frame_material_height,     // Standard height for carrier material used for the frame
    // Film Opening Parameters
    _film_opening_h,
    _film_opening_w,
    _film_opening_cut_ext,
    _film_opening_f,
    // Peg Feature Parameters
    _peg_style,       // "printed" or "heat_set"
    _peg_dia_val,
    _peg_h_val,
    _peg_x_val,
    _peg_y_val,
    _peg_z_val,       // Calculated Z offset for pegs/holes in the test frame
    // Test Frame Dimensions
    _test_cuboid_width,  // Overall width of the test frame cuboid
    _test_cuboid_depth   // Overall depth (or X-dim if viewed from top) of test frame cuboid
) {
    union() { // Union for potential additive parts of the test piece (i.e., printed pegs)
        generate_peg_features(
            _top_or_bottom = _effective_test_piece_role,
            _printed_or_heat_set = _peg_style,
            _peg_dia = _peg_dia_val,
            _peg_h = _peg_h_val,
            _peg_x = _peg_x_val,
            _peg_y = _peg_y_val,
            _z_off = _peg_z_val,
            _is_subtraction_pass = false
        );

        difference() {
            // Centered test piece cuboid
            cuboid([_test_cuboid_depth, _test_cuboid_width, _frame_material_height], anchor = CENTER);

            film_opening(
                opening_height = _film_opening_h,
                opening_width = _film_opening_w,
                carrier_height = _frame_material_height,
                cut_through_extension = _film_opening_cut_ext,
                frame_fillet = _film_opening_f
            );

            // Subtractive peg features for the test piece
            generate_peg_features(
                _top_or_bottom = _effective_test_piece_role,
                _printed_or_heat_set = _peg_style,
                _peg_dia = _peg_dia_val,
                _peg_h = _peg_h_val,
                _peg_x = _peg_x_val,
                _peg_y = _peg_y_val,
                _z_off = _peg_z_val,
                _is_subtraction_pass = true
            );
        }
    }
}

// Creates the standard four-hole footprint for alignment board screws.
// Parameters:
//   _screw_dia: Diameter of the screw holes.
//   _dist_for_x_coords: Total distance between hole centers that are separated along the X-axis of the carrier (forms the width of the hole pattern).
//   _dist_for_y_coords: Total distance between hole centers that are separated along the Y-axis of the carrier (forms the length of the hole pattern).
//   _carrier_h: Height of the carrier material.
//   _cut_ext: Cut through extension value.
//   _is_dent: If true, creates dents; otherwise, creates through-holes.
//   _dent_depth: Depth of the dent if _is_dent is true.
module alignment_footprint_holes(_screw_dia, _dist_for_x_coords, _dist_for_y_coords, _carrier_h, _cut_ext, _is_dent, _dent_depth) {
    hole_radius = _is_dent ? _screw_dia/2 + 0.25 : _screw_dia/2; // Add tolerance for dents if they are for press-fit or similar
    actual_hole_height = _is_dent ? _dent_depth : _carrier_h + _cut_ext;
    use_center_alignment = !_is_dent; // Through-holes are centered; dents are typically from a surface.
    // For dents, place their base at one of the surfaces (e.g. top surface going down, or bottom surface going up).
    // Assuming dents are typically made from the "outside" surface coming in.
    // If carrier is centered at Z=0, top surface is _carrier_h/2, bottom is -_carrier_h/2.
    // If _is_dent, place base of cylinder such that it cuts inwards from a surface.
    // For this module, let's assume dents go from Z=0 downwards if not centered, or from top surface if centered for carrier.
    // The original omega-d alignment_screw_holes places dents starting from z_pos = (-OMEGA_D_CARRIER_HEIGHT / 2) - 0.1 for dents.
    // This means the base of the dent cylinder is slightly below the carrier bottom surface, cutting upwards.
    // To maintain compatibility while being generic:
    // If it's a dent, it's not centered. We need a z_pos that makes sense.
    // Let's assume dents are cut from the surface the pegs/holes are referenced from.
    // If z_offset for pegs is carrier_h/2 (bottom piece), dents would be from top surface down.
    // If z_offset for pegs is related to top piece, dents might be from bottom surface up.
    // Given the original was `z_pos = is_dent ? (-OMEGA_D_CARRIER_HEIGHT / 2) - 0.1 : 0;`
    // and `cylinder(h=hole_h, r=hole_radius, center = use_center);`
    // If is_dent, hole_h = _dent_depth + 0.1 (originally), and center=false. Cylinder base at z_pos.
    // If !is_dent, hole_h = _carrier_h + _cut_ext, and center=true. Cylinder centered at z_pos=0.

    z_val_for_hole = _is_dent ? (-_carrier_h / 2) : 0; // If dent, base is at bottom surface, cutting up. If through-hole, centered at Z=0.
    
    eff_spacing_x = _dist_for_x_coords / 2;
    eff_spacing_y = _dist_for_y_coords / 2;

    for (x_mult = [-1, 1]) {
        for (y_mult = [-1, 1]) {
            translate([eff_spacing_x * x_mult, eff_spacing_y * y_mult, z_val_for_hole])
                cylinder(h=actual_hole_height, r=hole_radius, center=use_center_alignment);
        }
    }
}
