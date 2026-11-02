#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf -- "$WORK"' EXIT
export HOME="$WORK/home" MOCK="$WORK/mock"
mkdir -p "$HOME" "$MOCK/bin" "$MOCK/notices"
export PATH="$MOCK/bin:$PATH"
cat > "$MOCK/bin/yt-dlp" <<'SH'
#!/usr/bin/env bash
printf '%q ' "$@" >> "$MOCK/calls"; echo >> "$MOCK/calls"
while [[ $1 != -o ]]; do shift; done
dir=${2%/*}
n=0; [[ ! -f $dir/count.temp ]] || read -r n < "$dir/count.temp"
n=$((n+1)); echo "$n" > "$dir/count.temp"
echo "fixture error $n" >&2
case ${MODE:-fail} in
 success) echo media > "$dir/media.mp4"; exit 0 ;;
 recover) if [[ $n == 2 ]]; then echo media > "$dir/media.mp3"; exit 0; fi ;;
esac
exit 7
SH
cat > "$MOCK/bin/termux-notification" <<'SH'
#!/usr/bin/env bash
[[ ${API_FAIL:-false} != true ]] || exit 1
id=$2
printf '%q ' "$@" > "$MOCK/notices/$id"
while [[ $# -gt 0 ]]; do
 case $1 in --button1-action) printf '%s' "$2" > "$MOCK/retry-$id";; --button2-action) printf '%s' "$2" > "$MOCK/dismiss-$id";; esac
 shift
done
SH
printf '#!/usr/bin/env bash\nexit 0\n' > "$MOCK/bin/sleep"
cp "$MOCK/bin/sleep" "$MOCK/bin/termux-notification-remove"
cp "$MOCK/bin/sleep" "$MOCK/bin/termux-media-scan"
chmod +x "$MOCK/bin/"*
logs="$HOME/storage/shared/.termux-yt-dlg/logs"
run() { bash "$ROOT/termux-url-opener" "$1" | cat; }
settle() {
 for ((i=0;i<200;i++)); do
  if [[ $(find "$HOME/.local/state/termux-yt-dlg" -maxdepth 1 -type f ! -name '*.url' ! -name '.retention.lock' | wc -l) == "$1" ]]; then return; fi
  /usr/bin/sleep .05
 done
 echo 'background work did not finish' >&2; exit 1
}
export MODE=success
run 'https://youtu.be/video'; settle 0
[[ -f "$HOME/storage/shared/Movies/New/media.mp4" ]]
grep -q 'Download\\ complete' "$MOCK/notices/"*
[[ $(wc -l < "$MOCK/calls") == 1 ]]
export MODE=recover
run 'https://music.youtube.com/watch?v=music'; settle 0
[[ -f "$HOME/storage/shared/Music/New/media.mp3" ]]
grep -q 'Attempt 2 | Exit status: 0' "$logs/failed-downloads/"*.log
grep -q 'fixture error 1' "$logs/failed-downloads/"*.log
export MODE=fail
url='https://example.test/$(touch SHOULD_NOT_EXIST)?x="; echo bad'
url+="'"
url+=$'\n'
run "$url"; settle 1
[[ $(wc -l < "$MOCK/calls") == 6 ]]
grep -q 'Attempt 3 | Exit status: 7' "$logs/failed-downloads/"*.log
action=$(cat "$MOCK"/retry-*)
# Retry state must survive deletion/retention of the corresponding error log.
rm -f -- "$logs/failed-downloads/"*.log
dash -c "$action" | cat; settle 1
[[ $(wc -l < "$MOCK/calls") == 9 ]]
dash -c "$action" | cat; settle 1
[[ $(wc -l < "$MOCK/calls") == 9 ]]
[[ ! -e SHOULD_NOT_EXIST ]]
# Simultaneous repeated clicks must consume the new token only once.
for f in "$MOCK"/retry-*; do
    next_action=$(cat "$f")
    [[ $next_action != "$action" ]] || continue
    dash -c "$next_action" | cat &
    dash -c "$next_action" | cat &
    wait
    break
done
settle 1
[[ $(wc -l < "$MOCK/calls") == 12 ]]
printf -v quoted_url '%q' "$url"
[[ $(grep -Fc -- "$quoted_url" "$MOCK/calls") == 6 ]]
for f in "$MOCK"/dismiss-*; do dash -c "$(cat "$f")"; done
settle 0
rm -f -- "$MOCK"/retry-* "$MOCK"/dismiss-*
run 'https://example.test/independent-one' &
run 'https://example.test/independent-two' &
wait
settle 2
[[ $(find "$MOCK" -name 'retry-*' | wc -l) == 2 ]]
for f in "$MOCK"/dismiss-*; do dash -c "$(cat "$f")"; done
settle 0
mkdir -p "$HOME/.config/termux-yt-dlg"
printf 'NOTIFICATIONS=false\n' > "$HOME/.config/termux-yt-dlg/config"
before=$(find "$MOCK/notices" -type f | wc -l)
run 'https://example.test/off'; settle 0
[[ $(find "$MOCK/notices" -type f | wc -l) == "$before" ]]
printf 'RETRY_PROMPTS=false\n' > "$HOME/.config/termux-yt-dlg/config"
run 'https://example.test/no-prompt'; settle 0
[[ ! -e "$HOME/.local/state/termux-yt-dlg/"*.url ]]
# Literal settings work with CRLF and a final line without a newline.
printf 'NOTIFICATIONS=false\r\nRETRY_PROMPTS=false' > "$HOME/.config/termux-yt-dlg/config"
before=$(find "$MOCK/notices" -type f | wc -l)
run 'https://example.test/config-line-endings'; settle 0
[[ $(find "$MOCK/notices" -type f | wc -l) == "$before" ]]
printf 'RETRY_PROMPTS=false\n' > "$HOME/.config/termux-yt-dlg/config"
export API_FAIL=true
run 'https://example.test/permission'; settle 0
unset API_FAIL
mv "$MOCK/bin/termux-notification" "$MOCK/notification-disabled"
run 'https://example.test/missing'; settle 0
mv "$MOCK/notification-disabled" "$MOCK/bin/termux-notification"
printf 'NOTIFICATIONS=false\n' > "$HOME/.config/termux-yt-dlg/config"
touch "$logs/failed-downloads/unmanaged.log" "$logs/failed-downloads/ytdlg-active.active"
touch -t 200001010000 "$logs/failed-downloads/ytdlg-oldest.log"
for ((i=0;i<28;i++)); do run "https://example.test/concurrent/$i" & done
wait
settle 0
[[ $(find "$logs/failed-downloads" -name 'ytdlg-*.log' | wc -l) == 25 ]]
[[ -f "$logs/failed-downloads/unmanaged.log" && -f "$logs/failed-downloads/ytdlg-active.active" ]]
[[ ! -e "$logs/failed-downloads/ytdlg-oldest.log" ]]
grep -q 'generic:https://example.test' "$MOCK/calls"
grep -q 'height\\<=1080' "$MOCK/calls"
export MODE=success
run 'https://youtube.com/playlist?list=fixture'; settle 0
grep -q -- '--yes-playlist' "$MOCK/calls"
grep -q 'tv_embedded' "$MOCK/calls"
[[ -s "$logs/success.log" && -s "$logs/error.log" && -s "$logs/command-history.log" ]]
# Notification-state failures must not prevent an otherwise successful download.
mv "$HOME/.local/state/termux-yt-dlg" "$HOME/.local/state/saved"
touch "$HOME/.local/state/termux-yt-dlg"
run 'https://example.test/state-unavailable'
grep -q 'state-unavailable' "$logs/success.log"
bash "$ROOT/tests/install.sh"
echo 'PASS: mocked notifications, actions, retries, routing, concurrency, and retention'
