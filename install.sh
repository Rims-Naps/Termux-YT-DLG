#!/data/data/com.termux/files/usr/bin/bash

# Termux-YTD Installation Script

STORAGE_PATH="/data/data/com.termux/files/home/storage/shared"

# Update and upgrade Termux packages
echo "Updating Termux packages..."
apt update && apt upgrade -y

# Request storage permission for Termux
echo "Requesting storage access..."
termux-setup-storage
sleep 4

# Install Python and yt-dlp for downloading media
echo "Installing Python and yt-dlp for media downloads..."
pkg install python -y
pkg install ffmpeg -y
pip install yt-dlp

# Create download folders
echo "Creating directories for downloads..."
if [ ! -d "$STORAGE_PATH/Music" ]; then
    mkdir -p "$STORAGE_PATH/Music"
fi
if [ ! -d "$STORAGE_PATH/YouTube" ]; then
    mkdir -p "$STORAGE_PATH/YouTube"
fi
if [ ! -d "$STORAGE_PATH/Unknown" ]; then
    mkdir -p "$STORAGE_PATH/Unknown"
fi

# Set up enhanced URL opener script
echo "Setting up the enhanced Termux URL Opener script..."
if [ ! -d "$HOME/bin" ]; then
    mkdir -p "$HOME/bin"
fi
cp termux-url-opener "$HOME/bin/"
chmod +x "$HOME/bin/termux-url-opener"

# Set up yt-dlp config
echo "Setting up yt-dlp configuration..."
if [ ! -d "$HOME/.config/yt-dlp" ]; then
    mkdir -p "$HOME/.config/yt-dlp"
fi
echo "-S ext:mp4:m4a,res:720 -o $STORAGE_PATH/YouTube/%(title)s.%(ext)s --no-mtime" > "$HOME/.config/yt-dlp/config"
echo "-S ext:mp3 -o '$STORAGE_PATH/Music/%(title)s.%(ext)s' --no-mtime" >> "$HOME/.config/yt-dlp/config"
echo "-S ext:mp4:m4a,res:720 -o $STORAGE_PATH/Unknown/%(title)s.%(ext)s --no-mtime" >> "$HOME/.config/yt-dlp/config"

# Installation complete
echo "Installation complete! Share a video or music link with Termux to start downloading."
