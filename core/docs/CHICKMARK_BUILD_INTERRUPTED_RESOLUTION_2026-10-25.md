# ChickMark: `BUILD INTERRUPTED` workaround (25 October 2026)

## Observed
- Repeated Release and Debug Simulator builds started through Remote Desktop Commander stopped with `** BUILD INTERRUPTED **` and no compiler diagnostics. Remote session intermittently disconnected while builds ran.
- macOS disk space was ample (~150 GiB system, ~2.9 TiB external). Multiple simulator instances were initially booted.
- `nohup` from the remote command still lost its parent process when the remote session dropped; a `launchctl submit` process was alive but stalled during Xcode IDE/plugin initialization, and was removed.

## Successful procedure
1. `xcrun simctl shutdown all` (only when simulator tests are not actively in use).
2. Start an independent `tmux` session, rather than an RDC-managed shell:

```sh
cd /Volumes/ArvectumSSD/arvectum/repos/arvectum-tools
tmux new-session -d -s chickmark_release 'xcodebuild -jobs 2 -project chickmark/ios/HabitsByArvectumIOS.xcodeproj -scheme HabitsByArvectum -configuration Release -destination "generic/platform=iOS Simulator" -derivedDataPath /tmp/arvectum-four-rc-chick CODE_SIGNING_ALLOWED=NO build > /tmp/chick-tmux-build.log 2>&1; echo $? > /tmp/chick-tmux-build.exit'
```

3. Poll independently with `cat /tmp/chick-tmux-build.exit` and `grep 'BUILD ' /tmp/chick-tmux-build.log`.

## Result
`/tmp/chick-tmux-build.exit`: `0`; `/tmp/chick-tmux-build.log`: `** BUILD SUCCEEDED **`.

This proves a successful **unsigned Release iOS Simulator build**, not a signed distribution IPA. The root cause of remote disconnects is not yet proven; evidence strongly supports remote-shell process lifetime as the cause of interrupted builds. Preserve `tmux`/independent session for future long Xcode jobs.
