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

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anihortes Keyboard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("To enable the keyboard:")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: 1,
                    text: "Open Settings → General → Keyboard → Keyboards")
                InstructionRow(number: 2,
                    text: "Tap \"Add New Keyboard...\"")
                InstructionRow(number: 3,
                    text: "Select \"Anihortes\" from the list")
                InstructionRow(number: 4,
                    text: "When typing, tap the globe key to switch to Anihortes")
            }

            Text("The keyboard may not appear the first few times you try to select it. Once it begins to appear, it should work reliably.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .fontWeight(.semibold)
                .frame(width: 24, alignment: .trailing)
            Text(text)
        }
    }
}

#Preview {
    ContentView()
}
