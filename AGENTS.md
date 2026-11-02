# Repository guidance

This project is a Bash URL-share downloader for the GitHub-distributed Android Termux app.

- Read `README.md`, `termux-url-opener`, and `install.sh` before changing behavior.
- Preserve existing user changes and installed configuration.
- Keep URL classification, yt-dlp arguments, three-attempt retry strategy, background execution, routing, partial-file handling, and media scanning intact unless explicitly asked to change them.
- Treat URLs as data. Use quoted arguments and arrays; never evaluate URLs as shell code.
- Notification actions must work without a terminal and require an explicit user action to retry.
- Keep concurrent downloads and retry state independent. Retention must only delete completed logs owned by this feature.
- Use local mocks for tests; do not download live media during verification.
- Run `bash -n termux-url-opener install.sh` and `bash tests/run.sh` after relevant changes.
- State which checks passed and which notification behavior still needs Android validation.
- Avoid unrelated dependency, CI, or environment changes. Do not commit or push unless asked.
