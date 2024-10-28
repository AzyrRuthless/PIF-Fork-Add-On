# PIF Fork Add-On by Azyr

This project is a personal adaptation and extension of the Play Integrity Fork script by osm0sis. It includes various enhancements and customizations for personal use only.

## Disclaimer

**This project is intended for personal use only.** Use at your own risk. The author is not responsible for any damage or issues caused by using this script.

## Features

- Simplified handling of build.prop files from `/vendor` and `/system`
- Script-only mode toggle
- Output generation in JSON format for integration with other scripts

## Installation

Please note, this project is for **personal use only**. The following installation steps are provided for individuals who wish to experiment with the script:

1. Download the script.
2. Give execute permissions:
    ```bash
    chmod +x PifAdd-On.sh
    ```
3. Run the script:
    ```bash
    ./PifAdd-On.sh
    ```

## Usage

Follow the prompts provided by the script to perform various operations, including:
- Executing autopif
- Handling build.prop files
- Toggling script-only mode

## What This Script Does

The script processes build.prop files to generate a JSON output that includes various build properties, such as manufacturer, model, fingerprint, brand, product, device, and more. Users can input their build.prop file, and the script will automatically convert it into a custom.pif.json format that is compatible with Play Integrity Fork. It ensures compatibility checks, handles vendor and system build properties separately, and can toggle a script-only mode for streamlined operations.

## Future Plans

There are plans to develop this project into a Magisk module in the future. However, it will still be for personal use only and won't be officially released. If you're interested in trying it out, feel free to check out the code.

## Why Upload to GitHub?

While this project is intended for personal use, sharing it on GitHub has several benefits:
- **Transparency:** Keeping the project open and accessible demonstrates adherence to open-source principles, especially given its reliance on the GPL v3 licensed code.
- **Community Feedback:** Even though it’s personal, others might find the modifications useful and provide constructive feedback.
- **Version Control:** GitHub offers a robust platform for version control, making it easier to track changes and improvements over time.
- **Future Reference:** Having it available publicly ensures that the project is not lost and can serve as a reference for future personal projects or similar tasks.

## Credits

- Original Play Integrity Fork by [osm0sis](https://github.com/osm0sis/PlayIntegrityFork)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0). For more details, see the [LICENSE](./LICENSE) file.