// FileOrganiserView.swift
// MacAssist

import SwiftUI

struct FileOrganiserView: View {
    @State private var viewModel = FileOrganiserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Organiser")
                        .font(.largeTitle.bold())
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.showHistory = true
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding()
            
            Spacer()
            
            if viewModel.isOrganising {
                ScanProgressView(progress: 0.5, statusMessage: viewModel.statusMessage)
            } else if let session = viewModel.lastSession {
                successView(session: session)
            } else {
                EmptyStateView(
                    icon: "folder.badge.gearshape",
                    title: "Organize Files",
                    description: "Select a folder to automatically organize its loose files into categorized subfolders (Documents, Images, Videos, etc.).",
                    buttonTitle: "Start Organizing",
                    buttonIcon: "wand.and.stars",
                    showFolderPicker: true,
                    selectedPath: $viewModel.selectedPath
                ) {
                    if !viewModel.selectedPath.isEmpty {
                        Task { await viewModel.organiseSelectedFolder() }
                    }
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $viewModel.showHistory) {
            FileOrganiserHistoryView(viewModel: viewModel)
        }
        .alert("No Files Found", isPresented: $viewModel.showNoFilesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There were no loose files in that folder to organize.")
        }
    }
    
    private func successView(session: OrganiserHistorySession) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.blue.gradient)
                    .padding(.bottom, 8)
                
                Text("Successfully Organized \(session.organisedFiles.count) Files!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)

                Text("From: \(session.directoryPath)")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            GlassCard {
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(session.categoryCounts.keys.sorted(), id: \.self) { key in
                                if let count = session.categoryCounts[key] {
                                    Text("\(key): \(count)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(.blue.opacity(0.15)))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    Divider()
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
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
                                    .foregroundStyle(.secondary)
                                    .frame(width: 90, alignment: .trailing)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: 600, maxHeight: 350)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.lastSession = nil
                }
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 10)
        }
    }
}
