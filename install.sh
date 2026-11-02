#!/data/data/com.termux/files/usr/bin/bash


STORAGE_PATH="$HOME/storage/shared"
AUDIO_DIR="$STORAGE_PATH/Music/New"
VIDEO_DIR="$STORAGE_PATH/Movies/New"
TMP_DIR="$STORAGE_PATH/.termux-yt-dlg/tmp"
LOG_DIR="$STORAGE_PATH/.termux-yt-dlg/logs"
SCRIPT_URL="https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/refs/heads/main/termux-url-opener"

echo "Updating Termux packages..."
apt-get update && apt-get upgrade -y

echo "Requesting storage access..."
echo "NOTE: A permission dialog will appear — tap 'Allow'. The script will continue automatically."
termux-setup-storage
sleep 5

echo "Installing Python, ffmpeg, and yt-dlp..."
pkg install python python-pip ffmpeg curl -y

echo "Installing yt-dlp nightly build..."
# pip itself is maintained by Termux's package manager.
pip install -U --pre "yt-dlp[default]"

echo "Creating download directories..."
mkdir -p -- "$AUDIO_DIR" "$VIDEO_DIR" "$TMP_DIR" "$LOG_DIR"

echo "Downloading Termux URL Opener script..."
mkdir -p "$HOME/bin"
opener_stage=$(mktemp "$HOME/bin/.termux-url-opener.XXXXXXXX") || exit 1
trap 'rm -f -- "$opener_stage"' EXIT

if curl -fL -o "$opener_stage" "$SCRIPT_URL" &&
    [[ -s "$opener_stage" ]] && bash -n "$opener_stage" &&
    chmod +x "$opener_stage" && mv -f -- "$opener_stage" "$HOME/bin/termux-url-opener"; then
    echo "termux-url-opener downloaded and marked executable."
else
    echo ""
    echo "================================================================"
    echo "ERROR: Failed to download termux-url-opener from GitHub."
    echo "Check your internet connection or the repository URL and re-run."
    echo "URL attempted: $SCRIPT_URL"
    echo "================================================================"
    exit 1
fi

echo "Verifying yt-dlp installation..."
if yt-dlp --version >/dev/null 2>&1; then
    echo "yt-dlp installed successfully: $(yt-dlp --version)"
else
    echo "WARNING: yt-dlp may not have installed correctly. Try running:"
    echo "  pip install -U --pre 'yt-dlp[default]'"
fi

echo "Writing yt-dlp configuration..."
mkdir -p "$HOME/.config/yt-dlp"
# Note: this default -o only applies when yt-dlp is run manually from the
# command line. Downloads triggered via the share-sheet go through
# termux-url-opener, which routes audio/video into separate directories and
# is unaffected by this default.
if [[ ! -e "$HOME/.config/yt-dlp/config" ]]; then
cat > "$HOME/.config/yt-dlp/config" << EOL
--no-mtime
--embed-thumbnail
--embed-metadata
--add-metadata
--ffmpeg-location /data/data/com.termux/files/usr/bin
-o $VIDEO_DIR/%(title)s.%(ext)s
EOL
fi

echo ""
echo "================================================================"
echo "Installation / update complete!"
echo "================================================================"
echo "  yt-dlp version   : $(yt-dlp --version 2>/dev/null || echo 'unknown')"
echo "  Audio downloads  : $AUDIO_DIR"
echo "  Video downloads  : $VIDEO_DIR"
echo "  Temp/incomplete  : $TMP_DIR"
echo "  Success log      : $LOG_DIR/success.log"
echo "  Error log        : $LOG_DIR/error.log"
echo "  Command history  : $LOG_DIR/command-history.log"
echo "  Config file      : $HOME/.config/yt-dlp/config"
echo ""
echo "Share any video or music URL with Termux to start downloading."
echo "================================================================"
