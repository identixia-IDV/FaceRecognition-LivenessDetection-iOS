import UIKit

/// Android `IdentityGuideView` — circular ROI + hold progress ring.
final class IdentityGuideView: UIView {
    private var state: FaceCaptureState = .noFace
    private var progress: CGFloat = 0
    private var pulse: CGFloat = 0
    private var displayLink: CADisplayLink?
    private var pulsePhase: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { nil }

    func setGuideState(_ state: FaceCaptureState, progress: CGFloat) {
        self.state = state
        self.progress = min(1, max(0, progress))
        setNeedsDisplay()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startMotion()
        } else {
            stopMotion()
        }
    }

    private func startMotion() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopMotion() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        pulsePhase += 0.035
        pulse = (sin(pulsePhase) + 1) / 2
        if state == .captureOk { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let roi = IdentityCapture.roiInFrame(bounds.size)
        let path = UIBezierPath(ovalIn: roi)

        ctx.saveGState()
        ctx.addRect(bounds)
        ctx.addPath(path.cgPath)
        ctx.setFillColor(UIColor(red: 0.059, green: 0.102, blue: 0.133, alpha: 0.4).cgColor)
        ctx.drawPath(using: .eoFill)
        ctx.restoreGState()

        let ok = state == .captureOk
        let accent = IXColor.accent.cgColor
        let warn = IXColor.statusError.cgColor
        let stroke = ok ? accent : (state == .noFace ? IXColor.muted.cgColor : warn)

        ctx.setStrokeColor(stroke)
        ctx.setLineWidth(3)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        if ok && progress > 0 {
            ctx.setStrokeColor(accent)
            ctx.setLineWidth(6 + pulse * 2)
            ctx.setLineCap(.round)
            let start = -CGFloat.pi / 2
            let end = start + progress * 2 * .pi
            ctx.addArc(
                center: CGPoint(x: roi.midX, y: roi.midY),
                radius: roi.width / 2,
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
            ctx.strokePath()
        }
    }
}
