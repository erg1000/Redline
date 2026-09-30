//
//  MenuBarIcon.swift
//  Redline
//

import AppKit

/// The anger mark from the app icon, drawn for the menu bar.
enum MenuBarIcon {
    /// Adapts to light/dark menu bars.
    static let normal = make(color: nil, alpha: 1)
    /// On a blocked site, before the glow starts: the mark with a warning-triangle badge.
    static let watching = make(color: nil, alpha: 1, badge: true)
    /// Paused or outside working hours.
    static let dimmed = make(color: nil, alpha: 0.4)
    /// The glow is on.
    static let glowing = make(color: NSColor(red: 1, green: 0.2, blue: 0.13, alpha: 1), alpha: 1)

    /// Draws the four strokes of `Resources/AppIcon.svg`, cropped to the mark and scaled to 18 pt.
    private static func make(color: NSColor?, alpha: CGFloat, badge: Bool = false) -> NSImage {
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
            if badge { drawBadge(in: context, crop: crop) }
            return true
        }
        image.isTemplate = color == nil
        image.accessibilityDescription = "Redline"
        return image
    }

    /// A small "!" triangle in the bottom-right corner, with a gap cut around it so it reads against the mark.
    private static func drawBadge(in context: CGContext, crop: NSRect) {
        func triangle(inset: CGFloat) -> CGPath {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: crop.maxX - 150, y: crop.maxY - 300 - inset * 1.4))
            path.addLine(to: CGPoint(x: crop.maxX + inset * 1.2, y: crop.maxY + inset * 0.6))
            path.addLine(to: CGPoint(x: crop.maxX - 300 - inset * 1.2, y: crop.maxY + inset * 0.6))
            path.closeSubpath()
            return path
        }
        context.setBlendMode(.clear)
        context.addPath(triangle(inset: 45))
        context.fillPath()
        context.setBlendMode(.normal)
        context.setFillColor(NSColor.black.cgColor)
        context.addPath(triangle(inset: 0))
        context.fillPath()
        // The "!" is cut out of the triangle.
        context.setBlendMode(.clear)
        context.fill(CGRect(x: crop.maxX - 166, y: crop.maxY - 200, width: 32, height: 110))
        context.fillEllipse(in: CGRect(x: crop.maxX - 168, y: crop.maxY - 70, width: 36, height: 36))
        context.setBlendMode(.normal)
    }
}
