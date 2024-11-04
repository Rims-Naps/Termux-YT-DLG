#!/data/data/com.termux/files/usr/bin/bash

# Termux-YTD Installation Script

STORAGE_PATH="/data/data/com.termux/files/home/storage/shared"

# Update and upgrade Termux packages
echo "Updating Termux packages..."
apt-get update && apt-get upgrade -y

# Request storage permission for Termux
echo "Requesting storage access..."
termux-setup-storage
sleep 2

# Install required packages
echo "Installing Python, ffmpeg, and yt-dlp..."
pkg install python ffmpeg -y
pip install -U yt-dlp

# Create download folders
echo "Creating directories for downloads..."
mkdir -p "$STORAGE_PATH/Music" "$STORAGE_PATH/YouTube" "$STORAGE_PATH/Unknown"

# Set up enhanced URL opener script
echo "Setting up Termux URL Opener script..."
mkdir -p "$HOME/bin"
curl -L -o "$HOME/bin/termux-url-opener" "https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/main/termux-url-opener"
chmod +x "$HOME/bin/termux-url-opener"

# Set up yt-dlp config
echo "Setting up yt-dlp configuration..."
mkdir -p "$HOME/.config/yt-dlp"
cat > "$HOME/.config/yt-dlp/config" <<EOL
# yt-dlp configuration
-S ext:mp4:m4a,res:720 -o "$STORAGE_PATH/YouTube/%(title)s.%(ext)s" --no-mtime --quiet --progress --force-overwrites
-S ext:mp3 -o "$STORAGE_PATH/Music/%(title)s.%(ext)s" --no-mtime --quiet --progress --force-overwrites
-S ext:mp4:m4a,res:720 -o "$STORAGE_PATH/Unknown/%(title)s.%(ext)s" --no-mtime --quiet --progress --force-overwrites
EOL

# Installation complete
echo "Installation complete! Share a video or music link with Termux to start downloading."
