// EmptyStateView.swift
// MacAssist

import SwiftUI
import AppKit

/// A beautiful, animated empty-state hero view for scan/action screens.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let buttonIcon: String
    var showFolderPicker: Bool = false
    var selectedPath: Binding<String>?
    let action: () -> Void

    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var glowOpacity: Double = 0.3
    @State private var particleOffset1: CGFloat = 0
    @State private var particleOffset2: CGFloat = 0
    @State private var isHoveringButton = false

    var body: some View {
        ZStack {
            // Floating particles background.
            particlesBackground

            VStack(spacing: 28) {
                // Animated icon.
                ZStack {
                    // Glow ring.
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue.opacity(glowOpacity), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Icon.
                    Image(systemName: icon)
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                }

                VStack(spacing: 10) {
                    Text(title)
                        .font(.title.bold())

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

                // Optional folder picker.
                if showFolderPicker, let path = selectedPath {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text(path.wrappedValue)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 280)

                        Button("Browse…") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            panel.prompt = "Select Folder"
                            if panel.runModal() == .OK, let url = panel.url {
                                path.wrappedValue = url.path
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Large scan button with glow.
                Button(action: action) {
                    HStack(spacing: 10) {
                        Image(systemName: buttonIcon)
                            .font(.title3)
                        Text(buttonTitle)
                            .font(.title3.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .blue.opacity(isHoveringButton ? 0.5 : 0.2), radius: isHoveringButton ? 20 : 10, y: isHoveringButton ? 8 : 4)
                }
                .buttonStyle(.plain)
                .scaleEffect(isHoveringButton ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHoveringButton)
                .onHover { isHoveringButton = $0 }
            }
        }
        .padding(40)
        .onAppear {
            // Breathing animation for icon.
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                iconScale = 1.08
                glowOpacity = 0.5
            }
            // Particle drift.
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                particleOffset1 = 30
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                particleOffset2 = -25
            }
        }
    }

    private var particlesBackground: some View {
        ZStack {
            // Soft floating orbs.
            Circle()
                .fill(.blue.opacity(0.04))
                .frame(width: 200, height: 200)
                .offset(x: -100 + particleOffset1, y: -60 + particleOffset2)

            Circle()
                .fill(.purple.opacity(0.04))
                .frame(width: 150, height: 150)
                .offset(x: 120 + particleOffset2, y: 40 + particleOffset1)

            Circle()
                .fill(.cyan.opacity(0.03))
                .frame(width: 120, height: 120)
                .offset(x: -50 + particleOffset2, y: 80 - particleOffset1)

            Circle()
                .fill(.blue.opacity(0.03))
                .frame(width: 80, height: 80)
                .offset(x: 80 - particleOffset1, y: -90 + particleOffset2)
        }
    }
}
