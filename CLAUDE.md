# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DarkroomSCAD is an OpenSCAD-based project that generates parametric 3D models for darkroom equipment, primarily negative carriers for different enlarger types. The project uses a modular architecture with shared components and enlarger-specific implementations.

## Prerequisites and Dependencies

- **OpenSCAD Nightly Build Required**: The project uses features only available in nightly builds of OpenSCAD
- **BOSL2 Library**: All `.scad` files depend on the BOSL2 library which must be properly installed
- **OpenSCAD Configuration**:
  - Enable `textmetrics` feature in preferences
  - Set 3D rendering engine to "Manifold (new/fast)" for better performance

## Architecture

The project follows a hierarchical modular structure:

### Core Architecture

- `negative-carriers/carrier.scad` - Main parametric interface with all configuration options
- `negative-carriers/src/*.scad` - Enlarger-specific implementations (omega-d, lpl-saunders-45xx, beseler-23c)
- `negative-carriers/src/common/*.scad` - Shared modules and functionality

### Key Shared Modules

- `film-sizes.scad` - Defines dimensions for all supported film formats (35mm, medium format, 4x5)
- `carrier-features.scad` - Core geometric functions for film openings, pegs, heat-set inserts
- `text-etching.scad` - Text etching and multi-material printing support
- `*-alignment-board.scad` - Enlarger-specific alignment board geometries

### Enlarger Support

- **Omega-D**: Full implementation with alignment board support
- **LPL Saunders 45xx**: Complete carrier system
- **Beseler 23C**: Basic implementation

## File Organization

```
negative-carriers/
├── carrier.scad                    # Main parametric interface
└── src/
    ├── omega-d.scad               # Omega-D specific implementation
    ├── lpl-saunders-45xx.scad     # LPL Saunders implementation  
    ├── beseler-23c.scad           # Beseler implementation
    ├── omega-d.json               # Configuration data
    └── common/                    # Shared functionality
        ├── film-sizes.scad        # Film format dimensions
        ├── carrier-features.scad  # Core geometric modules
        ├── text-etching.scad      # Text/etching functionality
        └── *-alignment-board.scad # Enlarger-specific boards
```

## Development Workflow

### Testing and Validation

- Open `.scad` files in OpenSCAD to preview and validate geometry
- Use F5 for quick preview, F6 for full render
- Test different parameter combinations, especially film formats and orientations
- Verify text etching renders correctly with different fonts and sizes

### Code Style

- Use descriptive parameter names with underscores (e.g., `Enable_Owner_Name_Etch`)
- Include parameter constraints in comments using OpenSCAD customizer syntax: `// ["option1", "option2"]`
- Group related parameters in customizer sections using `/* [Section Name] */`
- Document module parameters using JSDoc-style comments
- Use consistent naming: enlarger-specific prefixes, descriptive function names

### Key Parameters

All enlarger implementations share these core parameters:

- `Top_or_Bottom`: Carrier part selection
- `Film_Format`: Supported formats from film-sizes.scad
- `Orientation`: Film orientation (vertical/horizontal)
- `Printed_or_Heat_Set_Pegs`: Peg attachment method
- `Owner_Name`, `Type_Name`: Text etching options
- `Fontface`, `Font_Size`, `TEXT_ETCH_DEPTH`: Typography settings

### Multi-Material Support

The codebase includes advanced multi-material printing support:

- `Text_As_Separate_Parts`: Enables separate text part generation
- `_WhichPart`: Selects specific parts for STL export ("All", "Base", "OwnerText", "TypeText")
- Text parts are positioned for multi-color printing workflows

## Common Constants and Tolerances

Defined in `carrier-features.scad`:

- `PEG_HOLE_TOLERANCE = 0.25`: Additional radius for peg holes
- `M2_HEAT_SET_HOLE_DIA = 1.6`: M2 heat-set insert hole diameter
- `TEXT_ETCH_OVEREXTRUDE = 0.2`: Extra depth for reliable text subtraction

## File Dependencies

When working with individual `.scad` files, ensure these includes are present:

- `include <BOSL2/std.scad>`
- `include <common/film-sizes.scad>`
- `include <common/carrier-features.scad>`
- `include <common/text-etching.scad>`
- Enlarger-specific alignment board includes as needed
