#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf -- "$WORK"' EXIT
export HOME="$WORK/home" INSTALL_SOURCE="$ROOT/termux-url-opener"
mkdir -p "$HOME" "$WORK/bin"
export PATH="$WORK/bin:$PATH"
for cmd in apt-get pkg pip termux-setup-storage sleep; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$WORK/bin/$cmd"
done
cat > "$WORK/bin/yt-dlp" <<'SH'
#!/usr/bin/env bash
[[ ${1:-} == --version ]] || exit 1
echo fixture-version
SH
cat > "$WORK/bin/curl" <<'SH'
#!/usr/bin/env bash
[[ ${INSTALL_FAIL:-false} != true ]] || exit 22
while [[ $# -gt 0 && $1 != -o ]]; do shift; done
[[ $# -ge 2 ]] || exit 1
cp -- "$INSTALL_SOURCE" "$2"
SH
chmod +x "$WORK/bin/"*
bash "$ROOT/install.sh" > "$WORK/output"
config="$HOME/.config/yt-dlp/config"
grep -qx -- '--no-mtime' "$config"
if grep -qx 'fi' "$config"; then echo 'unexpected shell code in yt-dlp config' >&2; exit 1; fi
cmp -- "$INSTALL_SOURCE" "$HOME/bin/termux-url-opener"
printf 'custom yt-dlp config\n' > "$config"
mkdir -p "$HOME/.config/termux-yt-dlg"
printf 'NOTIFICATIONS=false\n' > "$HOME/.config/termux-yt-dlg/config"
printf 'preserve backup\n' > "$HOME/.config/yt-dlp/config.bak"
bash "$ROOT/install.sh" > "$WORK/output"
grep -qx 'custom yt-dlp config' "$config"
grep -qx 'preserve backup' "$HOME/.config/yt-dlp/config.bak"
grep -qx 'NOTIFICATIONS=false' "$HOME/.config/termux-yt-dlg/config"
cp -- "$HOME/bin/termux-url-opener" "$WORK/previous"
if INSTALL_FAIL=true bash "$ROOT/install.sh" > "$WORK/output" 2>&1; then
    echo 'failed download reported success' >&2; exit 1
fi
cmp -- "$WORK/previous" "$HOME/bin/termux-url-opener"
printf 'if invalid bash\n' > "$WORK/invalid"
if INSTALL_SOURCE="$WORK/invalid" bash "$ROOT/install.sh" > "$WORK/output" 2>&1; then
    echo 'invalid script installed' >&2; exit 1
fi
cmp -- "$WORK/previous" "$HOME/bin/termux-url-opener"
echo 'PASS: fresh installation, preserved configuration, and failed/invalid updates'
