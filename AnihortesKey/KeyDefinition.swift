//
//  KeyDefinition.swift
//  AnihortesKey
//

import Foundation

/// Represents what happens when a key is tapped or swiped.
enum KeyAction: Equatable {
    case character(String)
    case shiftUp
    case shiftDown
    case dotCom        // inserts ".com"
    case tab
    case compose       // placeholder, not yet implemented
    case accent(String) // combining accent character
}

/// The 8 cardinal/ordinal directions for swipe gestures.
enum SwipeDirection: CaseIterable {
    case n, ne, e, se, s, sw, w, nw
}

/// Defines a single key: its center tap action and up to 8 swipe actions.
struct KeyDefinition {
    let center: KeyAction
    let swipes: [SwipeDirection: KeyAction]

    /// The underlying digit for long-press in alpha mode.
    let digit: String?

    var centerLabel: String {
        switch center {
        case .character(let s): return s
        default: return ""
        }
    }

    func label(for direction: SwipeDirection) -> String {
        guard let action = swipes[direction] else { return "" }
        switch action {
        case .character(let s): return s
        case .shiftUp: return "⇧"
        case .shiftDown: return "⇩"
        case .dotCom: return "✓"
        case .tab: return "⇥"
        case .compose: return "C"
        case .accent(let s):
            // Show readable form of combining characters
            switch s {
            case "\u{0300}": return "`"
            case "\u{0301}": return "'"
            case "\u{0302}": return "^"
            case "\u{0303}": return "~"
            case "\u{0308}": return "¨"
            default: return s
            }
        }
    }
}

/// The full keyboard layout.
struct KeyMap {
    /// 3x3 grid of keys in alphabetic mode, row-major order.
    static let alpha: [[KeyDefinition]] = [
        // Row 0: a, n, i
        [
            KeyDefinition(
                center: .character("a"),
                swipes: [
                    .nw: .compose,
                    .e: .character("-"),
                    .sw: .character("$"),
                    .s: .character("•"),
                    .se: .character("v"),
                ],
                digit: "1"
            ),
            KeyDefinition(
                center: .character("n"),
                swipes: [
                    .nw: .accent("\u{0300}"),  // combining grave
                    .n: .accent("\u{0302}"),  // combining circumflex
                    .ne: .accent("\u{0301}"), // combining acute
                    .w: .character("+"),
                    .e: .character("!"),
                    .sw: .character("/"),
                    .s: .character("l"),
                    .se: .character("\\"),
                ],
                digit: "2"
            ),
            KeyDefinition(
                center: .character("i"),
                swipes: [
                    .w: .character("?"),
                    .sw: .character("x"),
                    .s: .character("="),
                    .se: .character("€"),
                ],
                digit: "3"
            ),
        ],
        // Row 1: h, o, r
        [
            KeyDefinition(
                center: .character("h"),
                swipes: [
                    .nw: .character("{"),
                    .ne: .character("%"),
                    .w: .character("("),
                    .e: .character("k"),
                    .sw: .character("["),
                    .s: .dotCom,
                    .se: .character("_"),
                ],
                digit: "4"
            ),
            KeyDefinition(
                center: .character("o"),
                swipes: [
                    .nw: .character("q"),
                    .n: .character("u"),
                    .ne: .character("p"),
                    .w: .character("c"),
                    .e: .character("b"),
                    .sw: .character("g"),
                    .s: .character("d"),
                    .se: .character("j"),
                ],
                digit: "5"
            ),
            KeyDefinition(
                center: .character("r"),
                swipes: [
                    .nw: .character("|"),
                    .n: .shiftUp,
                    .ne: .character("}"),
                    .w: .character("m"),
                    .e: .character(")"),
                    .sw: .character("@"),
                    .s: .shiftDown,
                    .se: .character("]"),
                ],
                digit: "6"
            ),
        ],
        // Row 2: t, e, s
        [
            KeyDefinition(
                center: .character("t"),
                swipes: [
                    .nw: .accent("\u{0303}"),  // combining tilde
                    .n: .accent("\u{0308}"),   // combining diaeresis
                    .ne: .character("y"),
                    .w: .character("<"),
                    .e: .character("*"),
                    .s: .tab,
                ],
                digit: "7"
            ),
            KeyDefinition(
                center: .character("e"),
                swipes: [
                    .nw: .character("\""),
                    .n: .character("w"),
                    .ne: .accent("\u{0301}"), // combining acute
                    .e: .character("z"),
                    .sw: .character(","),
                    .s: .character("."),
                    .se: .character(":"),
                ],
                digit: "8"
            ),
            KeyDefinition(
                center: .character("s"),
                swipes: [
                    .nw: .character("f"),
                    .n: .character("&"),
                    .ne: .character("°"),
                    .w: .character("#"),
                    .e: .character(">"),
                    .s: .character(";"),
                ],
                digit: "9"
            ),
        ],
    ]

    /// Numeric mode keys: 1-9 in a 3x3 grid.
    static let numeric: [[KeyDefinition]] = [
        [
            KeyDefinition(center: .character("1"), swipes: [:], digit: nil),
            KeyDefinition(center: .character("2"), swipes: [:], digit: nil),
            KeyDefinition(center: .character("3"), swipes: [:], digit: nil),
        ],
        [
            KeyDefinition(center: .character("4"), swipes: [:], digit: nil),
            KeyDefinition(center: .character("5"), swipes: [:], digit: nil),
            KeyDefinition(center: .character("6"), swipes: [:], digit: nil),
        ],
        [
            KeyDefinition(center: .character("7"), swipes: [:], digit: nil),
            KeyDefinition(center: .character("8"), swipes: [:], digit: nil),
            KeyDefinition(center: .character("9"), swipes: [:], digit: nil),
        ],
    ]

    /// The bottom row "0" key for numeric mode.
    static let zeroKey = KeyDefinition(center: .character("0"), swipes: [:], digit: nil)
}
