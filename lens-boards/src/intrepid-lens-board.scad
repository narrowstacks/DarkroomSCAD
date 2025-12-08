include <common/lens-sizes.scad>

/* [Lens Settings] */
// Select lens mount type
Lens_Type = "Copal 0"; // ["Copal 0", "Copal 1", "Copal 3", "Super Large Lens"]

/* [Hidden] */
$fn = 100;
LENS_BOARD_WIDTH_HEIGHT = 140;

// Get lens dimensions from lookup table
_lens_dims = get_lens_format(Lens_Type);
_lens_mount_diameter = _lens_dims[0];
_lens_mount_thickness = _lens_dims[1];

module intrepid_lens_board(mount_diameter, board_thickness) {
    difference() {
        cube([LENS_BOARD_WIDTH_HEIGHT, LENS_BOARD_WIDTH_HEIGHT, board_thickness], center=true);
        cylinder(h=board_thickness + 0.1, d=mount_diameter, center=true);
    }
}

intrepid_lens_board(_lens_mount_diameter, _lens_mount_thickness);
