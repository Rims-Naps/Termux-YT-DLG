# Repository guidance

This project is a Bash URL-share downloader for the GitHub-distributed Android Termux app.

- Read `README.md`, `termux-url-opener`, and `install.sh` before changing behavior.
- Preserve existing user changes and installed configuration.
- Keep URL classification, yt-dlp arguments, three-attempt retry strategy, configured foreground/background execution, routing, partial-file handling, and media scanning intact unless explicitly asked to change them.
- Treat URLs as data. Use quoted arguments and arrays; never evaluate URLs as shell code.
- Notification actions must work without a terminal and require an explicit user action to retry.
- Keep concurrent downloads and retry state independent. Retention must only delete completed logs owned by this feature.
- Use local mocks for tests; do not download live media during verification.
- Run `bash -n termux-url-opener install.sh` after relevant changes and exercise behavior with local mocks. The previous `tests/` directory was removed; do not assume its runner exists.
- For requested Android verification, inspect and back up the installed opener and configuration first, and wait for active downloads. Fetch the branch installer with `wget`, inspect and syntax-check it before running, and verify that it fetches the matching branch opener. Test sharing using local fixtures/mocks, never live media; validate foreground/background and notification actions on the device. If the branch is unpublished, stage the local candidate instead and repeat the published-installer check after pushing when requested.
- State which checks passed and which notification behavior still needs Android validation.
- Avoid unrelated dependency, CI, or environment changes. Do not commit or push unless asked.
