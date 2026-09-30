// Renders Resources/AppIcon.icns: a dark squircle with a red edge glow and an eye.
// Run: swift scripts/make-icon.swift
import AppKit

func render(size: CGFloat) -> Data {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        let inset = rect.insetBy(dx: size * 0.1, dy: size * 0.1)
        let shape = NSBezierPath(roundedRect: inset, xRadius: size * 0.18, yRadius: size * 0.18)
        NSColor(white: 0.1, alpha: 1).setFill()
        shape.fill()
        NSGraphicsContext.current?.saveGraphicsState()
        shape.addClip()
        let glow = NSGradient(colors: [NSColor(white: 0.1, alpha: 0), NSColor(red: 1, green: 0.12, blue: 0.05, alpha: 1)])!
        glow.draw(in: shape, relativeCenterPosition: .zero)
        NSGraphicsContext.current?.restoreGraphicsState()
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.32, weight: .semibold)
            .applying(.init(paletteColors: [.white]))
        if let eye = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            let s = eye.size
            eye.draw(in: NSRect(x: (size - s.width) / 2, y: (size - s.height) / 2, width: s.width, height: s.height))
        }
        return true
    }
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(size: CGFloat(base)).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(size: CGFloat(base * 2)).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
