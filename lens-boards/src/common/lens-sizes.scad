// Film format lookup table
// Each entry: [format_name, mount_diameter, mount_thickness]
LENS_FORMATS = [
    ["Copal 0", 34.7, 3.75],
    ["Copal 1", 41.8, 3.75],
    ["Copal 3", 65, 4],
    ["Super Large Lens", 95, 4],
];

// Index constants for LENS_FORMATS table
_LF_NAME = 0;
_LF_MOUNT_DIAMETER = 1;
_LF_MOUNT_THICKNESS = 2;

// Core lookup function - returns the format entry or undef if not found
function _find_lens_format(format) =
    let (matches = [for (f = LENS_FORMATS) if (f[_LF_NAME] == format) f]) len(matches) > 0 ? matches[0] : undef;

// Unified function to get all lens format dimensions
// Returns: [mount_diameter, mount_thickness] or undef for unknown format
function get_lens_format(format) =
    let (entry = _find_lens_format(format)) entry != undef ? [entry[_LF_MOUNT_DIAMETER], entry[_LF_MOUNT_THICKNESS]]
    : undef;

// Backward-compatible accessor functions
function get_lens_format_mount_diameter(format) =
    get_lens_format(format)[0];

function get_lens_format_mount_thickness(format) =
    get_lens_format(format)[1];
