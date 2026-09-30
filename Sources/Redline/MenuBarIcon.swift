//
//  MenuBarIcon.swift
//  Redline
//

import AppKit

/// The anger mark from the app icon, drawn for the menu bar.
enum MenuBarIcon {
    /// Adapts to light/dark menu bars.
    static let normal = make(color: nil, alpha: 1)
    /// Paused or outside working hours.
    static let dimmed = make(color: nil, alpha: 0.4)
    /// On a blocked site, or the glow is still fading out.
    static let alert = make(color: NSColor(red: 1, green: 0.2, blue: 0.13, alpha: 1), alpha: 1)

    /// Draws the four strokes of `Resources/AppIcon.svg`, cropped to the mark and scaled to 18 pt.
    private static func make(color: NSColor?, alpha: CGFloat) -> NSImage {
        let size: CGFloat = 18
        let crop = NSRect(x: 240, y: 240, width: 544, height: 544)
        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.scaleBy(x: size / crop.width, y: size / crop.height)
            context.translateBy(x: -crop.minX, y: -crop.minY)
            for quarter in 0..<4 {
                context.saveGState()
                context.translateBy(x: 512, y: 512)
                context.rotate(by: CGFloat(quarter) * .pi / 2)
                context.translateBy(x: -512, y: -512)
                context.move(to: CGPoint(x: 440, y: 300))
                context.addCurve(to: CGPoint(x: 300, y: 440), control1: CGPoint(x: 450, y: 380), control2: CGPoint(x: 400, y: 430))
                context.restoreGState()
            }
            context.setLineWidth(70)
            context.setLineCap(.round)
            context.setStrokeColor((color ?? .black).withAlphaComponent(alpha).cgColor)
            context.strokePath()
            return true
        }
        image.isTemplate = color == nil
        image.accessibilityDescription = "Redline"
        return image
    }
}
