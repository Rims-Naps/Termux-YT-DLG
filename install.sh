#!/data/data/com.termux/files/usr/bin/bash


STORAGE_PATH="/data/data/com.termux/files/home/storage/shared"
SCRIPT_URL="https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/feature/auto-return-to-previous-app/termux-url-opener"

echo "Cleaning up previous installation..."
rm -f "$HOME/bin/termux-url-opener" 2>/dev/null

if [[ -f "$HOME/.config/yt-dlp/config" ]]; then
    cp "$HOME/.config/yt-dlp/config" "$HOME/.config/yt-dlp/config.bak"
    echo "Existing yt-dlp config backed up to: $HOME/.config/yt-dlp/config.bak"
fi
rm -rf "$HOME/.config/yt-dlp" 2>/dev/null

echo "Updating Termux packages..."
apt-get update && apt-get upgrade -y

echo "Requesting storage access..."
echo "NOTE: A permission dialog will appear — tap 'Allow'. The script will continue automatically."
termux-setup-storage
sleep 5

echo "Installing Python, ffmpeg, and yt-dlp..."
pkg install python ffmpeg -y

echo "Installing yt-dlp nightly build..."
pip install --upgrade pip
pip install -U --pre "yt-dlp[default]"

echo "Creating download directory..."
mkdir -p "$STORAGE_PATH/New"

echo "Downloading Termux URL Opener script..."
mkdir -p "$HOME/bin"

if curl -fL -o "$HOME/bin/termux-url-opener" "$SCRIPT_URL"; then
    chmod +x "$HOME/bin/termux-url-opener"
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
cat > "$HOME/.config/yt-dlp/config" << 'EOL'
--no-mtime
--embed-thumbnail
--embed-metadata
--add-metadata
--ffmpeg-location /data/data/com.termux/files/usr/bin
-o /data/data/com.termux/files/home/storage/shared/New/%(title)s.%(ext)s
EOL

echo ""
echo "================================================================"
echo "Installation / update complete!"
echo "================================================================"
echo "  yt-dlp version : $(yt-dlp --version 2>/dev/null || echo 'unknown')"
echo "  Download folder: $STORAGE_PATH/New"
echo "  Log file       : $STORAGE_PATH/yt_dlp_log.txt"
echo "  Config file    : $HOME/.config/yt-dlp/config"
echo ""
echo "Share any video or music URL with Termux to start downloading."
echo "================================================================"
