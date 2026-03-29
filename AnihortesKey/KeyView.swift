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

    // Touch tracking
    private var touchStart: CGPoint = .zero
    private var touchMaxDistance: CGFloat = 0
    private var touchPath: [CGPoint] = []
    private var longPressTimer: Timer?
    private var didFireLongPress = false

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
        backgroundColor = UIColor.systemBackground
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
            label.font = UIFont.systemFont(ofSize: 10, weight: .light)
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
        if dist >= bounds.width * dragThresholdFraction {
            longPressTimer?.invalidate()
            longPressTimer = nil
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let endPoint = touch.location(in: self)
        touchPath.append(endPoint)
        setPressed(false)
        longPressTimer?.invalidate()
        longPressTimer = nil

        // Don't fire another gesture if long-press already handled it
        if didFireLongPress { return }

        let result = classifyGesture(endPoint: endPoint)
        onGesture?(self, result)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(false)
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
        backgroundColor = isDark ? UIColor(white: 0.35, alpha: 1) : UIColor.white
        centerLabel.textColor = isDark ? .white : .black
        for (_, label) in hintLabels {
            label.textColor = isDark ? UIColor(white: 0.75, alpha: 1) : .secondaryLabel
        }
    }

    func setPressed(_ pressed: Bool) {
        UIView.animate(withDuration: 0.05) {
            self.transform = pressed ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.backgroundColor = pressed
                ? (self.traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.45, alpha: 1)
                    : UIColor(white: 0.88, alpha: 1))
                : (self.traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.35, alpha: 1)
                    : UIColor.white)
        }
    }
}
