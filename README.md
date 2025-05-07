# DarkroomSCAD

## Open source 3D models for darkroom equipment

This project provides a collection of open-source 3D models for darkroom equipment, designed using OpenSCAD. The models are parametric, allowing for customization to fit various needs and film formats. Whether you need negative carriers, film developing tools, or other darkroom accessories, this library aims to provide a versatile and adaptable set of designs for the analog photography community.

## Getting Started

These instructions will help you get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Before you begin, ensure you have the following installed and configured:

- **OpenSCAD (Nightly Build):** This project requires features available in the nightly builds of OpenSCAD. The latest stable release is not compatible. You can find the nightly builds on the [OpenSCAD downloads page](https://openscad.org/downloads.html) (look further down the page).
- **BOSL2 Library:** This project relies on the BOSL2 library. You can find it at [https://github.com/revarbat/BOSL2](https://github.com/revarbat/BOSL2). Please ensure it is correctly installed and accessible by OpenSCAD.
- **Included Files:** Some `.scad` files may require other specific files to be present in the same directory or a properly configured library path. For example, `omega-d.scad` requires `film-sizes.scad` and `common-carrier-features.scad`.

## Installation

1.  **Download OpenSCAD:**
    - Go to the [OpenSCAD downloads page](https://openscad.org/downloads.html).
    - Download and install the **latest nightly build** suitable for your operating system.
2.  **Install BOSL2 Library:**
    - Follow the installation instructions provided on the [BOSL2 GitHub repository](https://github.com/revarbat/BOSL2). This typically involves cloning the repository or downloading a release and placing it in your OpenSCAD libraries folder.
3.  **Project Files:**
    - Clone or download this repository.
    - Ensure that any accompanying `.scad` files (like `film-sizes.scad` or `common-carrier-features.scad`) are located where the main `.scad` files can find them (e.g., in the same directory or a common library folder).

## Configuration

For optimal performance and to ensure all features work correctly, please configure the following in OpenSCAD:

1.  **Enable Text Metrics:**
    - Go to OpenSCAD `Preferences`.
    - Under the `Features` tab (or similar, depending on the OpenSCAD version).
    - Ensure that `textmetrics` is enabled.
2.  **Set 3D Rendering Engine:**
    - Go to OpenSCAD `Preferences`.
    - Change the `3D rendering engine` to `"Manifold (new/fast)"`. This can significantly speed up the rendering of complex files.

## Usage

To use the `.scad` files in this project:

1.  **Open the File:** Open the desired `.scad` file (e.g., `negative_carriers/src/omega-d.scad`) in OpenSCAD.
2.  **Customize Parameters:** Most `.scad` files will have a section at the top for customization. You can adjust these parameters to suit your needs. Common parameters include:
    - `Top_or_Bottom`: Specifies whether to generate the top or bottom part of a carrier.
    - `Orientation`: Sets the film orientation (e.g., "vertical", "horizontal").
    - `Film_Format`: Selects the film format (e.g., "35mm", "6x6", "4x5", "custom").
    - `Enable_Owner_Name_Etch`: Enables or disables etching of an owner's name.
    - `Owner_Name`: The text for the owner's name.
    - `Enable_Type_Name_Etch`: Enables or disables etching of the carrier type.
    - `Type_Name`: Predefined or custom type name for the carrier.
    - `Custom_Type_Name`: Custom text if `Type_Name` is set to "Custom".
    - `Fontface`: Font used for etchings.
    - `Font_Size`: Font size for etchings.
    - `TEXT_ETCH_DEPTH`: Depth of the text etchings.
    - `Peg_Gap`: Adjusts the gap between film pegs and the film edge.
    - `Adjust_Film_Width`: Fine-tunes the film width allowance.
    - `Adjust_Film_Height`: Fine-tunes the film height allowance.
    - _(Refer to the specific `.scad` file for a full list of available parameters and their descriptions.)_
3.  **Render and Export:**
    - Once customized, you can preview the model in OpenSCAD (usually by pressing F5 for preview or F6 to render).
    - To generate an STL file for 3D printing, choose `File > Export > Export as STL...`.

## Contributing

Contributions are welcome! If you'd like to contribute, please follow these general guidelines:

- **Fork the Repository:** Start by forking the main repository.
- **Create a Branch:** Create a new branch for your feature or bug fix.
- **Code Style:** Try to maintain a consistent code style with the existing codebase. Comment your code where necessary.
- **Test Your Changes:** Ensure your changes work as expected and do not introduce new issues.
- **Submit a Pull Request:** Once your changes are ready, submit a pull request with a clear description of the changes and why they were made.

## License

[This project is licensed under the MIT License.](LICENSE)
