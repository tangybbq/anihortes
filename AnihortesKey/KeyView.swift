//
//  KeyView.swift
//  AnihortesKey
//

import UIKit

/// Result of a touch gesture on a key.
enum KeyGestureResult {
    case tap                         // Short touch, no significant movement
    case swipe(SwipeDirection)       // Moved past threshold in a direction
    case swipeAndReturn(SwipeDirection)  // Swiped out and came back (capital)
    case circular                    // Looped gesture (capital of center char)
    case longPress                   // Held without moving (digit in alpha mode)
}

/// Callback when a gesture completes on a key.
typealias KeyGestureHandler = (KeyView, KeyGestureResult) -> Void

class KeyView: UIView {
    let definition: KeyDefinition
    var onGesture: KeyGestureHandler?

    /// Drag threshold as fraction of key size. Default 0.25 (1/4 key width).
    var dragThresholdFraction: CGFloat = 0.25

    private let centerLabel = UILabel()
    private var hintLabels: [SwipeDirection: UILabel] = [:]
    private var isDark = false

    // Touch tracking
    private var touchStart: CGPoint = .zero
    private var touchMaxDistance: CGFloat = 0
    private var touchPath: [CGPoint] = []
    private var longPressTimer: Timer?
    private var didFireLongPress = false

    // Swipe preview
    private var previewLabel: UILabel?
    private var currentSwipeDirection: SwipeDirection?

    /// How long to hold before long-press fires (seconds).
    static let longPressDuration: TimeInterval = 0.4

    init(definition: KeyDefinition) {
        self.definition = definition
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = normalColor
        layer.cornerRadius = 6
        clipsToBounds = true
        isUserInteractionEnabled = true

        // Center label
        centerLabel.text = definition.centerLabel
        centerLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        centerLabel.textAlignment = .center
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerLabel)
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Hint labels for each swipe direction
        for direction in SwipeDirection.allCases {
            let text = definition.label(for: direction)
            guard !text.isEmpty else { continue }
            let label = UILabel()
            label.text = text
            label.font = UIFont.systemFont(ofSize: 16, weight: .light)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            hintLabels[direction] = label
            positionHint(label, direction: direction)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchStart = point
        touchMaxDistance = 0
        touchPath = [point]
        didFireLongPress = false
        setPressed(true)

        // Start long-press timer
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.longPressDuration, repeats: false) {
            [weak self] _ in
            guard let self else { return }
            // Only fire if finger hasn't moved significantly
            if self.touchMaxDistance < self.bounds.width * self.dragThresholdFraction {
                self.didFireLongPress = true
                self.onGesture?(self, .longPress)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchPath.append(point)
        let dist = distance(from: touchStart, to: point)
        if dist > touchMaxDistance {
            touchMaxDistance = dist
        }
        // Cancel long-press if finger moved too far
        let threshold = bounds.width * dragThresholdFraction
        if dist >= threshold {
            longPressTimer?.invalidate()
            longPressTimer = nil
        }

        // Update swipe preview
        if dist >= threshold {
            let dx = point.x - touchStart.x
            let dy = point.y - touchStart.y
            let dir = directionFrom(dx: dx, dy: dy)
            if dir != currentSwipeDirection {
                currentSwipeDirection = dir
                showSwipePreview(direction: dir)
            }
        } else {
            hideSwipePreview()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let endPoint = touch.location(in: self)
        touchPath.append(endPoint)
        setPressed(false)
        hideSwipePreview()
        longPressTimer?.invalidate()
        longPressTimer = nil

        if didFireLongPress { return }

        let result = classifyGesture(endPoint: endPoint)
        onGesture?(self, result)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(false)
        hideSwipePreview()
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private func classifyGesture(endPoint: CGPoint) -> KeyGestureResult {
        let threshold = bounds.width * dragThresholdFraction
        let dx = endPoint.x - touchStart.x
        let dy = endPoint.y - touchStart.y
        let endDistance = distance(from: touchStart, to: endPoint)

        let didSwipeOut = touchMaxDistance >= threshold

        if !didSwipeOut {
            return .tap
        }

        // Check for circular gesture first — a circle may end somewhat far
        // from start (finger doesn't land perfectly), so use a generous
        // return radius. The angular accumulation itself ensures the path
        // actually looped.
        if isCircularPath() {
            return .circular
        }

        let cameBack = endDistance < threshold

        if cameBack {
            // Find the point farthest from start to determine swipe direction
            let farthestPoint = touchPath.max(by: {
                distance(from: touchStart, to: $0) < distance(from: touchStart, to: $1)
            }) ?? endPoint
            let farDx = farthestPoint.x - touchStart.x
            let farDy = farthestPoint.y - touchStart.y

            let direction = directionFrom(dx: farDx, dy: farDy)
            return .swipeAndReturn(direction)
        }

        let direction = directionFrom(dx: dx, dy: dy)
        return .swipe(direction)
    }

    /// Detect a circular gesture by accumulating the total angular change
    /// along the touch path. A full circle accumulates ~2π (360°) of
    /// consistent turning; a swipe-and-return reverses direction and
    /// accumulates very little net angle.
    private func isCircularPath() -> Bool {
        // Filter to points with enough spacing to give meaningful direction
        // vectors, but keep the spacing small so we don't lose the curve.
        let minStep: CGFloat = 3.0  // points (about 1mm on retina)
        var filtered: [CGPoint] = []
        for point in touchPath {
            if let last = filtered.last {
                guard distance(from: last, to: point) >= minStep else { continue }
            }
            filtered.append(point)
        }
        guard filtered.count >= 4 else { return false }

        var totalAngle: CGFloat = 0
        for i in 1..<(filtered.count - 1) {
            let dx1 = filtered[i].x - filtered[i - 1].x
            let dy1 = filtered[i].y - filtered[i - 1].y
            let dx2 = filtered[i + 1].x - filtered[i].x
            let dy2 = filtered[i + 1].y - filtered[i].y
            let cross = dx1 * dy2 - dy1 * dx2
            let dot = dx1 * dx2 + dy1 * dy2
            let angle = atan2(cross, dot)
            totalAngle += angle
        }

        // A full circle is 2π (~6.28). Require at least 240° (~4π/3) of
        // consistent turning in either direction. This accommodates quick,
        // imperfect circles while still rejecting linear swipe-and-returns
        // (which accumulate near 0).
        return abs(totalAngle) >= 4 * .pi / 3
    }

    private func directionFrom(dx: CGFloat, dy: CGFloat) -> SwipeDirection {
        let angle = atan2(dy, dx)
        let normalized = angle < 0 ? angle + 2 * .pi : angle
        let sector = Int((normalized + .pi / 8) / (.pi / 4)) % 8

        switch sector {
        case 0: return .e
        case 1: return .se
        case 2: return .s
        case 3: return .sw
        case 4: return .w
        case 5: return .nw
        case 6: return .n
        case 7: return .ne
        default: return .e
        }
    }

    private func distance(from a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        return sqrt(dx * dx + dy * dy)
    }

    // MARK: - Hint Positioning

    private func positionHint(_ label: UILabel, direction: SwipeDirection) {
        let inset: CGFloat = 3
        switch direction {
        case .n:
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            ])
        case .ne:
            NSLayoutConstraint.activate([
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
                label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            ])
        case .e:
            NSLayoutConstraint.activate([
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        case .se:
            NSLayoutConstraint.activate([
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            ])
        case .s:
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            ])
        case .sw:
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            ])
        case .w:
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        case .nw:
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            ])
        }
    }

    // MARK: - Appearance

    func updateAppearance(isDark: Bool) {
        self.isDark = isDark
        backgroundColor = normalColor
        centerLabel.textColor = isDark ? .white : .black
        for (_, label) in hintLabels {
            label.textColor = isDark ? UIColor(white: 0.75, alpha: 1) : .secondaryLabel
        }
    }

    private var normalColor: UIColor {
        isDark ? UIColor(white: 0.35, alpha: 1) : UIColor.white
    }

    private var pressedColor: UIColor {
        isDark ? UIColor(white: 0.45, alpha: 1) : UIColor(white: 0.88, alpha: 1)
    }

    /// Update all letter labels to show uppercase or lowercase.
    func updateCase(uppercase: Bool) {
        let transform: (String) -> String = uppercase
            ? { $0.uppercased() }
            : { $0.lowercased() }

        if let text = centerLabel.text, text.rangeOfCharacter(from: .letters) != nil {
            centerLabel.text = transform(text)
        }
        for (direction, label) in hintLabels {
            guard let text = label.text, text.rangeOfCharacter(from: .letters) != nil else { continue }
            // Don't transform special action labels (⇧, ⇩, ✓, ⇥, C)
            if case .character = definition.swipes[direction] {
                label.text = transform(text)
            }
        }
    }

    func setPressed(_ pressed: Bool) {
        transform = pressed ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        backgroundColor = pressed ? pressedColor : normalColor
    }

    // MARK: - Swipe Preview

    private func showSwipePreview(direction: SwipeDirection) {
        let text = definition.label(for: direction)
        guard !text.isEmpty else {
            hideSwipePreview()
            return
        }

        if previewLabel == nil {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 32, weight: .medium)
            label.textAlignment = .center
            label.backgroundColor = isDark ? UIColor(white: 0.5, alpha: 1) : UIColor(white: 0.95, alpha: 1)
            label.textColor = isDark ? .white : .black
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            // Preview floats above the key via superview
            superview?.addSubview(label)
            previewLabel = label
        }

        previewLabel?.text = text
        let previewSize: CGFloat = bounds.width * 0.7
        let centerInSuperview = CGPoint(x: frame.midX, y: frame.minY - previewSize / 2 - 4)
        previewLabel?.frame = CGRect(
            x: centerInSuperview.x - previewSize / 2,
            y: centerInSuperview.y - previewSize / 2,
            width: previewSize,
            height: previewSize
        )
    }

    private func hideSwipePreview() {
        previewLabel?.removeFromSuperview()
        previewLabel = nil
        currentSwipeDirection = nil
    }
}
