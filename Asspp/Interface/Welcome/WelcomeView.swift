//
//  WelcomeView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ColorfulX
import SwiftUI

struct WelcomeView: View {
    @State var openInstruction: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Image(.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)

                Text("Welcome to MapleStore")
                    .font(.system(.headline, design: .rounded))

                Text("Search the App Store. Keep the versions you need.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer().frame(height: 0)
            }

            VStack(spacing: 16) {
                Spacer()
                HStack(spacing: 8) {
                    Text(version)
                    Button {
                        openInstruction = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $openInstruction) {
                        SimpleInstruction()
                            .padding(32)
                    }
                }
                Text("The App Store API can be unstable. Retry if an error occurs.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ColorfulView(color: .constant(.winter))
                .opacity(0.25)
                .ignoresSafeArea(),
        )
        #if os(macOS)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        #endif
    }
}
