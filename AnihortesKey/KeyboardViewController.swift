//
//  KeyboardViewController.swift
//  AnihortesKey
//
//  Created by David Jr on 2026-03-29.
//

import UIKit

class KeyboardViewController: UIInputViewController {

    private var keyViews: [[KeyView]] = []
    private var sideButtons: [UIButton] = []
    private var spaceBarView: UIView?
    private var zeroKeyView: UIView?  // numeric mode: "0" key (left 2/3 of bottom row)
    private var isNumericMode = false

    // Side button references
    private var globeButton: UIButton!
    private var modeButton: UIButton!
    private var backspaceButton: UIButton!
    private var returnButton: UIButton!

    // Backspace repeat timer
    private var backspaceTimer: Timer?

    private let keySpacing: CGFloat = 4
    private let keyboardHeight: CGFloat = 260

    override func viewDidLoad() {
        super.viewDidLoad()

        let heightConstraint = view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        buildKeyboard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutKeys()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        globeButton.isHidden = !needsInputModeSwitchKey
    }

    override func textDidChange(_ textInput: UITextInput?) {
        let isDark = textDocumentProxy.keyboardAppearance == .dark
        for row in keyViews {
            for kv in row { kv.updateAppearance(isDark: isDark) }
        }
    }

    // MARK: - Build Keyboard (create views, no positioning yet)

    private func buildKeyboard() {
        // Clear existing views
        view.subviews.forEach { $0.removeFromSuperview() }
        keyViews.removeAll()
        sideButtons.removeAll()

        let layout = isNumericMode ? KeyMap.numeric : KeyMap.alpha

        // Create key views
        for (rowIndex, rowDefs) in layout.enumerated() {
            var rowKeyViews: [KeyView] = []
            for (_, keyDef) in rowDefs.enumerated() {
                let kv = KeyView(definition: keyDef)
                kv.onGesture = { [weak self] keyView, result in
                    self?.handleKeyGesture(keyView: keyView, result: result)
                }
                view.addSubview(kv)
                rowKeyViews.append(kv)
            }
            keyViews.append(rowKeyViews)
        }

        // Create spacebar (and zero key in numeric mode)
        zeroKeyView?.removeFromSuperview()
        zeroKeyView = nil

        if isNumericMode {
            // Numeric: left 2/3 = "0", right 1/3 = space
            let zeroView = UIView()
            zeroView.backgroundColor = .white
            zeroView.layer.cornerRadius = 6
            zeroView.clipsToBounds = true
            let zeroLabel = UILabel()
            zeroLabel.text = "0"
            zeroLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)
            zeroLabel.textColor = .black
            zeroLabel.textAlignment = .center
            zeroView.addSubview(zeroLabel)
            let zeroTap = UITapGestureRecognizer(target: self, action: #selector(zeroTapped))
            zeroView.addGestureRecognizer(zeroTap)
            view.addSubview(zeroView)
            zeroKeyView = zeroView
        }

        let bar = UIView()
        bar.backgroundColor = .white
        bar.layer.cornerRadius = 6
        bar.clipsToBounds = true
        let label = UILabel()
        label.text = "space"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        bar.addSubview(label)
        let tap = UITapGestureRecognizer(target: self, action: #selector(spaceTapped))
        bar.addGestureRecognizer(tap)
        view.addSubview(bar)
        spaceBarView = bar

        // Create side buttons
        globeButton = makeSideButton(systemImage: "globe",
                                     action: #selector(handleInputModeList(from:with:)),
                                     forEvents: .allTouchEvents)
        modeButton = makeSideButton(title: isNumericMode ? "abc" : "123",
                                    action: #selector(toggleMode))
        backspaceButton = makeSideButton(systemImage: "delete.left",
                                         action: #selector(backspaceTapped))
        returnButton = makeSideButton(systemImage: "return",
                                      action: #selector(returnTapped))

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(backspaceLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        backspaceButton.addGestureRecognizer(longPress)

        sideButtons = [globeButton, modeButton, backspaceButton, returnButton]
        for b in sideButtons { view.addSubview(b) }

        // Re-apply globe visibility (lost when views are recreated on mode toggle)
        globeButton.isHidden = !needsInputModeSwitchKey
    }

    // MARK: - Layout (frame-based, computed from available height)

    private func layoutKeys() {
        let totalHeight = view.bounds.height
        let totalWidth = view.bounds.width
        guard totalHeight > 0, totalWidth > 0 else { return }

        let padding: CGFloat = 2
        let numKeyRows: CGFloat = 4  // 3 rows of keys + 1 spacebar row
        let numSideButtons: CGFloat = 4

        // Key size: square, 4 rows fit in available height
        let availableHeight = totalHeight - 2 * padding
        let keySize = (availableHeight - (numKeyRows - 1) * keySpacing) / numKeyRows

        let gridWidth = 3 * keySize + 2 * keySpacing
        let sideWidth = keySize

        let gridLeft = padding
        let gridTop = padding

        // Layout 3x3 key grid
        for (rowIndex, row) in keyViews.enumerated() {
            for (colIndex, kv) in row.enumerated() {
                let x = gridLeft + CGFloat(colIndex) * (keySize + keySpacing)
                let y = gridTop + CGFloat(rowIndex) * (keySize + keySpacing)
                kv.frame = CGRect(x: x, y: y, width: keySize, height: keySize)
            }
        }

        // Layout bottom row (row index 3): spacebar, or 0+space in numeric mode
        let bottomY = gridTop + 3 * (keySize + keySpacing)

        if isNumericMode, let zeroView = zeroKeyView {
            // "0" takes left 2 key widths + 1 spacing, space takes remaining 1 key width
            let zeroWidth = 2 * keySize + keySpacing
            zeroView.frame = CGRect(x: gridLeft, y: bottomY, width: zeroWidth, height: keySize)
            if let label = zeroView.subviews.first as? UILabel {
                label.frame = zeroView.bounds
            }
            let spaceLeft = gridLeft + zeroWidth + keySpacing
            let spaceWidth = keySize
            spaceBarView?.frame = CGRect(x: spaceLeft, y: bottomY,
                                         width: spaceWidth, height: keySize)
        } else {
            // Alpha mode: spacebar spans full grid width
            spaceBarView?.frame = CGRect(x: gridLeft, y: bottomY,
                                         width: gridWidth, height: keySize)
        }
        if let label = spaceBarView?.subviews.first as? UILabel {
            label.frame = spaceBarView?.bounds ?? .zero
        }

        // Layout side buttons: right of grid, spanning full height
        let sideLeft = gridLeft + gridWidth + keySpacing
        let sideHeight = (availableHeight - (numSideButtons - 1) * keySpacing) / numSideButtons

        for (index, button) in sideButtons.enumerated() {
            let y = padding + CGFloat(index) * (sideHeight + keySpacing)
            button.frame = CGRect(x: sideLeft, y: y, width: sideWidth, height: sideHeight)
        }
    }

    // MARK: - Button Factory

    private func makeSideButton(title: String? = nil, systemImage: String? = nil,
                                action: Selector, forEvents: UIControl.Event = .touchUpInside) -> UIButton {
        let button = UIButton(type: .system)
        if let title = title {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }
        if let systemImage = systemImage {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            button.setImage(UIImage(systemName: systemImage, withConfiguration: config), for: .normal)
        }
        button.backgroundColor = UIColor(white: 0.75, alpha: 1)
        button.tintColor = .label
        button.layer.cornerRadius = 6
        button.addTarget(self, action: action, for: forEvents)
        return button
    }

    // MARK: - Gesture Handling

    private func handleKeyGesture(keyView: KeyView, result: KeyGestureResult) {
        switch result {
        case .tap:
            performAction(keyView.definition.center)

        case .swipe(let direction):
            if let action = keyView.definition.swipes[direction] {
                performAction(action)
            }

        case .swipeAndReturn(let direction):
            // Capitalize the swipe character
            if let action = keyView.definition.swipes[direction] {
                performCapitalized(action)
            }

        case .circular:
            // Capitalize the center character
            performCapitalized(keyView.definition.center)
        }
    }

    private func performCapitalized(_ action: KeyAction) {
        switch action {
        case .character(let s):
            textDocumentProxy.insertText(s.uppercased())
        default:
            // Non-character actions don't have capitals; just perform normally
            performAction(action)
        }
    }

    // MARK: - Actions

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
    }

    @objc private func zeroTapped() {
        textDocumentProxy.insertText("0")
    }

    @objc private func toggleMode() {
        isNumericMode.toggle()
        buildKeyboard()
        layoutKeys()
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func backspaceLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.textDocumentProxy.deleteBackward()
            }
        case .ended, .cancelled:
            backspaceTimer?.invalidate()
            backspaceTimer = nil
        default:
            break
        }
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
    }

    private func performAction(_ action: KeyAction) {
        switch action {
        case .character(let s):
            textDocumentProxy.insertText(s)
        case .tab:
            textDocumentProxy.insertText("\t")
        case .dotCom:
            textDocumentProxy.insertText(".com")
        case .shiftUp, .shiftDown:
            break // Phase 3
        case .compose:
            break // Future
        case .accent:
            break // Phase 3
        }
    }
}
