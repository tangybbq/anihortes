//
//  SpaceBarView.swift
//  AnihortesKey
//

import UIKit

/// Result of a touch gesture on the spacebar.
enum SpaceBarResult {
    case tap              // Insert space
    case cursorLeft       // Move cursor left one character
    case cursorRight      // Move cursor right one character
    case wordLeft         // Move cursor left one word
    case wordRight        // Move cursor right one word
}

/// Callback when a gesture completes on the spacebar.
typealias SpaceBarGestureHandler = (SpaceBarResult) -> Void

/// Spacebar with drag-to-navigate: swipe left/right to move the cursor by
/// one character, swipe-and-return to move by one word.
class SpaceBarView: UIView {
    var onGesture: SpaceBarGestureHandler?

    /// Drag threshold in points. Set from outside based on the regular key
    /// width so the sensitivity matches the letter keys.
    var dragThreshold: CGFloat = 40

    private let label = UILabel()

    // Touch tracking
    private var touchStart: CGPoint = .zero
    private var touchMaxDistance: CGFloat = 0
    private var farthestPoint: CGPoint = .zero

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 6
        clipsToBounds = true
        isUserInteractionEnabled = true

        label.text = "space"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        addSubview(label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }

    // MARK: - Appearance

    func updateAppearance(isDark: Bool) {
        backgroundColor = isDark ? UIColor(white: 0.35, alpha: 1) : UIColor.white
        label.textColor = isDark ? UIColor(white: 0.75, alpha: 1) : UIColor.secondaryLabel
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchStart = point
        touchMaxDistance = 0
        farthestPoint = point
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let dist = abs(point.x - touchStart.x)
        if dist > touchMaxDistance {
            touchMaxDistance = dist
            farthestPoint = point
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let endPoint = touch.location(in: self)

        let didSwipeOut = touchMaxDistance >= dragThreshold

        if !didSwipeOut {
            onGesture?(.tap)
            return
        }

        let endDist = abs(endPoint.x - touchStart.x)
        let cameBack = endDist < dragThreshold
        let wentLeft = farthestPoint.x < touchStart.x

        if cameBack {
            // Swipe-and-return → word movement
            onGesture?(wentLeft ? .wordLeft : .wordRight)
        } else {
            // Swipe stayed out → character movement
            let movedLeft = endPoint.x < touchStart.x
            onGesture?(movedLeft ? .cursorLeft : .cursorRight)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Nothing to clean up
    }
}
