#!/data/data/com.termux/files/usr/bin/bash

# Termux-YTD Installation/Update Script

STORAGE_PATH="/data/data/com.termux/files/home/storage/shared"

# Cleanup previous installation (for updates)
echo "Cleaning up previous installation..."
rm -f "$HOME/bin/termux-url-opener" 2>/dev/null
rm -rf "$HOME/.config/yt-dlp" 2>/dev/null

# Update and upgrade Termux packages
echo "Updating Termux packages..."
apt-get update && apt-get upgrade -y

# Request storage permission for Termux
echo "Requesting storage access..."
termux-setup-storage
sleep 3

# Install required packages
echo "Installing Python, ffmpeg, and yt-dlp..."
pkg install python ffmpeg -y

# Install/update yt-dlp to latest version
pip install --upgrade pip
pip install --upgrade yt-dlp

# Create download folders
echo "Creating directories for downloads..."
mkdir -p "$STORAGE_PATH/New" "$STORAGE_PATH/Music" "$STORAGE_PATH/YouTube" "$STORAGE_PATH/Unknown"

# Set up enhanced URL opener script
echo "Setting up Termux URL Opener script..."
mkdir -p "$HOME/bin"

# Download the fixed script
curl -L -o "$HOME/bin/termux-url-opener" "https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/main/termux-url-opener"
chmod +x "$HOME/bin/termux-url-opener"

# Verify yt-dlp installation
echo "Verifying yt-dlp installation..."
if yt-dlp --version >/dev/null 2>&1; then
    echo "yt-dlp installed successfully: $(yt-dlp --version)"
else
    echo "Warning: yt-dlp installation may have issues"
fi

# Set up optimized yt-dlp config
echo "Setting up yt-dlp configuration..."
mkdir -p "$HOME/.config/yt-dlp"
cat > "$HOME/.config/yt-dlp/config" <<EOL
# yt-dlp global configuration
--no-mtime
--embed-thumbnail
--write-description
--write-info-json
--ignore-errors
--no-warnings
--extractor-args youtube:player_client=android,web
EOL

# Installation complete
echo ""
echo "================================================================"
echo "Installation/update complete!"
echo "================================================================"
echo "Share a video or music link with Termux to start downloading."
echo "Downloads will be saved to: $STORAGE_PATH/New"
echo "Check logs at: $STORAGE_PATH/yt_dlp_log.txt"
echo "================================================================"
