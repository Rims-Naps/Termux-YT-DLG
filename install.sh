#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

STORAGE_PATH="$HOME/storage/shared"
AUDIO_DIR="$STORAGE_PATH/Music/New"
VIDEO_DIR="$STORAGE_PATH/Movies/New"
TMP_DIR="$STORAGE_PATH/.termux-yt-dlg/tmp"
STATE_DIR="$STORAGE_PATH/.termux-yt-dlg/state"
LOG_DIR="$STORAGE_PATH/.termux-yt-dlg/logs"
INSTALL_LOG="$LOG_DIR/install.log"
SCRIPT_URL="https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/781bd92a6e0cdb5629d36abf244b1c710982ccc1/termux-url-opener"

mkdir -p -- "$LOG_DIR"
exec > >(tee -a "$INSTALL_LOG") 2>&1

echo "Cleaning up previous installation..."
rm -f "$HOME/bin/termux-url-opener" 2>/dev/null

if [[ -f "$HOME/.config/yt-dlp/config" ]]; then
    cp -f "$HOME/.config/yt-dlp/config" "$HOME/.config/yt-dlp/config.bak"
    echo "Existing yt-dlp config backed up to $HOME/.config/yt-dlp/config.bak"
fi

echo "Updating Termux packages..."
pkg update -y
pkg upgrade -y

echo "Requesting storage access..."
termux-setup-storage
sleep 2

echo "Installing required packages..."
pkg install -y python ffmpeg aria2 termux-api
python -m pip install -U "yt-dlp[default]"

echo "Creating download directories..."
mkdir -p -- "$AUDIO_DIR" "$VIDEO_DIR" "$TMP_DIR" "$STATE_DIR" "$LOG_DIR"

echo "Downloading Termux URL Opener script..."
mkdir -p "$HOME/bin"
curl -fL --retry 3 -o "$HOME/bin/termux-url-opener" "$SCRIPT_URL"
chmod +x "$HOME/bin/termux-url-opener"

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

mkdir -p "$HOME/.config/yt-dlp"
cat > "$HOME/.config/yt-dlp/config" << EOL
--no-mtime
--embed-thumbnail
--embed-metadata
--add-metadata
--ffmpeg-location /data/data/com.termux/files/usr/bin
-o $VIDEO_DIR/%(title)s.%(ext)s
EOL

echo "Installation/update complete!"
echo "Audio downloads: $AUDIO_DIR"
echo "Video downloads: $VIDEO_DIR"
echo "Logs: $LOG_DIR"
