// CleanSuccessView.swift
// MacAssist

import SwiftUI

/// A beautiful success hero screen shown after cleaning or uninstalling files.
struct CleanSuccessView: View {
    let title: String
    let message: String
    let iconName: String
    let onDone: () -> Void
    
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(.green.gradient)
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
                    .opacity(animateIcon ? 1.0 : 0.0)
                    .padding(.bottom, 8)
                
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: onDone) {
                Text("OK")
                    .font(.headline)
                    .frame(width: 140)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animateIcon = true
            }
        }
    }
}
