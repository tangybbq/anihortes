//
//  ContentView.swift
//  Anihortes
//
//  Created by David Jr on 2026-03-29.
//

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
