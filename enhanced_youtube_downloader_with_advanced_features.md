---
title: "Enhanced YouTube downloader with advanced features"
source: "https://claude.ai/chat/6ce2136a-6ae8-4a32-9e1f-7c334cd5512f"
model: "claude-sonnet-5"
exported: 2026-09-18
---

# Human — Sep 18, 2026, 1:35 PM

**Attachment: combined-termux-url-opener.txt · blob · 60.9 KB**

additional-functionality-WIP
working on my repository code adding new features in the repo branch  additional-functionality-WIP is my repo at this URL https://github.com/Rims-Naps/Termux-YT-DLG/tree/additional-functionality-WIP 




Please incorporate the following new features into the script provided in the attached file, combined-termux-url-opener.txt:

* Google link unwrapping
* Auto-embedding metadata, thumbnails, and chapters
* Aria2c multi-connection downloading
* Download archive for skipping duplicates
* Auto log file size capping
* Cookie file support for age-restricted videos



additional features to implement

Because this script performs background downloads rather than standard browser downloads, it is critical to provide the user with real-time transparency. Please implement a tooltip system that displays detailed progress updates for each stage of the download process, followed by a final notification tooltip to confirm either a successful completion or an error message if the download fails.

# Claude — Sep 18, 2026, 1:39 PM

**File: termux-url-opener**

```
#!/data/data/com.termux/files/usr/bin/bash

# --- Directories -----------------------------------------------------------
# Type-aware download routing. Files land directly in Music/Movies once
# finished, and interrupted/partial downloads never leave the tmp dir, so
# Android's media scanner only ever sees completed files.
BASE_DIR="$HOME/storage/shared"
AUDIO_DIR="$BASE_DIR/Music/New"
VIDEO_DIR="$BASE_DIR/Movies/New"
TMP_DIR="$BASE_DIR/.termux-yt-dlg/tmp"
STATE_DIR="$BASE_DIR/.termux-yt-dlg/state"
ARCHIVE_FILE="$STATE_DIR/download-archive.txt"

# --- Logs --------------------------------------------------------------
LOG_DIR="$BASE_DIR/.termux-yt-dlg/logs"
SUCCESS_LOG="$LOG_DIR/success.log"
ERROR_LOG="$LOG_DIR/error.log"
COMMAND_LOG="$LOG_DIR/command-history.log"
LOG_MAX_BYTES=$((512 * 1024))   # cap each log at ~512KB, keeping the newest data

# --- Cookies (for age-restricted / login-gated videos) ----------------------
# Drop a Netscape-format cookies.txt in either of these locations (the yt-dlp
# config dir, or the root of shared storage for easy drag-and-drop from a
# file manager) and it will be picked up automatically. Never overwritten or
# created by this script.
COOKIE_CANDIDATES=(
    "$HOME/.config/yt-dlp/cookies.txt"
    "$BASE_DIR/cookies.txt"
)

# Ensure required directories exist. Never touches/truncates anything that
# already exists.
for _d in "$AUDIO_DIR" "$VIDEO_DIR" "$TMP_DIR" "$STATE_DIR" "$LOG_DIR"; do
    [[ -d "$_d" ]] || mkdir -p -- "$_d" 2>/dev/null
done

# Ensure log files exist (append-only; rotated by size, never wiped outright).
for _f in "$SUCCESS_LOG" "$ERROR_LOG" "$COMMAND_LOG"; do
    [[ -f "$_f" ]] || : >> "$_f" 2>/dev/null
done

# Auto log-size capping. Keeps the tail (most recent) bytes of each log file
# whenever it grows past LOG_MAX_BYTES, so logs never grow unbounded on a
# device with limited storage. Runs once per invocation, before anything is
# appended, so a single burst of logging can't blow past the cap unnoticed.
cap_log() {
    local f="$1" max="$2" size
    [[ -f "$f" ]] || return 0
    size=$(wc -c < "$f" 2>/dev/null || echo 0)
    if (( size > max )); then
        tail -c "$max" -- "$f" > "${f}.tmp" 2>/dev/null && mv -f -- "${f}.tmp" "$f"
    fi
}
for _f in "$SUCCESS_LOG" "$ERROR_LOG" "$COMMAND_LOG"; do
    cap_log "$_f" "$LOG_MAX_BYTES"
done

log_success() { printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >> "$SUCCESS_LOG"; }
log_error()   { printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >> "$ERROR_LOG"; }
log_info()    { printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >> "$COMMAND_LOG"; }

# --- Notification "tooltip" system ------------------------------------------
# Because downloads happen in the background after control returns to the
# previous app, Termux:API notifications are the only reliable way to keep
# the user informed. We use a single notification id per invocation so each
# stage update replaces the last (a live progress "tooltip"), then post one
# final notification (and a toast) confirming success or failure. All of
# this is a no-op if Termux:API isn't installed.
NOTIFY_ID="ytdlg_$$"
HAVE_NOTIFY=false
HAVE_TOAST=false
command -v termux-notification >/dev/null 2>&1 && HAVE_NOTIFY=true
command -v termux-toast >/dev/null 2>&1 && HAVE_TOAST=true

# Updates the ongoing progress notification with the current stage.
notify_stage() {
    local content="$1"
    $HAVE_NOTIFY && termux-notification \
        --id "$NOTIFY_ID" \
        --title "Termux-YT-DLG — downloading" \
        --content "$content" \
        --priority low \
        --ongoing \
        2>/dev/null
}

# Posts the terminal notification (dismissible) and a matching toast.
notify_final() {
    local title="$1" content="$2" ok="$3"
    if $HAVE_NOTIFY; then
        if [[ "$ok" == true ]]; then
            termux-notification --id "$NOTIFY_ID" --title "$title" --content "$content" --priority default 2>/dev/null
        else
            termux-notification --id "$NOTIFY_ID" --title "$title" --content "$content" --priority high --led-color FF0000 2>/dev/null
        fi
    fi
    $HAVE_TOAST && termux-toast -g middle -s "$content" 2>/dev/null
}

url="$1"
if [[ -z "$url" ]]; then
    log_error "No URL provided. Exiting."
    exit 1
fi

# --- Google link unwrapping --------------------------------------------------
# Links shared out of Gmail, Google Search, Google Docs, etc. often arrive
# wrapped as https://www.google.com/url?q=<real-url>&... . Unwrap them so
# content-type detection and yt-dlp both see the real destination.
urldecode() {
    local data="${1//+/ }"
    printf '%b' "${data//%/\\x}"
}

unwrap_google_redirect() {
    local in="$1" raw
    if [[ "$in" == *"google."*"/url?"* ]]; then
        raw=$(printf '%s' "$in" | sed -n 's/.*[?&]\(url\|q\)=\([^&]*\).*/\2/p')
        if [[ -n "$raw" ]]; then
            urldecode "$raw"
            return 0
        fi
    fi
    printf '%s' "$in"
}

unwrapped_url=$(unwrap_google_redirect "$url")
if [[ "$unwrapped_url" != "$url" && -n "$unwrapped_url" ]]; then
    log_info "Unwrapped Google redirect: $url -> $unwrapped_url"
    url="$unwrapped_url"
fi

# Record the exact invocation (script + all args, quoted) before doing
# anything else, so every call to this tool is logged regardless of what
# happens afterward.
{
    printf -- '----------------------------------------\n'
    printf '[%s] PID:%s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$$"
    printf '%s' "$0"
    for _arg in "$@"; do
        printf ' %q' "$_arg"
    done
    printf '\n'
    printf -- '----------------------------------------\n'
} >> "$COMMAND_LOG" 2>/dev/null

# Immediate feedback. The script backgrounds the real work and returns
# control to the previous app right away, so a quick toast here reassures
# the user the share actually registered before any notification exists.
$HAVE_TOAST && termux-toast -g top -s "Download queued…" 2>/dev/null
notify_stage "Queued — detecting content type…"

# Resolve an optional cookies file for age-restricted / login-gated content.
COOKIE_ARGS=()
for _c in "${COOKIE_CANDIDATES[@]}"; do
    if [[ -s "$_c" ]]; then
        COOKIE_ARGS=( --cookies "$_c" )
        log_info "Using cookie file: $_c"
        break
    fi
done

# Prefer aria2c for multi-connection downloading when it's installed;
# otherwise fall back to yt-dlp's built-in downloader silently.
DOWNLOADER_ARGS=()
if command -v aria2c >/dev/null 2>&1; then
    DOWNLOADER_ARGS=( --downloader aria2c --downloader-args "aria2c:-x 16 -s 16 -j 16 -k 1M" )
else
    log_info "aria2c not found — using yt-dlp's native downloader."
fi

# Always embed whatever metadata/thumbnail/chapters are available. Harmless
# no-ops when a given site/format doesn't provide one of these.
EMBED_ARGS=( --embed-metadata --embed-chapters --embed-thumbnail --add-metadata )

# Moves finished files out of a per-download temp dir into the correct
# type-based directory, based on file extension. Skips yt-dlp's own
# in-progress artifacts so partial files are never picked up. Prints the
# number of files moved.
move_completed_files() {
    local src="$1" moved=0 f
    for f in "$src"/*; do
        [[ -e "$f" ]] || continue
        case "$f" in
            *.part|*.ytdl|*.part-Frag*|*.temp) continue ;;
        esac
        case "$f" in
            *.mp3|*.m4a|*.opus|*.aac|*.flac|*.wav|*.ogg)
                mv -f -- "$f" "$AUDIO_DIR/" && moved=$((moved + 1)) ;;
            *)
                mv -f -- "$f" "$VIDEO_DIR/" && moved=$((moved + 1)) ;;
        esac
    done
    echo "$moved"
}

{
    content_type="unknown"
    playlist_info=""
    download_success=false
    exit_status=""
    BYPASS_ARGS=( --geo-bypass --age-limit 99 )
    HEADER_ARGS=( --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36" )
    FORMAT=""
    POST_ARGS=()
    EXTRACTOR_ARGS=()
    PLAYLIST_ARGS=()
    is_playlist=false
    if [[ "$url" == *"playlist"* || "$url" == *"list="* ]]; then
        is_playlist=true
    fi

    # Classify URL and set yt-dlp args (unchanged from previous behavior).
    if [[ "$url" == *"music.youtube.com"* ]] || [[ "$is_playlist" == true ]]; then
        content_type="music"
        FORMAT="bestaudio[ext=m4a]/bestaudio/best"
        POST_ARGS=( -x --audio-format mp3 --audio-quality 0 )
        EXTRACTOR_ARGS=( --extractor-args "youtube:player_client=android,web" )
        if [[ "$is_playlist" == true ]]; then
            playlist_info=" (Playlist)"
            PLAYLIST_ARGS=( --yes-playlist )
        fi
    elif [[ "$url" == *"youtube.com/watch"* || "$url" == *"youtu.be"* ]]; then
        content_type="video"
        FORMAT="bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]/best"
        EXTRACTOR_ARGS=( --extractor-args "youtube:player_client=android,web" )
    else
        content_type="generic"
        FORMAT="best"
        if [[ "$url" == *"pornhub"* || "$url" == *"xvideos"* || "$url" == *"xnxx"* ]]; then
            HEADER_ARGS+=( --add-header "Referer:https://www.google.com/" )
        fi
    fi

    notify_stage "Detected: ${content_type}${playlist_info} — starting download"

    # Each invocation gets its own temp subdirectory so partial/interrupted
    # files from concurrent or retried downloads never mix, and are never
    # mistaken for completed downloads (they only leave this dir on success).
    dl_tmp="$TMP_DIR/$$_$(date +%s)"
    mkdir -p -- "$dl_tmp" 2>/dev/null
    if [[ ! -d "$dl_tmp" ]]; then
        log_error "$url | Could not create temp directory: $dl_tmp"
        notify_final "Download failed" "Could not create a temp directory on device storage." false
        exit 1
    fi

    # Retry loop (3 attempts) — unchanged strategy from previous behavior.
    for attempt in 1 2 3; do
        if [[ $attempt -eq 2 && ${#EXTRACTOR_ARGS[@]} -gt 0 ]]; then
            EXTRACTOR_ARGS=( --extractor-args "youtube:player_client=tv_embedded,web" )
        fi
        if [[ $attempt -eq 3 ]]; then
            EXTRACTOR_ARGS=()
            fallback_url="generic:$url"
        else
            fallback_url="$url"
        fi

        notify_stage "Downloading (attempt ${attempt}/3)…"

        yt_stderr="$dl_tmp/.yt-dlp-attempt-${attempt}.stderr"
        yt-dlp \
            "${BYPASS_ARGS[@]}" \
            "${HEADER_ARGS[@]}" \
            "${COOKIE_ARGS[@]}" \
            "${EXTRACTOR_ARGS[@]}" \
            "${PLAYLIST_ARGS[@]}" \
            "${DOWNLOADER_ARGS[@]}" \
            -f "$FORMAT" \
            "${POST_ARGS[@]}" \
            "${EMBED_ARGS[@]}" \
            --download-archive "$ARCHIVE_FILE" \
            --no-warnings \
            --ignore-errors \
            -o "$dl_tmp/%(title)s.%(ext)s" \
            "$fallback_url" \
            > /dev/null 2> "$yt_stderr"
        exit_status=$?

        if [[ $exit_status -eq 0 ]]; then
            download_success=true
            rm -f -- "$yt_stderr"
            break
        else
            log_error "$url | Type: $content_type$playlist_info | Attempt $attempt failed | Exit status: $exit_status"
            if [[ -s "$yt_stderr" ]]; then
                {
                    echo "  ---- yt-dlp stderr (attempt $attempt) ----"
                    cat -- "$yt_stderr"
                    echo "  -------------------------------------------"
                } >> "$ERROR_LOG"
            fi
            rm -f -- "$yt_stderr"
            if [[ $attempt -lt 3 ]]; then
                notify_stage "Attempt ${attempt}/3 failed — retrying…"
                sleep 5
            fi
        fi
    done

    if [[ "$download_success" == true ]]; then
        notify_stage "Finalizing — moving files & scanning media…"
        moved=$(move_completed_files "$dl_tmp")
        log_success "$url | Type: $content_type$playlist_info | Attempt: $attempt | Files: $moved"
        # Clean up the temp subdir now that its contents have been moved out.
        rmdir -- "$dl_tmp" 2>/dev/null
        if command -v termux-media-scan >/dev/null 2>&1; then
            termux-media-scan "$AUDIO_DIR" "$VIDEO_DIR" 2>/dev/null
        fi
        if [[ "$moved" -gt 0 ]]; then
            notify_final "Download complete" "${moved} file(s) saved (${content_type}${playlist_info})." true
        else
            notify_final "Download finished (already had it)" "yt-dlp reported success but no new files were moved — likely already in the download archive." true
        fi
    else
        log_error "$url | Type: $content_type$playlist_info | Download failed after 3 attempts | Last exit status: $exit_status | Partial files retained in: $dl_tmp"
        log_error "$url | Suggestion: try a VPN, add a cookies.txt file for age-restricted content, or check $ERROR_LOG for details."
        notify_final "Download failed" "${content_type}${playlist_info} failed after 3 attempts (exit ${exit_status}). See error log." false
    fi
} &
# Android returns to the previous app automatically
exit 0

```

Works as expected. Now let me diff against the baseline branch script to confirm nothing was lost, then check it into the repo working tree and export it.

Good — the diff is clean and additive. Now let's also update the README with a short note on the new features, then package everything for delivery.

I cloned `additional-functionality-WIP` and built on top of the existing script (kept its temp-dir routing, retry loop, and append-only logs) rather than starting over. Both files are attached above — drop `termux-url-opener` in place of the one in the repo.

What's new:

- **Google link unwrapping** — detects `google.*/url?q=`/`url=` redirects and extracts the real URL (tested against both `q=` and `url=` param styles) before classification runs.
- **Metadata/thumbnail/chapter embedding** — `--embed-metadata --embed-chapters --embed-thumbnail --add-metadata` added to every yt-dlp call.
- **aria2c** — used automatically as the downloader (`-x16 -s16 -j16`) when `aria2c` is installed; silently falls back to yt-dlp's native downloader otherwise, so it won't break on devices without it.
- **Download archive** — `--download-archive` pointed at a persistent file under `.termux-yt-dlg/state/`, so re-sharing a link you already grabbed is a no-op.
- **Log size capping** — each of the three logs is trimmed to its newest ~512KB at the start of every run (tested the trim logic in isolation).
- **Cookie support** — checks `~/.config/yt-dlp/cookies.txt` then `~/storage/shared/cookies.txt` and uses whichever exists; never creates or overwrites one.
- **Notification tooltip system** — since the script returns control to the previous app immediately, real-time feedback has to happen through Termux:API rather than stdout. It posts one *updating* ongoing notification (same `--id`) through each stage — queued → detecting → downloading (attempt N/3) → retrying → finalizing — then a final dismissible notification plus a `termux-toast`, either "Download complete (N files)" or "Download failed" with the reason. All of this is wrapped in `command -v` checks, so it's a harmless no-op if Termux:API isn't installed.

Everything else (retry strategy, temp-dir isolation, media-type routing into Music/Movies) is untouched. I verified the script with `bash -n` and unit-tested the URL-unwrap and log-cap functions in isolation; I couldn't run it against real Termux/yt-dlp/aria2c since that requires the Android runtime. I don't have push access to your GitHub repo, so you'll need to copy this file over `additional-functionality-WIP` and commit it yourself.

# Human — Sep 18, 2026, 1:52 PM

Prove too me that it is fully functional and will not have any bugs or issues I want to ensure everything is absolutely undoubtedly flawless in every way before I actually commit it too my GitHub

# Claude — Sep 18, 2026, 1:57 PM

You're right to want more than my word for it — let me actually prove it rather than just assert it. I'll build a mock Termux/yt-dlp environment and run the real script through it, plus run static analysis. I'll be upfront afterward about what this can and can't prove.

Clean shellcheck pass — zero warnings. Now let's build a mock Termux environment and actually execute the script end-to-end.

Good catch on my end — that was a bug in my **mock** yt-dlp (a naive substring match `-x` was accidentally matching inside the aria2c downloader-args string), not in your script. Let me fix the mock properly and redo this rigorously.

All 4 content-type paths route correctly. Now the harder cases: failure/retry path, Google-unwrap, cookies, log capping, and no-Termux-API fallback.

Interesting finding — let me isolate it further before reporting.

Good — this test surfaced a real, legitimate bug (present in the baseline script too, not something I introduced, but worth fixing now that I've found it): `move_completed_files` intentionally skips `.part`/`.ytdl`/temp fragment files, but then `rmdir` silently fails if any are left behind — so the per-download temp directory and its stray file are **never cleaned up**. With `--ignore-errors` on playlists, this can realistically trigger whenever one entry fails but others succeed. Let me fix it.

Now let's verify the fix, re-run shellcheck, and re-run the full test suite from a clean state.

Clean. Now let's re-run the full battery of tests from scratch against the fixed script, plus the remaining untested features (Google unwrap, cookies, log capping, no-Termux-API fallback, concurrency, special characters).

Fixed — zero orphaned temp directories now. Next: Google unwrap, cookies, log capping, missing-Termux-API fallback, concurrency, and special characters.

Confirmed — yt-dlp was invoked with `https://www.youtube.com/watch?v=dQw4w9WgXcQ` (my earlier grep pattern was just faulty, not the script). Google unwrap works correctly. Now: log capping, missing-Termux-API fallback, concurrency, and shell-injection safety.

Both pass: log capped to just above the 512KB threshold (the extra bytes are the new entry appended after capping, which is correct), and the script completes cleanly with exit 0 when Termux:API isn't installed at all.

Found a genuine concurrency bug — nice catch from that test. `cap_log()` used a fixed temp filename (`file.tmp`), so two downloads shared/triggered close together race on that file and one's `mv` fails (visible as an uncaught stderr error). Let's fix it properly.

All 8 concurrent runs completed cleanly with no stderr leakage, no lost successes, no leftover temp files, and no orphaned directories. Now let's re-confirm the injection test (which earlier had a harness bug, not a script bug) properly via a script file.

Correct exit-1 behavior in both cases. Let's do one final full clean-slate regression pass and finalize the files.

I want to be straight with you: I can't honestly tell you it's "undoubtedly flawless" — no one can prove the absence of bugs, especially in something this environment-dependent (real Termux, real Android notification permissions, real yt-dlp/aria2c network behavior). What I *can* do is show you exactly what I tested and what I found. Here's what actually happened:

**Static analysis:** `shellcheck` — 0 warnings, clean.

**Live testing** — I built a mock Termux (fake `yt-dlp`, `aria2c`, `termux-notification`, `termux-toast`, `termux-media-scan` that log every call) and ran the real script against it:

| Test | Result |
|---|---|
| YouTube video → routes to Movies/New | ✅ |
| YouTube Music → routes to Music/New | ✅ |
| Playlist detection (`--yes-playlist`, audio format) | ✅ |
| Generic/unknown URL | ✅ |
| Google-redirect unwrap (`q=` and `url=` forms) — verified yt-dlp received the real URL | ✅ |
| Cookie file present → `--cookies` passed; absent → silently omitted | ✅ |
| aria2c present → `--downloader aria2c` added | ✅ |
| 3-attempt retry/failure path, timing, error log, failure notification | ✅ |
| Log auto-capping under a 700KB file | ✅ |
| No Termux:API installed → completes with exit 0, no crash | ✅ |
| Empty/missing URL → exits 1, logs cleanly | ✅ |
| Shell-injection URL (`` `cmd` ``, `$(cmd)`, `;rm -rf`) → inert, not executed | ✅ |
| URL with spaces/quotes → handled correctly | ✅ |
| 8 concurrent shares fired at once | Found 2 real bugs (below), now fixed and re-verified clean |

**Two real bugs this process caught, and fixed:**
1. **Orphaned temp directories** — `move_completed_files` skips `.part`/`.ytdl` files by design, but the `rmdir` after it silently fails if any are left (realistic with `--ignore-errors` on a partially-failed playlist), permanently leaking a directory per occurrence. Fixed: now cleans up known yt-dlp temp artifacts before the `rmdir`, and logs a warning if something unexpected is still there instead of failing silently.
2. **Log-capping race condition** — two downloads capping the same log file at the same moment used the same fixed temp filename and could stomp each other, leaking an uncaught `mv` error to stderr. Fixed with a per-PID temp filename; re-ran 8 concurrent downloads against an oversized log and got zero stderr leakage.

**What this can't prove**, honestly:
- Real yt-dlp/aria2c behavior against actual network traffic and real video sites.
- Real Android notification permissions/behavior, scoped storage quirks, or battery-optimization killing the background job.
- Whether `-x` from aria2c args vs yt-dlp's own audio-extract flag could ever collide in a way that matters (it can't — those are separate argv entries to the real yt-dlp binary; that ambiguity only existed in my *mock's* naive string matching, not in the real script's args array).

The updated, fixed file is attached above — this is the one to commit.

