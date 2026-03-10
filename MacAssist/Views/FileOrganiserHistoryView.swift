// FileOrganiserHistoryView.swift
// MacAssist

import SwiftUI

struct FileOrganiserHistoryView: View {
    @Bindable var viewModel: FileOrganiserViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Organization History")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    viewModel.clearHistory()
                } label: {
                    Label("Clear History", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(viewModel.history.isEmpty)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.top, .horizontal], 24)
            
            if viewModel.history.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("You haven't organized any folders yet.")
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.history) { session in
                            HistorySessionCard(session: session)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 650, minHeight: 500)
    }
}

struct HistorySessionCard: View {
    let session: OrganiserHistorySession
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label(session.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(isExpanded ? "Hide Details" : "Details") {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(.blue)
            }
            
            // Path
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text(session.directoryPath)
                    .font(.body.monospaced())
            }
            
            // Badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(session.categoryCounts.keys.sorted(), id: \.self) { key in
                        if let count = session.categoryCounts[key] {
                            Text("\(key): \(count)")
                                .font(.caption.bold())
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.purple.opacity(0.15)))
                        }
                    }
                }
            }
            
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)
                
                Text("Files Organized:")
                    .font(.subheadline.bold())
                
                VStack(spacing: 4) {
                    ForEach(session.organisedFiles) { file in
                        HStack {
                            Text(file.originalName)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                Text(file.category)
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                            .frame(width: 100, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.04))
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isExpanded ? Color.blue.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.windowBackgroundColor)))
        )
    }
}
