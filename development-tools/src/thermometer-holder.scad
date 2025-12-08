/**
 * Thermometer Holder for Darkroom Containers
 *
 * A clip-on holder that attaches to container rims and holds a thermometer.
 * Optimized for 3D printing - no supports needed when printed on its side.
 */

include <BOSL2/std.scad>

/* [Thermometer Dimensions] */
// Diameter of thermometer shaft (mm)
Thermometer_Diameter = 4; // [1:0.5:15]

// Extra clearance for thermometer fit (mm)
Thermometer_Clearance = 0.5; // [0.2:0.1:1.5]

/* [Container Dimensions] */
// Thickness of container rim (mm)
Container_Rim_Thickness = 2; // [0.5:0.5:10]

// Depth of container rim hook (mm)
Container_Rim_Depth = 15; // [8:1:30]

// Extra clearance for container rim (mm)
Rim_Clearance = 0.5; // [0.2:0.1:2]

/* [Holder Dimensions] */
// Length of horizontal arm (mm)
Arm_Length = 60; // [40:5:120]

// Width of the holder (mm)
Holder_Width = 15; // [10:1:25]

// Thickness of material (mm)
Material_Thickness = 4; // [3:0.5:8]

/* [Rendering] */
$fn = 48;

// Calculated values
therm_hole_dia = Thermometer_Diameter + Thermometer_Clearance * 2;
rim_slot_width = Container_Rim_Thickness + Rim_Clearance * 2;
hook_total_width = rim_slot_width + Material_Thickness * 2;
hook_height = Container_Rim_Depth + Material_Thickness;

/**
 * Main thermometer holder - single unified shape
 */
module thermometer_holder() {
    difference() {
        // Main body as linear extrusion of 2D profile
        rotate([90, 0, 0])
            linear_extrude(height=Holder_Width, center=true)
                holder_profile();

        // Thermometer hole
        therm_hole_x = therm_hole_dia / 2 + 8;
        translate([therm_hole_x, 0, Material_Thickness / 2])
            cylinder(h=Material_Thickness + 2, d=therm_hole_dia, center=true);
    }
}

/**
 * 2D profile of the holder (view from the side)
 */
module holder_profile() {
    // Where the hook begins (inner wall)
    hook_inner_x = Arm_Length - hook_total_width;

    union() {
        // Horizontal arm
        square([Arm_Length, Material_Thickness]);

        // Hook - outer vertical (hangs down from arm)
        translate([Arm_Length - Material_Thickness, -hook_height + Material_Thickness])
            square([Material_Thickness, hook_height]);

        // Hook - inner vertical (shorter, creates the open U-shape for rim)
        // This piece only extends down partway to leave bottom open
        translate([hook_inner_x, -Container_Rim_Depth])
            square([Material_Thickness, Container_Rim_Depth + Material_Thickness]);

        // Support brace
        brace_top_x = therm_hole_dia + 12;
        brace_bottom_y = -Container_Rim_Depth;

        polygon(
            [
                [brace_top_x, 0], // Top left of brace
                [brace_top_x + Material_Thickness, 0], // Top right
                [hook_inner_x + Material_Thickness, brace_bottom_y], // Bottom right (connects to inner hook)
                [hook_inner_x, brace_bottom_y], // Bottom left
            ]
        );
    }
}

// Render the holder
rotate([90, 0, 0]) thermometer_holder();
