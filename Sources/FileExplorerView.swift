
import SwiftUI

struct FileExplorerView: View {
    @ObservedObject var viewModel: ContentViewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack(spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    
                    Text("File Explorer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        viewModel.showingDirectoryPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 10, weight: .semibold))
                            
                            Text("Add Folder")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                        )
                    }
                    .buttonStyle(.plain)
                
                if !viewModel.selectedDirectories.isEmpty {
                    Button {
                        viewModel.refreshDirectories()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 10, weight: .semibold))
                            
                            Text("Refresh")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.20, green: 0.78, blue: 0.35))
                        )
                    }
                    .buttonStyle(.plain)
                    
                        Button {
                            viewModel.showingClearAllConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                
                                Text("Clear All")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.96, green: 0.26, blue: 0.21))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            
            Divider()
                .background(Color(red: 0.90, green: 0.90, blue: 0.92))
            
            // File tree content
            Group {
                if viewModel.fileNodes.isEmpty {
                    modernEmptyState
                } else {
                    modernFileTree
                }
            }
        }
        .frame(minWidth: 350, idealWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.99, green: 0.99, blue: 1.0))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 1)
        )
    }

    private var modernEmptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.15),
                                    Color(red: 0.34, green: 0.34, blue: 0.84).opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
                
                VStack(spacing: 6) {
                    Text("No Folders Added")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                    
                    Text("Add project folders to get started with AI assistance")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.47, green: 0.47, blue: 0.49))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            Button {
                viewModel.showingDirectoryPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Choose Folder")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .shadow(color: Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var modernFileTree: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Scanning folders...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(viewModel.fileNodes.enumerated()), id: \.element.path) { index, node in
                            FileRowView(
                                node: node,
                                selectedFiles: $viewModel.selectedFiles,
                                level: 0,
                                isTopLevel: true,
                                onRemoveDirectory: { viewModel.removeDirectory(at: index) },
                                onGitIgnoreSelect: { filePath in
                                    viewModel.gitIgnoreFileToSelect = filePath
                                    viewModel.showingGitIgnoreConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}
