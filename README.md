# Termux-YTD Enhanced

Termux-YTD Enhanced is a powerful tool designed to simplify the process of downloading videos and music directly to your Android device using the Termux terminal emulator. Built around `yt-dlp`, this script offers advanced features such as automated quality selection, a retry mechanism for failed downloads, and background downloading capabilities.

## Key Features

- **Automated Quality Selection**: Automatically selects the highest available quality for videos and music, ensuring optimal playback.
- **Retry Mechanism**: Implements a robust retry system to handle download interruptions, improving reliability.
- **Background Downloading**: Downloads run in the background, allowing you to multitask without interruptions.
- **Organized Downloads**: Files are automatically sorted into designated folders, keeping your media library tidy.

## Installation

Follow these steps to set up Termux-YTD Enhanced on your Android device:

1. **Install Termux**  
   Download and install the Termux APK from [F-Droid](https://f-droid.org/en/packages/com.termux/). The version on the Google Play Store may not function correctly.

2. **Open Termux**  
   Launch the Termux application on your device.

3. **Install Required Packages**  
   Update your Termux packages and install `wget` by running the following commands:
   ```bash
   pkg update
   pkg install wget -y
   ```

4. **Grant Storage Access**  
   Allow Termux to access your device's storage by executing:
   ```bash
   termux-setup-storage
   ```

5. **Download and Run the Installation Script**  
   Use the following command to download and execute the installation script:
   ```bash
   wget --no-check-certificate "https://raw.githubusercontent.com/Rims-Naps/termux-yt-dlp/master/install.sh" && chmod +x install.sh && bash install.sh
   ```

## Usage

To start downloading videos or music, simply share any URL from your browser or another application to the Termux app. The download process will begin automatically.

## Contributing

Contributions to improve Termux-YTD Enhanced are welcome! If you have suggestions or want to contribute code, please follow these steps:

1. Fork the repository.
2. Make your changes.
3. Submit a pull request with a detailed description of your improvements.

For more information, refer to the documentation within the repository.

---

Congratulations! You’ve successfully set up Termux-YTD Enhanced. Start downloading your favorite videos and music today, and build your perfect media library with ease.![tested](https://github.com/user-attachments/assets/5d63b023-1397-4875-9f0f-73b805f59f72)
