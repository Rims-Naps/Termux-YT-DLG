#!/data/data/com.termux/files/usr/bin/bash

STORAGE_PATH="$HOME/storage/shared"
AUDIO_DIR="$STORAGE_PATH/Music/New"
VIDEO_DIR="$STORAGE_PATH/Movies/New"
TMP_DIR="$STORAGE_PATH/.termux-yt-dlg/tmp"
STATE_DIR="$STORAGE_PATH/.termux-yt-dlg/state"
LOG_DIR="$STORAGE_PATH/.termux-yt-dlg/logs"
SCRIPT_URL="https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/feature/auto-return-to-previous-app/termux-url-opener"

# Fails loudly with a clear message instead of silently continuing into a
# half-installed state. Used only for steps that later steps truly depend on.
require() {
    local desc="$1"
    shift
    if ! "$@"; then
        echo ""
        echo "================================================================"
        echo "ERROR: $desc failed. Fix the error above and re-run this script."
        echo "================================================================"
        exit 1
    fi
}

echo "Cleaning up previous installation..."
rm -f "$HOME/bin/termux-url-opener" 2>/dev/null

# Back up the existing yt-dlp config for reference, but never delete the
# ~/.config/yt-dlp directory itself: it's also where cookies.txt lives (see
# README's cookie-support section), and a blanket `rm -rf` would silently
# destroy a user's cookies on every re-install/update. Only the config file
# is touched — and it gets fully overwritten later in this script anyway,
# so there is nothing to delete here in the first place.
if [[ -f "$HOME/.config/yt-dlp/config" ]]; then
    cp "$HOME/.config/yt-dlp/config" "$HOME/.config/yt-dlp/config.bak"
    echo "Existing yt-dlp config backed up to: $HOME/.config/yt-dlp/config.bak"
fi

echo "Updating Termux packages..."
apt-get update && apt-get upgrade -y
# Deliberately not fatal: upgrade failures/prompts are common and don't
# block the installs below, which check for themselves.

echo "Requesting storage access..."
echo "NOTE: A permission dialog will appear — tap 'Allow'. The script will continue automatically."
termux-setup-storage
sleep 5

echo "Installing Python, ffmpeg, aria2, and Termux:API..."
# python + ffmpeg: required by yt-dlp itself (ffmpeg for merging/embedding).
# aria2: powers the multi-connection downloads in termux-url-opener.
# termux-api: provides the termux-notification / termux-toast /
#   termux-media-scan command-line tools used for the download progress
#   notifications. NOTE: this package alone is not enough — you also need
#   the separate "Termux:API" companion app installed from F-Droid (the
#   same store you installed Termux from) for these commands to actually
#   work. The package just provides the command-line side of the bridge.
require "Installing python/ffmpeg/aria2/termux-api" pkg install -y python ffmpeg aria2 termux-api

echo "Installing yt-dlp nightly build..."
require "Upgrading pip" pip install --upgrade pip
require "Installing yt-dlp" pip install -U --pre "yt-dlp[default]"

echo "Creating download directories..."
mkdir -p -- "$AUDIO_DIR" "$VIDEO_DIR" "$TMP_DIR" "$STATE_DIR" "$LOG_DIR"

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

echo "Verifying installation..."
missing=()

if yt-dlp --version >/dev/null 2>&1; then
    echo "  yt-dlp            : OK ($(yt-dlp --version))"
else
    echo "  yt-dlp            : MISSING"
    missing+=("yt-dlp")
fi

if command -v aria2c >/dev/null 2>&1; then
    echo "  aria2c            : OK ($(aria2c --version | head -n1))"
else
    echo "  aria2c            : MISSING (multi-connection downloads will silently fall back to yt-dlp's built-in downloader)"
    missing+=("aria2c")
fi

if command -v ffmpeg >/dev/null 2>&1; then
    echo "  ffmpeg            : OK"
else
    echo "  ffmpeg            : MISSING (metadata/thumbnail/chapter embedding will fail)"
    missing+=("ffmpeg")
fi

for cmd in termux-notification termux-toast termux-media-scan; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  $cmd : OK (command found)"
    else
        echo "  $cmd : MISSING"
        missing+=("$cmd")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "WARNING: the following were not found and may need attention: ${missing[*]}"
    echo "  - For yt-dlp: try running 'pip install -U --pre \"yt-dlp[default]\"' manually."
    echo "  - For aria2c/ffmpeg: try running 'pkg install -y aria2 ffmpeg' manually."
    echo "  - For termux-notification/termux-toast/termux-media-scan: these commands"
    echo "    are provided by the 'termux-api' package, but ALSO require the separate"
    echo "    'Termux:API' companion app to be installed (same app store as Termux"
    echo "    itself). Installing the package without the app will leave these"
    echo "    commands present but non-functional."
fi

echo "Writing yt-dlp configuration..."
mkdir -p "$HOME/.config/yt-dlp"
# Note: this default -o only applies when yt-dlp is run manually from the
# command line. Downloads triggered via the share-sheet go through
# termux-url-opener, which routes audio/video into separate directories and
# is unaffected by this default.
cat > "$HOME/.config/yt-dlp/config" << EOL
--no-mtime
--embed-thumbnail
--embed-metadata
--add-metadata
--ffmpeg-location /data/data/com.termux/files/usr/bin
-o $VIDEO_DIR/%(title)s.%(ext)s
EOL

echo ""
echo "================================================================"
echo "Installation / update complete!"
echo "================================================================"
echo "  yt-dlp version   : $(yt-dlp --version 2>/dev/null || echo 'unknown')"
echo "  Audio downloads  : $AUDIO_DIR"
echo "  Video downloads  : $VIDEO_DIR"
echo "  Temp/incomplete  : $TMP_DIR"
echo "  Download archive : $STATE_DIR/download-archive.txt"
echo "  Success log      : $LOG_DIR/success.log"
echo "  Error log        : $LOG_DIR/error.log"
echo "  Command history  : $LOG_DIR/command-history.log"
echo "  Config file      : $HOME/.config/yt-dlp/config"
echo ""
echo "For age-restricted content, drop a cookies.txt (Netscape format) into"
echo "either ~/.config/yt-dlp/cookies.txt or $STORAGE_PATH/cookies.txt."
echo ""
echo "Share any video or music URL with Termux to start downloading."
echo "================================================================"
