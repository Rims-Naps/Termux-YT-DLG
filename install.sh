#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

STORAGE_PATH="$HOME/storage/shared"

DOWNLOAD_DIR="$STORAGE_PATH/Download/Termux-YT-DLG"

TMP_DIR="$STORAGE_PATH/.termux-yt-dlg/tmp"
STATE_DIR="$STORAGE_PATH/.termux-yt-dlg/state"
LOG_DIR="$STORAGE_PATH/.termux-yt-dlg/logs"
INSTALL_LOG="$LOG_DIR/install.log"

mkdir -p -- "$LOG_DIR"
exec > >(tee -a "$INSTALL_LOG") 2>&1

echo "Cleaning up previous installation..."
rm -f "$HOME/bin/termux-url-opener" "$HOME/bin/termux-url-opener-update" 2>/dev/null

if [[ -f "$HOME/.config/yt-dlp/config" ]]; then
    cp -f "$HOME/.config/yt-dlp/config" "$HOME/.config/yt-dlp/config.bak"
    echo "Existing yt-dlp config backed up to $HOME/.config/yt-dlp/config.bak"
fi

echo "Updating Termux packages..."
pkg update -y -o Dpkg::Options::="--force-confnew"
pkg upgrade -y -o Dpkg::Options::="--force-confnew"

echo "Requesting storage access..."
termux-setup-storage
sleep 2

echo "Installing required packages..."
pkg install -y -o Dpkg::Options::="--force-confnew" wget python ffmpeg aria2 termux-api
python -m pip install -U "yt-dlp[default]"

echo "Creating download directory..."
mkdir -p -- "$DOWNLOAD_DIR" "$TMP_DIR" "$STATE_DIR" "$LOG_DIR"

echo "Downloading Termux URL Opener script..."
mkdir -p "$HOME/bin"
wget --no-check-certificate --retry-connrefused --tries=3 -O "$HOME/bin/termux-url-opener" "https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/refs/heads/additional-functionality-WIP/termux-url-opener"
chmod +x "$HOME/bin/termux-url-opener"

echo "Installing termux-url-opener-update helper..."
cat > "$HOME/bin/termux-url-opener-update" << 'EOL'
#!/data/data/com.termux/files/usr/bin/bash
BASE_DIR="$HOME/storage/shared"
CUSTOM_SCRIPT_SOURCE="$BASE_DIR/termux-url-opener"
INSTALLED_SCRIPT_TARGET="$HOME/bin/termux-url-opener"

if [[ -f "$CUSTOM_SCRIPT_SOURCE" ]]; then
    mkdir -p -- "$(dirname -- "$INSTALLED_SCRIPT_TARGET")"
    mv -f -- "$CUSTOM_SCRIPT_SOURCE" "$INSTALLED_SCRIPT_TARGET"
    chmod +x -- "$INSTALLED_SCRIPT_TARGET"
    echo "The termux-url-opener file has been moved from $CUSTOM_SCRIPT_SOURCE to $INSTALLED_SCRIPT_TARGET."
fi
EOL
chmod +x "$HOME/bin/termux-url-opener-update"

echo "Verifying installation..."
for command_name in yt-dlp ffmpeg aria2c; do
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "  $command_name: OK"
    else
        echo "  $command_name: MISSING"
    fi
done
for command_name in termux-notification termux-toast termux-media-scan; do
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "  $command_name: OK"
    else
        echo "  $command_name: unavailable; related quality-of-life behavior will be skipped"
    fi
done
if [[ -x "$HOME/bin/termux-url-opener-update" ]]; then
    echo "  termux-url-opener-update: OK (run it any time to manually pick up a custom script)"
fi

mkdir -p "$HOME/.config/yt-dlp"
cat > "$HOME/.config/yt-dlp/config" << EOL
--no-mtime
--embed-thumbnail
--embed-metadata
--add-metadata
--ffmpeg-location /data/data/com.termux/files/usr/bin
-o $DOWNLOAD_DIR/%(title)s.%(ext)s
EOL

echo "Installation/update complete!"
echo "Downloads: $DOWNLOAD_DIR"
echo "Install log: $INSTALL_LOG"
echo "Download log: $LOG_DIR/download.log"
echo "To manually pick up a custom termux-url-opener placed at $STORAGE_PATH/termux-url-opener, run: termux-url-opener-update"
