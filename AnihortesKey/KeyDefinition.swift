// SPDX-License-Identifier: GPL-3.0-or-later WITH App-Store-Exception
//
// Anihortes — a gesture-based keyboard for iOS
// Copyright (C) 2026 David L. Brown, Jr.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// As a special exception to the GNU General Public License, you have
// permission to convey this work through an app store, even if that
// store has terms and conditions that are incompatible with the GPL,
// provided that the work otherwise complies with the GPL and that you
// make the Corresponding Source available as required by the GPL.

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

    /// Numeric mode keys: 1-9 with punctuation swipes carried over from alpha.
    /// Letters are filtered out; only symbols, accents, and special actions remain.
    static let numeric: [[KeyDefinition]] = {
        alpha.enumerated().map { (rowIndex, row) in
            row.enumerated().map { (colIndex, alphaDef) in
                let digit = "\(rowIndex * 3 + colIndex + 1)"
                let punctuationSwipes = alphaDef.swipes.filter { _, action in
                    switch action {
                    case .character(let s):
                        // Keep if it's not a letter
                        guard let scalar = s.unicodeScalars.first else { return true }
                        return !CharacterSet.letters.contains(scalar)
                    case .accent, .tab, .dotCom:
                        return true
                    case .shiftUp, .shiftDown, .compose:
                        return false
                    }
                }
                return KeyDefinition(center: .character(digit),
                                     swipes: punctuationSwipes,
                                     digit: nil)
            }
        }
    }()
}
