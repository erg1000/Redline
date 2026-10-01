# Redline

A menu bar app that paints a red glow around your screen edges when you linger on social media during working hours.

- Watches the active tab in **Safari** and **Chrome** (via AppleScript — allow it when macOS asks).
- After **1 minute** on a listed site (adjustable from the menu: 30 seconds to 15 minutes) the glow fades in, then grows stronger and starts pulsing until it reaches full intensity (**10 minutes** later by default).
- When you leave, built-up time drains quickly (Fast = 20× faster than it builds up, so a full glow is gone in about 30 seconds). Short tab switches barely dent it; real breaks clear it.
- Working hours (default Mon–Fri 9:00–18:00), timings, wind-down speed and the site list are all editable in **Settings…**.
- Pause for 15 min / 30 min / 1 h / rest of the day from the menu. **Preview Glow** shows what the alarm looks like.
- The menu bar icon turns red while you're on a social site.

## Installation

1. **Download** `Redline-1.0.dmg` from the [latest release](https://github.com/erg1000/Redline/releases/latest).
2. **Open the DMG** and drag **Redline** onto the **Applications** folder.
3. **Open Redline** from your Applications folder. macOS will say *"Redline" Not Opened* because the app isn't notarized by Apple (see [why](#why-does-macos-warn-about-redline)). Click **Done**.
4. **Allow it once:** open **System Settings → Privacy & Security**, scroll down to the *Security* section, and click **Open Anyway** next to *"Redline" was blocked…*. Confirm with your password or Touch ID, then click **Open Anyway** again.
5. **Look at the top right of your screen.** Redline lives in the menu bar as a small anger mark 💢. It has no window and no Dock icon, so nothing else appears when it starts.
6. **Allow browser access:** the first time Safari or Chrome is in front, macOS asks whether Redline may control it. Click **Allow**. Redline only reads the address of the active tab; nothing is recorded or sent anywhere.
7. Optional: open **Settings…** from the menu to set your working hours and sites, and turn on **Launch at Login**.

> **Can't see the anger mark?** On MacBooks with a notch, menu bar icons can hide behind it when the menu bar is full. Quit a few other menu bar apps, or hold ⌘ and drag other icons to make room.

<details>
<summary>Prefer the Terminal?</summary>

Instead of steps 3–4, remove the download quarantine and open the app:

```bash
xattr -dr com.apple.quarantine /Applications/Redline.app
open /Applications/Redline.app
```
</details>

### Why does macOS warn about Redline?

Apple only lets apps open without a warning if they're signed with a paid Apple Developer ID and notarized. Redline is a free, open-source project and isn't notarized (yet), so macOS asks you to confirm once. The full source is in this repository, and you can [build it yourself](#building-from-source) instead.

### Uninstalling

Quit Redline (click the anger mark → **Quit Redline**), turn off **Launch at Login** first if you enabled it, and move `Redline.app` from Applications to the Trash. To also remove its settings, run `defaults delete actionkraft.Redline`. Its browser permission can be removed under System Settings → Privacy & Security → Automation.

## Building from source

Requires Xcode 16 or later (Swift 6) and macOS 15.

```bash
./scripts/build-app.sh            # builds build/Redline.app
./scripts/build-app.sh --install  # also copies it to /Applications and launches it
./scripts/make-release.sh         # builds build/Redline-<version>.dmg for distribution
swift scripts/make-icon.swift     # renders Resources/AppIcon.svg (or .png) into AppIcon.icns
```

If the menu says it can't read your browser, open System Settings → Privacy & Security → Automation and enable Safari/Chrome under Redline.

## License

MIT — see [LICENSE](LICENSE).
