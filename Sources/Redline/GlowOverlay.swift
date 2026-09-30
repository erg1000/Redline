//
//  GlowOverlay.swift
//  Redline
//

import AppKit
import QuartzCore

/// Click-through windows that draw a red glow along the edges of every screen.
@MainActor
final class GlowOverlay {
    private var windows: [NSWindow] = []
    private var intensity: Double = 0
    private var screenObserver: NSObjectProtocol?

    init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuildWindows() }
        }
    }

    /// 0 hides the glow; 1 is full intensity. Changes animate over `duration` seconds.
    func setIntensity(_ value: Double, duration: TimeInterval = 1) {
        let value = min(max(value, 0), 1)
        guard value != intensity else { return }
        intensity = value

        if value > 0, windows.isEmpty { rebuildWindows() }
        for window in windows {
            (window.contentView as? GlowView)?.apply(intensity: value, duration: duration)
        }
    }

    private func rebuildWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map(makeWindow)
        for window in windows {
            (window.contentView as? GlowView)?.apply(intensity: intensity, duration: 0)
            window.orderFrontRegardless()
        }
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.contentView = GlowView(frame: NSRect(origin: .zero, size: screen.frame.size))
        window.setFrame(screen.frame, display: false)
        return window
    }
}

/// Four gradients fading inward from the screen edges, plus a pulse once the glow gets strong.
private final class GlowView: NSView {
    private let container = CALayer()
    private let top = CAGradientLayer()
    private let bottom = CAGradientLayer()
    private let left = CAGradientLayer()
    private let right = CAGradientLayer()
    private var intensity: Double = 0
    private var isPulsing = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.addSublayer(container)
        container.opacity = 0

        let red = NSColor(red: 1, green: 0.1, blue: 0.05, alpha: 0.9).cgColor
        let clear = NSColor(red: 1, green: 0.1, blue: 0.05, alpha: 0).cgColor
        let edges: [(CAGradientLayer, CGPoint, CGPoint)] = [
            (top, CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0)),
            (bottom, CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)),
            (left, CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)),
            (right, CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5)),
        ]
        for (gradient, start, end) in edges {
            gradient.colors = [red, clear]
            gradient.startPoint = start
            gradient.endPoint = end
            container.addSublayer(gradient)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { false }

    func apply(intensity: Double, duration: TimeInterval) {
        self.intensity = intensity
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        container.opacity = intensity > 0 ? Float(0.35 + 0.65 * intensity) : 0
        layoutEdges()
        CATransaction.commit()
        updatePulse()
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layoutEdges()
        CATransaction.commit()
    }

    private func layoutEdges() {
        let size = bounds.size
        container.frame = bounds
        let thickness = min(40 + 220 * intensity, min(size.width, size.height) / 3)
        top.frame = CGRect(x: 0, y: size.height - thickness, width: size.width, height: thickness)
        bottom.frame = CGRect(x: 0, y: 0, width: size.width, height: thickness)
        left.frame = CGRect(x: 0, y: 0, width: thickness, height: size.height)
        right.frame = CGRect(x: size.width - thickness, y: 0, width: thickness, height: size.height)
    }

    /// A slow "breathing" pulse from half intensity upward, so it stays noticeable.
    private func updatePulse() {
        let shouldPulse = intensity >= 0.5
        guard shouldPulse != isPulsing else { return }
        isPulsing = shouldPulse
        guard shouldPulse else {
            [top, bottom, left, right].forEach { $0.removeAnimation(forKey: "pulse") }
            return
        }
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0.55
        pulse.duration = 1.4
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        [top, bottom, left, right].forEach { $0.add(pulse, forKey: "pulse") }
    }
}
