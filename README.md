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
   Download the Android APK from the official [Termux GitHub releases](https://github.com/termux/termux-app/releases). This project targets the GitHub build, not the Google Play version.

2. **Open Termux**  
   Launch the Termux application on your device.

3. **Install Required Packages**  
   Update package lists and install `curl`:
   ```bash
   pkg update
   pkg install curl -y
   ```

4. **Grant Storage Access**  
   Allow Termux to access your device's storage by executing:
   ```bash
   termux-setup-storage
   ```

5. **Download and Run the Installation Script**  
   Use the following command to download and execute the installation script:
   ```bash
   cd "$HOME"
   curl -fL --retry 3 -o install-yt-dlg.sh "https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/refs/heads/main/install.sh" &&
     bash -n install-yt-dlg.sh && bash install-yt-dlg.sh
   ```

   The same commands update an existing installation. Wait for current downloads
   to finish first. Existing yt-dlp and notification configurations are preserved.
   The installed opener is replaced only after the downloaded script passes a
   syntax check; a failed download leaves the previous opener in place.
   The installer retains its existing package-update and yt-dlp nightly-install
   steps. It also installs curl and uses Termux's packaged pip.

## Usage

To start downloading videos or music, simply share any URL from your browser or another application to the Termux app. The download process will begin automatically.

## Notifications and configuration

Notifications are optional and enabled by default. Install the optional
[Termux:API Android add-on](https://github.com/termux/termux-api) from its official
GitHub distribution: sign into GitHub in your browser, open the official
[Termux:API Actions](https://github.com/termux/termux-api/actions), choose a successful
GitHub Action Build on `master`, and download/extract the debug APK artifact under
Artifacts. Install that APK through Android, then run `pkg install termux-api`
inside Termux. The Android
add-on and CLI package are both required. Termux and its add-ons must use compatible
signatures: use GitHub builds together; do not mix GitHub and F-Droid APKs.
See the upstream [installation rules](https://github.com/termux/termux-app#installation).
Allow notifications for Termux:API in Android settings (including any permission
prompt on Android 13+). Android battery/background restrictions may affect delivery.

Create `$HOME/.config/termux-yt-dlg/config`:

```bash
mkdir -p "$HOME/.config/termux-yt-dlg"
cat > "$HOME/.config/termux-yt-dlg/config" <<'EOF'
NOTIFICATIONS=true
RETRY_PROMPTS=true
EOF
```

Set `NOTIFICATIONS=false` to disable all notifications. Set `RETRY_PROMPTS=false`
to keep completion/failure notifications without Retry/Dismiss actions. Use these
literal lines without spaces or quotes; this file is parsed as data, not executed.
Installation and updates preserve this file and existing yt-dlp configuration.
Defaults are only written for a missing yt-dlp configuration.

A completion notification reports the URL, type, file count, and successful attempt.
One failure notification appears only after the existing three attempts finish.
Retry explicitly starts one new three-attempt sequence for that URL; Dismiss or
swiping away does not retry. Repeated clicks on the same action cannot start more
downloads. A new exhausted sequence can offer another explicit Retry. No terminal
prompt is used. Concurrent downloads have separate notification IDs and private
retry state under `$HOME/.local/state/termux-yt-dlg`, independent of log retention.
Pending state remains until an action or notification deletion consumes it.
Missing tools, denied permissions, or API timeouts do not prevent downloads;
notification calls time out after ten seconds, with a two-second forced-kill grace
period. Existing notifications may remain
visible when Android cannot service a removal request.

## Error logs

The existing success, error-summary (including stderr), and command-history logs
remain under `$HOME/storage/shared/.termux-yt-dlg/logs`.
Each sequence with any failed attempt also gets a unique file in
`logs/failed-downloads/ytdlg-*.log`, even if a later automatic attempt succeeds.
It records the URL, start/end timestamps, attempt timestamps and numbers, exit
statuses, and yt-dlp stderr. Logs can contain private URLs and server output.

Only the newest 25 completed managed logs are kept. Publication and retention use
a process lock through the existing Python dependency. Active `.active` files are
excluded; concurrent writers may temporarily exceed 25 files. Interrupted writers
can leave `.active` files for manual inspection/removal. Unrelated files are never
retention candidates. Partial downloads keep their existing temporary-file behavior.
The retention lock lives in private Termux state, outside Android shared storage.

After installing the optional API add-on and granting notification permission,
check notification delivery without downloading media:

```bash
timeout --kill-after=2 10 termux-notification \
  --id ytdlg-install-test --title 'Termux-YT-DLG' --content 'Notifications are available'
```

If no notification appears, check the Termux:API notification permission/channel,
matching APK sources, and Android background restrictions. A successful command
exit alone does not prove Android displayed the notification.

## Local verification

Run `bash -n termux-url-opener install.sh` and `bash tests/run.sh` with Bash,
Python, and standard shell utilities available. Tests use local yt-dlp and API mocks;
they do not fetch media. On Android, separately validate notification permissions,
button delivery with Termux in the background, concurrent notifications, dismissal,
and missing/denied Termux:API behavior. Mock tests do not verify Android delivery.

## Contributing

Contributions to improve Termux-YTD Enhanced are welcome! If you have suggestions or want to contribute code, please follow these steps:

1. Fork the repository.
2. Make your changes.
3. Submit a pull request with a detailed description of your improvements.

For more information, refer to the documentation within the repository.

---

Congratulations! You’ve successfully set up Termux-YTD Enhanced. Start downloading your favorite videos and music today, and build your perfect media library with ease.![tested](https://github.com/user-attachments/assets/5d63b023-1397-4875-9f0f-73b805f59f72)
