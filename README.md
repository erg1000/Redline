# Redline

A menu bar app that paints a red glow around your screen edges when you linger on social media during working hours.

- Watches the active tab in **Safari** and **Chrome** (via AppleScript — allow it when macOS asks).
- After **2 minutes** on a listed site the glow fades in, then grows stronger and starts pulsing until it reaches full intensity (**10 minutes** later by default).
- When you leave, built-up time drains quickly (Fast = 6× faster than it builds up), so short tab switches don't reset it, but real breaks do.
- Working hours (default Mon–Fri 9:00–18:00), timings, wind-down speed and the site list are all editable in **Settings…**.
- Pause for 15 min / 30 min / 1 h / rest of the day from the menu. **Preview Glow** shows what the alarm looks like.

## Build

```bash
./scripts/build-app.sh            # builds build/Redline.app
./scripts/build-app.sh --install  # also copies it to /Applications and launches it
swift scripts/make-icon.swift     # renders Resources/AppIcon.svg (or .png) into AppIcon.icns
```

If the menu says it can't read your browser, open System Settings → Privacy & Security → Automation and enable Safari/Chrome under Redline.
