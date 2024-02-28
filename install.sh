#!/data/data/com.termux/files/usr/bin/bash

# Enhanced Termux-YTD Installation Script

echo "Updating Termux packages..."
apt update && apt upgrade -y

echo "Requesting storage access..."
termux-setup-storage

echo "Installing Python and yt-dlp for media downloads..."
pkg install python -y
pip install yt-dlp

echo "Creating directories for downloads..."
mkdir -p ~/storage/shared/{Music,YouTube,Explicit}

echo "Setting up the enhanced Termux URL Opener script..."
mkdir -p ~/bin
cp termux-url-opener ~/bin/
chmod +x ~/bin/termux-url-opener

echo "Installation complete! Share a video or music link with Termux to start downloading."
