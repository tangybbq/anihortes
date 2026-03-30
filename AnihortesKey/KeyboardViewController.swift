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
    private var zeroKeyView: UIView?
    private var isNumericMode = false

    // Side button references
    private var globeButton: UIButton!
    private var modeButton: UIButton!
    private var backspaceButton: UIButton!
    private var returnButton: UIButton!

    // Backspace repeat timer
    private var backspaceTimer: Timer?

    // Shift state: nil = use auto-cap, true = force upper, false = force lower
    private var shiftOverride: Bool? = nil

    // Track the last action for accent-combining undo
    private enum LastAction {
        case none
        case character(String)          // plain character inserted
        case combined(base: String, accent: String, result: String)  // accent was combined
        case accentLiteral(String)      // accent inserted as literal (didn't combine)
    }
    private var lastAction: LastAction = .none

    private let keySpacing: CGFloat = 4
    private let keyboardHeight: CGFloat = 300

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
        refreshAppearance()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        refreshAppearance()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        // Cursor moved — update caps state for new position
        updateKeyLabelsCase()
    }

    private func refreshAppearance() {
        let isDark = textDocumentProxy.keyboardAppearance == .dark
        for row in keyViews {
            for kv in row { kv.updateAppearance(isDark: isDark) }
        }
        updateBarAppearance(isDark: isDark)
        updateKeyLabelsCase()
    }

    private func updateBarAppearance(isDark: Bool) {
        let bg = isDark ? UIColor(white: 0.35, alpha: 1) : UIColor.white
        let textColor = isDark ? UIColor.white : UIColor.black
        let secondaryText = isDark ? UIColor(white: 0.75, alpha: 1) : UIColor.secondaryLabel

        spaceBarView?.backgroundColor = bg
        if let label = spaceBarView?.subviews.first as? UILabel {
            label.textColor = secondaryText
        }
        zeroKeyView?.backgroundColor = bg
        if let label = zeroKeyView?.subviews.first as? UILabel {
            label.textColor = textColor
        }

        let buttonBg = isDark ? UIColor(white: 0.25, alpha: 1) : UIColor(white: 0.75, alpha: 1)
        let buttonTint = isDark ? UIColor.white : UIColor.label
        for button in sideButtons {
            button.backgroundColor = buttonBg
            button.tintColor = buttonTint
        }
    }

    // MARK: - Auto-capitalization

    /// Determine if the next character should be capitalized.
    private var shouldAutoCapitalize: Bool {
        // If user explicitly set shift, use that
        if let override = shiftOverride { return override }

        guard let context = textDocumentProxy.documentContextBeforeInput else {
            return true  // empty document = start of input
        }
        if context.isEmpty { return true }

        // After a newline, always capitalize
        if context.last == "\n" { return true }

        // After sentence-ending punctuation followed by optional spaces
        let stripped = String(context.reversed().drop(while: { $0 == " " || $0 == "\t" }).reversed())
        if stripped.isEmpty { return true }
        if let last = stripped.last, ".?!".contains(last) { return true }

        return false
    }

    /// Apply case to a character string based on current shift/auto-cap state.
    private func applyCase(_ s: String) -> String {
        let result = shouldAutoCapitalize ? s.uppercased() : s
        // Consume one-shot shift override after use
        shiftOverride = nil
        return result
    }

    /// Update all key labels to reflect current caps state.
    private func updateKeyLabelsCase() {
        guard !isNumericMode else { return }
        let upper = shouldAutoCapitalize
        for row in keyViews {
            for kv in row { kv.updateCase(uppercase: upper) }
        }
    }

    // MARK: - Build Keyboard

    private func buildKeyboard() {
        view.subviews.forEach { $0.removeFromSuperview() }
        keyViews.removeAll()
        sideButtons.removeAll()

        let layout = isNumericMode ? KeyMap.numeric : KeyMap.alpha

        for (_, rowDefs) in layout.enumerated() {
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

        // Spacebar and zero key
        zeroKeyView?.removeFromSuperview()
        zeroKeyView = nil

        if isNumericMode {
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

        // Side buttons
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

        // Don't check needsInputModeSwitchKey here — it's unreliable before
        // the host connection is established. Hide by default; viewDidAppear
        // will show it if needed.
        globeButton.isHidden = true
        updateKeyLabelsCase()
    }

    // MARK: - Layout

    private func layoutKeys() {
        let totalHeight = view.bounds.height
        let totalWidth = view.bounds.width
        guard totalHeight > 0, totalWidth > 0 else { return }

        let padding: CGFloat = 2
        let bottomPadding = max(padding, view.safeAreaInsets.bottom)
        let numKeyRows: CGFloat = 4
        let numSideButtons: CGFloat = 4

        let availableHeight = totalHeight - padding - bottomPadding
        let keySize = (availableHeight - (numKeyRows - 1) * keySpacing) / numKeyRows

        let gridWidth = 3 * keySize + 2 * keySpacing
        let sideWidth = keySize

        let gridLeft = padding
        let gridTop = padding

        for (rowIndex, row) in keyViews.enumerated() {
            for (colIndex, kv) in row.enumerated() {
                let x = gridLeft + CGFloat(colIndex) * (keySize + keySpacing)
                let y = gridTop + CGFloat(rowIndex) * (keySize + keySpacing)
                kv.frame = CGRect(x: x, y: y, width: keySize, height: keySize)
            }
        }

        let bottomY = gridTop + 3 * (keySize + keySpacing)

        if isNumericMode, let zeroView = zeroKeyView {
            let zeroWidth = 2 * keySize + keySpacing
            zeroView.frame = CGRect(x: gridLeft, y: bottomY, width: zeroWidth, height: keySize)
            if let label = zeroView.subviews.first as? UILabel {
                label.frame = zeroView.bounds
            }
            let spaceLeft = gridLeft + zeroWidth + keySpacing
            spaceBarView?.frame = CGRect(x: spaceLeft, y: bottomY,
                                         width: keySize, height: keySize)
        } else {
            spaceBarView?.frame = CGRect(x: gridLeft, y: bottomY,
                                         width: gridWidth, height: keySize)
        }
        if let label = spaceBarView?.subviews.first as? UILabel {
            label.frame = spaceBarView?.bounds ?? .zero
        }

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
            if let action = keyView.definition.swipes[direction] {
                performCapitalized(action)
            }

        case .circular:
            performCapitalized(keyView.definition.center)

        case .longPress:
            if !isNumericMode, let digit = keyView.definition.digit {
                textDocumentProxy.insertText(digit)
                lastAction = .character(digit)
            }
        }
        updateKeyLabelsCase()
    }

    private func performCapitalized(_ action: KeyAction) {
        switch action {
        case .character(let s):
            let upper = s.uppercased()
            textDocumentProxy.insertText(upper)
            lastAction = .character(upper)
            shiftOverride = nil
        default:
            performAction(action)
        }
    }

    // MARK: - Actions

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
        lastAction = .character(" ")
        updateKeyLabelsCase()
    }

    @objc private func zeroTapped() {
        textDocumentProxy.insertText("0")
        lastAction = .character("0")
    }

    @objc private func toggleMode() {
        isNumericMode.toggle()
        buildKeyboard()
        layoutKeys()
        refreshAppearance()
    }

    @objc private func backspaceTapped() {
        handleBackspace()
        updateKeyLabelsCase()
    }

    @objc private func backspaceLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.textDocumentProxy.deleteBackward()
            }
            lastAction = .none
        case .ended, .cancelled:
            backspaceTimer?.invalidate()
            backspaceTimer = nil
        default:
            break
        }
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
        lastAction = .character("\n")
        updateKeyLabelsCase()
    }

    /// Handle backspace with accent-combining undo.
    private func handleBackspace() {
        switch lastAction {
        case .combined(let base, let accent, _):
            // Undo the combination: delete the combined character,
            // re-insert the base character and the accent as a standalone symbol
            let literal = literalForCombining(accent)
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(base)
            textDocumentProxy.insertText(literal)
            lastAction = .accentLiteral(literal)
        default:
            textDocumentProxy.deleteBackward()
            lastAction = .none
        }
    }

    private func performAction(_ action: KeyAction) {
        switch action {
        case .character(let s):
            let output = isLetter(s) ? applyCase(s) : s
            textDocumentProxy.insertText(output)
            lastAction = .character(output)

        case .tab:
            textDocumentProxy.insertText("\t")
            lastAction = .character("\t")

        case .dotCom:
            textDocumentProxy.insertText(".com")
            lastAction = .character(".com")

        case .shiftUp:
            shiftOverride = true

        case .shiftDown:
            shiftOverride = false

        case .compose:
            break // Future

        case .accent(let combiningChar):
            applyAccent(combiningChar)
        }
    }

    // MARK: - Accent Combining

    /// Try to combine the accent with the previous character. If that produces
    /// a valid precomposed character, replace it. Otherwise insert literally.
    private func applyAccent(_ combiningChar: String) {
        // Get the character before the cursor
        guard let context = textDocumentProxy.documentContextBeforeInput,
              let lastChar = context.last else {
            // Nothing to combine with — insert accent literally
            textDocumentProxy.insertText(combiningChar)
            lastAction = .accentLiteral(combiningChar)
            return
        }

        let base = String(lastChar)
        // Try combining: base + combining character, then normalize to NFC
        let combined = (base + combiningChar).precomposedStringWithCanonicalMapping

        // If NFC normalization produced a single character, the combination is valid
        if combined.count == 1 && combined != base {
            // Replace: delete the base, insert the combined form
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(combined)
            lastAction = .combined(base: base, accent: combiningChar, result: combined)
        } else {
            // No valid combination — insert the accent as a literal character
            // Use a visible representation instead of the combining mark
            let literal = literalForCombining(combiningChar)
            textDocumentProxy.insertText(literal)
            lastAction = .accentLiteral(literal)
        }
    }

    /// Map combining characters to their standalone visible equivalents.
    private func literalForCombining(_ combining: String) -> String {
        switch combining {
        case "\u{0300}": return "`"         // combining grave → backtick
        case "\u{0301}": return "'"         // combining acute → apostrophe
        case "\u{0302}": return "^"         // combining circumflex → caret
        case "\u{0303}": return "~"         // combining tilde → tilde
        case "\u{0308}": return "\u{00A8}"  // combining diaeresis → standalone diaeresis
        default: return combining
        }
    }

    private func isLetter(_ s: String) -> Bool {
        guard let scalar = s.unicodeScalars.first else { return false }
        return CharacterSet.letters.contains(scalar)
    }
}
