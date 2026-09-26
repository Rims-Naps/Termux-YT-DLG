# Termux-YTD Enhanced

Termux-YTD Enhanced is a powerful tool designed to simplify the process of downloading videos and music directly to your Android device using the Termux terminal emulator. Built around `yt-dlp`, this script offers automated quality selection, retry handling, background downloading, and additional download-management features.

## Key Features

- **Automated Quality Selection**: Automatically selects appropriate high-quality formats for videos and music.
- **Retry Mechanism**: Retries failed downloads up to three times.
- **Background Downloading**: Downloads run in the background by default. Set `BACKGROUND_DOWNLOAD=false` in `termux-url-opener` to make downloads synchronous.
- **Unified Download Directory**: Completed audio and video files are stored in `Download/Termux-YT-DLG`.
- **Google Link Unwrapping**: Automatically unwraps supported Google redirect URLs before downloading.
- **Metadata, Thumbnail & Chapter Embedding**: Embeds available metadata, thumbnails, and chapters.
- **aria2c Multi-Connection Downloads**: Uses aria2c with multiple connections when available, with a fallback to yt-dlp's native downloader.
- **Download Archive**: Maintains an archive to prevent already-downloaded items from being downloaded again.
- **Cookie Support**: Detects `cookies.txt` in `~/.config/yt-dlp/` or shared storage.
- **Termux:API Notifications**: Provides progress notifications and toasts when Termux:API is available.
- **Consolidated Logging**: Keeps download activity in `download.log`, capped at approximately 512 KB.
- **Custom Script Pickup**: A `termux-url-opener-update` helper can move a custom `termux-url-opener` from shared storage into `~/bin/`.

## Installation

Follow these steps to set up Termux-YTD Enhanced on your Android device:

1. **Install Termux**

   Download and install the Termux APK from [F-Droid](https://f-droid.org/en/packages/com.termux/). The version on the Google Play Store may not function correctly.

   For Termux:API notification features, also install the matching **Termux:API** companion app.

2. **Open Termux**

   Launch the Termux application on your device.

3. **Install Required Packages**

   Update your Termux packages and install `wget` by running:

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

   Use the following command to download and execute the installation script for the `additional-functionality-WIP` branch:

   ```bash
   wget --no-check-certificate "https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/refs/heads/additional-functionality-WIP/install.sh" && chmod +x install.sh && bash install.sh
   ```

   The installer installs the additional dependencies required by the enhanced version, including `python`, `ffmpeg`, `aria2`, `termux-api`, `wget`, and `yt-dlp`.

## Usage

To start downloading videos or music, simply share a URL from your browser or another application to Termux. The download process will begin automatically.

Completed downloads are placed in:

```text
Internal Storage/Download/Termux-YT-DLG/
```

To manually install a custom `termux-url-opener`, place it at:

```text
Internal Storage/termux-url-opener
```

Then run:

```bash
termux-url-opener-update
```

## Contributing

Contributions to improve Termux-YTD Enhanced are welcome! If you have suggestions or want to contribute code, please follow these steps:

1. Fork the repository.
2. Make your changes.
3. Submit a pull request with a detailed description of your improvements.

For more information, refer to the documentation within the repository.

---

Congratulations! You’ve successfully set up Termux-YTD Enhanced.![tested](https://github.com/user-attachments/assets/5d63b023-1397-4875-9f0f-73b805f59f72)
