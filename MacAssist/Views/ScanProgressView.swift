// ScanProgressView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI

/// Animated scan progress indicator with Liquid Glass style.
struct ScanProgressView: View {
    let progress: Double
    let statusMessage: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background circle.
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                // Progress arc.
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .blue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                // Spinning indicator when scanning.
                if progress < 1.0 && progress > 0 {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .offset(y: -60)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }

                // Percentage text.
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    if progress >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear { isAnimating = true }
    }
}
