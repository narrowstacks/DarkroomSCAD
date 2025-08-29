// Common features for negative carriers
include <BOSL2/std.scad>

// Constants for common dimensions and tolerances
PEG_HOLE_TOLERANCE = 0.25; // Additional radius for peg holes
PEG_HEIGHT_ADJUSTMENT = 0.2; // Extra height for proper OpenSCAD preview
TEXT_ETCH_OVEREXTRUDE = 0.2; // Extra extrusion for reliable subtraction
M2_HEAT_SET_HOLE_DIA = 1.6; // Diameter for M2 heat-set insert holes
M2_SOCKET_HEAD_DIA = 3.8; // Diameter for M2 socket head clearance
DENT_TOLERANCE = 0.25; // Additional radius for dent holes

// Creates the rectangular opening for the film frame.
module film_opening(opening_height, opening_width, carrier_height, cut_through_extension, frame_fillet) {
    cuboid([opening_height, opening_width, carrier_height + cut_through_extension], chamfer=frame_fillet, anchor=CENTER);
}

// Creates the registration pegs or corresponding holes.
module pegs_feature(is_hole = false, peg_diameter, peg_height, peg_pos_x, peg_pos_y, z_offset) {
    radius = is_hole ? peg_diameter / 2 + PEG_HOLE_TOLERANCE : peg_diameter / 2;
    effective_peg_height = peg_height + PEG_HEIGHT_ADJUSTMENT;

    union() {
        translate([peg_pos_x, peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center=true);
        translate([peg_pos_x, -peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center=true);
        translate([-peg_pos_x, peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center=true);
        translate([-peg_pos_x, -peg_pos_y, z_offset]) cylinder(h=effective_peg_height, r=radius, center=true);
    }
}

// Creates holes for M2 heat-set screws
module heat_set_pegs_holes(is_socket_head = false, peg_height, peg_pos_x, peg_pos_y, z_offset) {
    diameter = is_socket_head ? M2_SOCKET_HEAD_DIA : M2_HEAT_SET_HOLE_DIA;
    pegs_feature(is_hole=true, peg_diameter=diameter, peg_height=peg_height, peg_pos_x=peg_pos_x, peg_pos_y=peg_pos_y, z_offset=z_offset);
}

// Legacy wrapper for backward compatibility
module heat_set_pegs_socket_head_opening(peg_height, peg_pos_x, peg_pos_y, z_offset) {
    heat_set_pegs_holes(is_socket_head=true, peg_height=peg_height, peg_pos_x=peg_pos_x, peg_pos_y=peg_pos_y, z_offset=z_offset);
}

// Creates an extruded text shape for etching.
module text_etch(text_string, font, size, etch_depth = 1, halign = "center", valign = "center") {
    linear_extrude(height=etch_depth + TEXT_ETCH_OVEREXTRUDE) {
        text(text_string, font=font, size=size, halign=halign, valign=valign);
    }
}

// Creates a solid text body for multi-material parts.
module text_solid(text_string, font, size, height, halign = "center", valign = "center") {
    linear_extrude(height=height) {
        text(text_string, font=font, size=size, halign=halign, valign=valign);
    }
}

// Determine effective orientation, especially for "4x5"
function get_effective_orientation(film_format_str, orientation_str) =
    (film_format_str == "4x5") ? "vertical" : orientation_str;

// Calculate base opening height based on effective orientation and film dimensions
function get_calculated_opening_height(eff_orientation, film_actual_h, film_actual_w) =
    eff_orientation == "vertical" ? film_actual_h : film_actual_w;

// Calculate base opening width based on effective orientation and film dimensions
function get_calculated_opening_width(eff_orientation, film_actual_h, film_actual_w) =
    eff_orientation == "vertical" ? film_actual_w : film_actual_h;

// Apply an adjustment to a dimension
function get_adjusted_dimension(base_dim, adjustment_val) =
    base_dim + adjustment_val;

// Get final adjusted opening dimension
// For custom formats, pass custom_film_height and custom_film_width to override defaults
function get_final_opening_dimension(is_height, film_format_str, orientation_str, adjust_val, custom_film_height = undef, custom_film_width = undef) =
    let (
        _film_h_raw = get_film_format_height(film_format_str, custom_film_height),
        _film_w_raw = get_film_format_width(film_format_str, custom_film_width),
        _eff_orientation = get_effective_orientation(film_format_str, orientation_str),
        _calc_opening_dim = is_height ?
            get_calculated_opening_height(_eff_orientation, _film_h_raw, _film_w_raw)
        : get_calculated_opening_width(_eff_orientation, _film_h_raw, _film_w_raw)
    ) get_adjusted_dimension(_calc_opening_dim, adjust_val);

// Wrapper functions for backward compatibility and custom format support
function get_final_opening_height(film_format_str, orientation_str, adjust_h_val, custom_film_height = undef, custom_film_width = undef) =
    get_final_opening_dimension(true, film_format_str, orientation_str, adjust_h_val, custom_film_height, custom_film_width);

function get_final_opening_width(film_format_str, orientation_str, adjust_w_val, custom_film_height = undef, custom_film_width = undef) =
    get_final_opening_dimension(false, film_format_str, orientation_str, adjust_w_val, custom_film_height, custom_film_width);

// For custom formats: use custom opening dimensions directly if provided, otherwise calculate from film stock 
function get_custom_aware_opening_height(film_format_str, orientation_str, adjust_h_val, custom_film_height = undef, custom_film_width = undef, custom_opening_height = undef) =
    (film_format_str == "custom" && custom_opening_height != undef) ?
        custom_opening_height
    : get_final_opening_height(film_format_str, orientation_str, adjust_h_val, custom_film_height, custom_film_width);

function get_custom_aware_opening_width(film_format_str, orientation_str, adjust_w_val, custom_film_height = undef, custom_film_width = undef, custom_opening_width = undef) =
    (film_format_str == "custom" && custom_opening_width != undef) ?
        custom_opening_width
    : get_final_opening_width(film_format_str, orientation_str, adjust_w_val, custom_film_height, custom_film_width);

// Calculate Z offset for pegs/holes
function get_peg_z_offset(is_top_piece, z_value_for_top, z_value_for_bottom) =
    is_top_piece ? z_value_for_top : z_value_for_bottom;

// Calculate a peg coordinate (X or Y) based on Omega-style rules
function calculate_omega_style_peg_coordinate(is_dominant_film_dimension, film_width_or_equiv_half, film_peg_distance_half, peg_radius, omega_internal_gap_value) =
    is_dominant_film_dimension ?
        (film_width_or_equiv_half + peg_radius)
    : (film_peg_distance_half + peg_radius - omega_internal_gap_value);

// Calculate internal peg gap for filed medium formats
function calculate_internal_peg_gap(film_format_str, peg_gap_val) =
    let (
        is_filed = film_format_str == "6x4.5 filed" || film_format_str == "6x6 filed" || film_format_str == "6x7 filed" || film_format_str == "6x8 filed" || film_format_str == "6x9 filed" || film_format_str == "35mm filed"
    ) is_filed ? (1 - peg_gap_val) - 1 : (1 - peg_gap_val);

// Calculate LPL-style peg coordinate (simpler approach based on film dimensions + peg radius + gap)
function calculate_lpl_style_peg_coordinate(effective_orientation, film_height, film_width, peg_radius, peg_gap, is_x_coordinate) =
    let (
        use_width = (effective_orientation == "vertical" && is_x_coordinate) || (effective_orientation == "horizontal" && !is_x_coordinate),
        film_dimension = use_width ? film_width : film_height
    ) film_dimension / 2 + peg_radius + peg_gap;

// Unified peg positioning function that can handle both Omega-D and LPL-Saunders approaches
function calculate_unified_peg_positions(
    film_format_str,
    orientation_str,
    peg_diameter,
    peg_gap_val,
    adjust_film_width_val = 0,
    adjust_film_height_val = 0,
    positioning_style = "omega", // ["omega", "lpl"]
    film_peg_distance = undef // Required for omega style, ignored for lpl style
) =
    let (
        film_height_raw = get_film_format_height(film_format_str) + adjust_film_height_val,
        film_width_raw = get_film_format_width(film_format_str) + adjust_film_width_val,
        effective_orientation = get_effective_orientation(film_format_str, orientation_str),
        peg_radius = peg_diameter / 2,

        // Calculate positions based on style
        pos_x = (positioning_style == "omega") ?
            calculate_omega_style_peg_coordinate(
                is_dominant_film_dimension=(effective_orientation == "vertical"),
                film_width_or_equiv_half=film_width_raw / 2,
                film_peg_distance_half=film_peg_distance / 2,
                peg_radius=peg_radius,
                omega_internal_gap_value=calculate_internal_peg_gap(film_format_str, peg_gap_val)
            )
        : calculate_lpl_style_peg_coordinate(
            effective_orientation=effective_orientation,
            film_height=film_height_raw,
            film_width=film_width_raw,
            peg_radius=peg_radius,
            peg_gap=peg_gap_val,
            is_x_coordinate=true
        ),
        pos_y = (positioning_style == "omega") ?
            calculate_omega_style_peg_coordinate(
                is_dominant_film_dimension=(effective_orientation == "horizontal"),
                film_width_or_equiv_half=film_width_raw / 2,
                film_peg_distance_half=film_peg_distance / 2,
                peg_radius=peg_radius,
                omega_internal_gap_value=calculate_internal_peg_gap(film_format_str, peg_gap_val)
            )
        : calculate_lpl_style_peg_coordinate(
            effective_orientation=effective_orientation,
            film_height=film_height_raw,
            film_width=film_width_raw,
            peg_radius=peg_radius,
            peg_gap=peg_gap_val,
            is_x_coordinate=false
        )
    ) [pos_x, pos_y];

// Generate peg features (printed pegs or holes for pegs/inserts)
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
        if (_top_or_bottom == "top") {
            if (_printed_or_heat_set == "printed") {
                pegs_feature(
                    is_hole=true,
                    peg_diameter=_peg_dia,
                    peg_height=_peg_h,
                    peg_pos_x=_peg_x,
                    peg_pos_y=_peg_y,
                    z_offset=_z_off
                );
            } else {
                heat_set_pegs_socket_head_opening(
                    peg_height=_peg_h,
                    peg_pos_x=_peg_x,
                    peg_pos_y=_peg_y,
                    z_offset=_z_off
                );
            }
        } else {
            if (_printed_or_heat_set == "heat_set") {
                heat_set_pegs_holes(
                    peg_height=_peg_h,
                    peg_pos_x=_peg_x,
                    peg_pos_y=_peg_y,
                    z_offset=_z_off
                );
            }
        }
    } else {
        if (_top_or_bottom == "bottom" && _printed_or_heat_set == "printed") {
            pegs_feature(
                is_hole=false,
                peg_diameter=_peg_dia,
                peg_height=_peg_h,
                peg_pos_x=_peg_x,
                peg_pos_y=_peg_y,
                z_offset=_z_off
            );
        }
    }
}

// Instantiate a specific alignment board based on type string
module instantiate_alignment_board_by_type(board_type_str) {
    if (board_type_str == "omega") {
        omega_d_alignment_board_no_screws();
    } else if (board_type_str == "lpl-saunders") {
        lpl_saunders_alignment_board();
    } else if (board_type_str == "beseler-23c") {
        beseler_23c_alignment_board();
    } else {
        echo(str("Warning: Unknown alignment board type specified: ", board_type_str));
    }
}

// Generate subtractive peg features (holes)
module generate_all_peg_features(
    _top_or_bottom,
    _peg_style_param,
    _peg_diameter_param,
    _peg_actual_height_param,
    _peg_pos_x_param,
    _peg_pos_y_param,
    _peg_z_offset_param
) {
    generate_peg_features(
        _top_or_bottom=_top_or_bottom,
        _printed_or_heat_set=_peg_style_param,
        _peg_dia=_peg_diameter_param,
        _peg_h=_peg_actual_height_param,
        _peg_x=_peg_pos_x_param,
        _peg_y=_peg_pos_y_param,
        _z_off=_peg_z_offset_param,
        _is_subtraction_pass=true
    );
}

// Generate additive peg features (printed pegs)
module generate_additive_peg_features(
    _top_or_bottom,
    _peg_style_param,
    _peg_diameter_param,
    _peg_actual_height_param,
    _peg_pos_x_param,
    _peg_pos_y_param,
    _peg_z_offset_param
) {
    generate_peg_features(
        _top_or_bottom=_top_or_bottom,
        _printed_or_heat_set=_peg_style_param,
        _peg_dia=_peg_diameter_param,
        _peg_h=_peg_actual_height_param,
        _peg_x=_peg_pos_x_param,
        _peg_y=_peg_pos_y_param,
        _z_off=_peg_z_offset_param,
        _is_subtraction_pass=false
    );
}

// Process a carrier-specific base shape by adding standard film opening and peg features
module carrier_base_processing(
    _top_or_bottom,
    _carrier_material_height,
    _opening_height_param,
    _opening_width_param,
    _opening_cut_through_ext_param,
    _opening_fillet_param,
    _peg_style_param,
    _peg_diameter_param,
    _peg_actual_height_param,
    _peg_pos_x_param,
    _peg_pos_y_param,
    _peg_z_offset_param
) {
    difference() {
        children(0);

        film_opening(
            opening_height=_opening_height_param,
            opening_width=_opening_width_param,
            carrier_height=_carrier_material_height,
            cut_through_extension=_opening_cut_through_ext_param,
            frame_fillet=_opening_fillet_param
        );

        generate_all_peg_features(
            _top_or_bottom, _peg_style_param, _peg_diameter_param,
            _peg_actual_height_param, _peg_pos_x_param, _peg_pos_y_param, _peg_z_offset_param
        );
    }

    generate_additive_peg_features(
        _top_or_bottom, _peg_style_param, _peg_diameter_param,
        _peg_actual_height_param, _peg_pos_x_param, _peg_pos_y_param, _peg_z_offset_param
    );
}

// Generate a standardized test frame for checking film fit and peg alignment
module generate_test_frame(
    _effective_test_piece_role,
    _frame_material_height,
    _film_opening_h,
    _film_opening_w,
    _film_opening_cut_ext,
    _film_opening_f,
    _peg_style,
    _peg_dia_val,
    _peg_h_val,
    _peg_x_val,
    _peg_y_val,
    _peg_z_val,
    _test_cuboid_width,
    _test_cuboid_depth
) {
    union() {
        generate_additive_peg_features(
            _effective_test_piece_role, _peg_style, _peg_dia_val,
            _peg_h_val, _peg_x_val, _peg_y_val, _peg_z_val
        );

        difference() {
            cuboid([_test_cuboid_depth, _test_cuboid_width, _frame_material_height], anchor=CENTER);

            film_opening(
                opening_height=_film_opening_h,
                opening_width=_film_opening_w,
                carrier_height=_frame_material_height,
                cut_through_extension=_film_opening_cut_ext,
                frame_fillet=_film_opening_f
            );

            generate_all_peg_features(
                _effective_test_piece_role, _peg_style, _peg_dia_val,
                _peg_h_val, _peg_x_val, _peg_y_val, _peg_z_val
            );
        }
    }
}

// Creates the standard four-hole footprint for alignment board screws
module alignment_footprint_holes(_screw_dia, _dist_for_x_coords, _dist_for_y_coords, _carrier_h, _cut_ext, _is_dent, _dent_depth) {
    hole_radius = _is_dent ? _screw_dia / 2 + DENT_TOLERANCE : _screw_dia / 2;
    actual_hole_height = _is_dent ? _dent_depth : _carrier_h + _cut_ext;
    use_center_alignment = !_is_dent;
    z_val_for_hole = _is_dent ? ( -_carrier_h / 2) : 0;

    eff_spacing_x = _dist_for_x_coords / 2;
    eff_spacing_y = _dist_for_y_coords / 2;

    for (x_mult = [-1, 1]) {
        for (y_mult = [-1, 1]) {
            translate([eff_spacing_x * x_mult, eff_spacing_y * y_mult, z_val_for_hole])
                cylinder(h=actual_hole_height, r=hole_radius, center=use_center_alignment);
        }
    }
}

// ============================================================================
// DIRECTIONAL ARROW ETCHING FUNCTIONALITY
// ============================================================================

// Default arrow dimensions - can be overridden by calling modules
ARROW_LENGTH = 8;
ARROW_WIDTH = 5;
ARROW_ETCH_DEPTH = 0.5;

/**
 * Creates a left-pointing arrow shape for directional etching
 * Used to indicate film orientation on square format carriers (like 6x6)
 * @param etch_depth Depth of the etched arrow
 * @param length Arrow length
 * @param width Arrow width
 */
module arrow_etch(etch_depth = 0.5, length = 5, width = 3) {
    translate([-10, 0, .5])
        linear_extrude(height=etch_depth + 0.1)
            polygon(points=[[-length / 2, 0], [length / 2, width / 2], [length / 2, -width / 2]]);
}

/**
 * Determines if a film format needs directional arrows
 * Currently only 6x6 formats need arrows since they're square
 */
function needs_directional_arrow(film_format_str) =
    film_format_str == "6x6" || film_format_str == "6x6 filed";

/**
 * Calculates arrow position and rotation based on film format and orientation
 * Returns [x_pos, y_pos, rotation_angle]
 */
function calculate_arrow_position(film_format_str, orientation_str, opening_width, opening_height, arrow_length = 8, arrow_offset = 5) =
    let (
        effective_orientation = get_effective_orientation(film_format_str, orientation_str)
    )
    // For 6x6, opening is square so we can use either dimension
    (effective_orientation == "vertical") ?
        [10, -(opening_width / 2 + arrow_offset + arrow_length / 2), 0] // Vertical: arrow points left, positioned below
    : [0, -(opening_height / 2 + arrow_offset + arrow_length / 2), 90]; // Horizontal: arrow points up, positioned to the right

/**
 * Generates directional arrow etching for appropriate film formats
 * This is the main function that should be called by carrier implementations
 * @param film_format_str The film format string (e.g., "6x6", "35mm")
 * @param orientation_str The orientation string ("vertical" or "horizontal")
 * @param opening_width Width of the film opening
 * @param opening_height Height of the film opening
 * @param arrow_length Length of the arrow (default: 8)
 * @param arrow_width Width of the arrow (default: 5)
 * @param arrow_etch_depth Depth of the arrow etching (default: 0.5)
 * @param arrow_offset Distance from opening edge to arrow (default: 5)
 */
module generate_directional_arrow_etch(
    film_format_str,
    orientation_str = "vertical",
    opening_width = 56,
    opening_height = 56,
    arrow_length = 8,
    arrow_width = 5,
    arrow_etch_depth = 0.5,
    arrow_offset = 5
) {
    if (needs_directional_arrow(film_format_str)) {
        arrow_pos = calculate_arrow_position(
            film_format_str, orientation_str, opening_width, opening_height, arrow_length, arrow_offset
        );

        translate([arrow_pos[0], arrow_pos[1], 0])
            rotate([0, 0, arrow_pos[2]])
                arrow_etch(etch_depth=arrow_etch_depth, length=arrow_length, width=arrow_width);
    }
}
