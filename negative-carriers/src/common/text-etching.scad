// Text etching functionality for negative carriers
// Provides shared text etching and multi-material text generation modules

include <BOSL2/std.scad>
include <carrier-features.scad>

/**
 * Generates multi-material text parts for separate printing
 * Creates solid text objects positioned for multi-color printing
 * 
 * @param owner_name The owner name text to render
 * @param type_name The carrier type name text to render
 * @param enable_owner_etch Whether to render owner name text
 * @param enable_type_etch Whether to render type name text
 * @param owner_position [x, y, z] position for owner text
 * @param type_position [x, y, z] position for type text
 * @param owner_rotation [rx, ry, rz] rotation for owner text
 * @param type_rotation [rx, ry, rz] rotation for type text
 * @param font_face Font to use for text
 * @param font_size Font size for text
 * @param text_height Height of solid text for multi-material printing
 * @param text_as_separate_parts Whether to generate separate text parts
 * @param which_part Part selection for multi-material output
 */
module generate_shared_multi_material_text_parts(
    owner_name,
    type_name,
    enable_owner_etch,
    enable_type_etch,
    owner_position,
    type_position,
    owner_rotation,
    type_rotation,
    font_face,
    font_size,
    text_height,
    text_as_separate_parts,
    which_part
) {
    if (text_as_separate_parts) {
        if (enable_owner_etch) {
            SharedPart("OwnerText", which_part)
                rotate(owner_rotation) translate(owner_position)
                        text_solid(
                            text_string=owner_name,
                            font=font_face,
                            size=font_size,
                            height=text_height,
                            halign="right",
                            valign="top"
                        );
        }
        if (enable_type_etch) {
            SharedPart("TypeText", which_part)
                rotate(type_rotation) translate(type_position)
                        text_solid(
                            text_string=type_name,
                            font=font_face,
                            size=font_size,
                            height=text_height,
                            halign="left",
                            valign="top"
                        );
        }
    }
}

/**
 * Generates text etch subtractions for owner and type names
 * Creates recessed text areas on the carrier surface
 * 
 * @param owner_name The owner name text to etch
 * @param type_name The carrier type name text to etch
 * @param enable_owner_etch Whether to etch owner name
 * @param enable_type_etch Whether to etch type name
 * @param owner_position [x, y, z] position for owner text etch
 * @param type_position [x, y, z] position for type text etch
 * @param owner_rotation [rx, ry, rz] rotation for owner text etch
 * @param type_rotation [rx, ry, rz] rotation for type text etch
 * @param font_face Font to use for text
 * @param font_size Font size for text
 * @param etch_depth Depth of text etching
 */
module generate_shared_text_etch_subtractions(
    owner_name,
    type_name,
    enable_owner_etch,
    enable_type_etch,
    owner_position,
    type_position,
    owner_rotation,
    type_rotation,
    font_face,
    font_size,
    etch_depth
) {
    if (enable_owner_etch) {
        rotate(owner_rotation) translate(owner_position)
                text_etch(
                    text_string=owner_name,
                    font=font_face,
                    size=font_size,
                    etch_depth=etch_depth,
                    halign="right",
                    valign="top"
                );
    }
    if (enable_type_etch) {
        rotate(type_rotation) translate(type_position)
                text_etch(
                    text_string=type_name,
                    font=font_face,
                    size=font_size,
                    etch_depth=etch_depth,
                    halign="left",
                    valign="top"
                );
    }
}

/**
 * Shared part gating module for multi-material printing
 * Controls which parts are rendered based on selection
 * @param DoPart Part name to conditionally render
 * @param WhichPart Current part selection from carrier
 */
module SharedPart(DoPart, WhichPart) {
    color(SharedPartColor(DoPart)) {
        if (WhichPart == "All" || DoPart == WhichPart) {
            children();
        }
    }
}

/**
 * Maps part names to preview colors for multi-material visualization
 * @param part Part name string
 * @return Color name for OpenSCAD preview
 */
function SharedPartColor(part) =
    (part == "Base") ? "grey"
    : (part == "OwnerText") ? "orange"
    : (part == "TypeText") ? "purple"
    : "gray";

/**
 * Validates that text fits within specified boundary constraints
 * @param text_string The text to validate
 * @param font_face Font to use for measurement
 * @param font_size Font size for measurement
 * @param center_x X coordinate of text center
 * @param center_y Y coordinate of text center
 * @param rotation_angle Rotation angle in degrees (for calculating rotated bounds)
 * @param safe_min_x Minimum allowed X boundary
 * @param safe_max_x Maximum allowed X boundary
 * @param safe_min_y Minimum allowed Y boundary
 * @param safe_max_y Maximum allowed Y boundary
 * @param text_label Label for error messages (e.g., "Owner Name", "Type Name")
 */
module validate_text_bounds(
    text_string,
    font_face,
    font_size,
    center_x,
    center_y,
    rotation_angle,
    safe_min_x,
    safe_max_x,
    safe_min_y,
    safe_max_y,
    text_label
) {
    text_metrics = textmetrics(text=text_string, font=font_face, size=font_size, halign="center", valign="center");

    // Calculate rotated dimensions (for 270° rotation, width and height swap)
    rotated_size_x = (rotation_angle == 270) ? text_metrics.size[1] : text_metrics.size[0];
    rotated_size_y = (rotation_angle == 270) ? text_metrics.size[0] : text_metrics.size[1];

    text_min_x = center_x - rotated_size_x / 2;
    text_max_x = center_x + rotated_size_x / 2;
    text_min_y = center_y - rotated_size_y / 2;
    text_max_y = center_y + rotated_size_y / 2;

    assert(
        text_min_x >= safe_min_x && text_max_x <= safe_max_x,
        str("ERROR: ", text_label, " '", text_string, "' X dimension [", text_min_x, ", ", text_max_x, "] exceeds safe area X [", safe_min_x, ", ", safe_max_x, "]. Consider shortening the name or adjusting position.")
    );
    assert(
        text_min_y >= safe_min_y && text_max_y <= safe_max_y,
        str("ERROR: ", text_label, " '", text_string, "' Y dimension [", text_min_y, ", ", text_max_y, "] exceeds safe area Y [", safe_min_y, ", ", safe_max_y, "]. Consider shortening the name or adjusting position.")
    );
}
