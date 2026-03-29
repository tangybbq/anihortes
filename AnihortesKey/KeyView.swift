//
//  KeyView.swift
//  AnihortesKey
//

import UIKit

class KeyView: UIView {
    let definition: KeyDefinition
    private let centerLabel = UILabel()
    private var hintLabels: [SwipeDirection: UILabel] = [:]

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

    func updateAppearance(isDark: Bool) {
        backgroundColor = isDark ? UIColor(white: 0.35, alpha: 1) : UIColor.white
        centerLabel.textColor = isDark ? .white : .black
        for (_, label) in hintLabels {
            label.textColor = isDark ? UIColor(white: 0.75, alpha: 1) : .secondaryLabel
        }
    }

    // Visual feedback for press
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
