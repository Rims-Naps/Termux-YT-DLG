#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

STORAGE_PATH="$HOME/storage/shared"
AUDIO_DIR="$STORAGE_PATH/Music/New"
VIDEO_DIR="$STORAGE_PATH/Movies/New"
TMP_DIR="$STORAGE_PATH/.termux-yt-dlg/tmp"
STATE_DIR="$STORAGE_PATH/.termux-yt-dlg/state"
LOG_DIR="$STORAGE_PATH/.termux-yt-dlg/logs"
INSTALL_LOG="$LOG_DIR/install-log-errors.txt"
INSTALL_LOG_MAX_BYTES=$((512 * 1024))   # cap at ~512KB, same approach as termux-url-opener's logs
SCRIPT_URL="https://raw.githubusercontent.com/Rims-Naps/Termux-YT-DLG/additional-functionality-WIP/termux-url-opener"

mkdir -p -- "$LOG_DIR" 2>/dev/null

# Auto-cap the install log before this run appends more to it, so it never
# grows unbounded across many installs/updates.
if [[ -f "$INSTALL_LOG" ]]; then
    _size=$(wc -c < "$INSTALL_LOG" 2>/dev/null || echo 0)
    if (( _size > INSTALL_LOG_MAX_BYTES )); then
        _tmp="${INSTALL_LOG}.tmp.$$"
        tail -c "$INSTALL_LOG_MAX_BYTES" -- "$INSTALL_LOG" > "$_tmp" 2>/dev/null && mv -f -- "$_tmp" "$INSTALL_LOG" 2>/dev/null
        rm -f -- "$_tmp" 2>/dev/null
    fi
fi

{
    echo ""
    echo "================================================================"
    echo "Install run: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "================================================================"
} >> "$INSTALL_LOG"

# Mirror everything this script prints — both stdout and stderr — into the
# log file below, while still showing it live in the terminal. This means a
# failed run always leaves a record on disk, instead of needing to manually
# copy/paste the terminal output to figure out what went wrong.
exec > >(tee -a "$INSTALL_LOG") 2>&1

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
export DEBIAN_FRONTEND=noninteractive
apt-get update
dpkg --configure -a
apt-get -o Dpkg::Options::=--force-confold upgrade -y

echo "Requesting storage access..."
echo "NOTE: A permission dialog will appear — tap 'Allow'. The script will continue automatically."
sleep 2
termux-setup-storage 
sleep 2

pkg install -y python

python -m pip install -U "yt-dlp[default]"

pkg install -y ffmpeg aria2 termux-api


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
    echo "  - For yt-dlp: try running 'python -m pip install -U --pre \"yt-dlp[default]\"' manually."
    echo "  - For aria2c/ffmpeg: try running 'pkg install -y aria2 ffmpeg' manually."
    echo "  - For termux-notification/termux-toast/termux-media-scan: these commands"
    echo "    are provided by the 'termux-api' package, but ALSO require the separate"
    echo "    'Termux:API' companion app to be installed (same app store as Termux"
    echo "    itself). Installing the package without the app will leave these"
    echo "    commands present but non-functional."
    echo ""
    echo "ERROR: installation did not complete. Fix the missing dependencies and re-run."
    exit 1
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
echo "  Install log      : $INSTALL_LOG"
echo "  Config file      : $HOME/.config/yt-dlp/config"
echo ""
echo "For age-restricted content, drop a cookies.txt (Netscape format) into"
echo "either ~/.config/yt-dlp/cookies.txt or $STORAGE_PATH/cookies.txt."
echo ""
echo "Share any video or music URL with Termux to start downloading."
echo "================================================================"
