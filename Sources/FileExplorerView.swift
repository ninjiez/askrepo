
import SwiftUI

struct FileExplorerView: View {
    @ObservedObject var viewModel: ContentViewViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack(spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                    
                    Text("File Explorer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
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
                                .fill(ColorScheme.Dynamic.accentPrimary(colorScheme))
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
                                .fill(ColorScheme.Dynamic.accentSuccess)
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
                                    .fill(ColorScheme.Dynamic.accentDanger)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            
            Divider()
                .background(ColorScheme.Dynamic.borderLight(colorScheme))
            
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
                .fill(ColorScheme.Dynamic.surfaceCard(colorScheme))
                .shadow(color: ColorScheme.Dynamic.shadowCard(colorScheme), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
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
                                    ColorScheme.Dynamic.accentPrimary(colorScheme).opacity(0.15),
                                    ColorScheme.Dynamic.accentSecondary(colorScheme).opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                }
                
                VStack(spacing: 6) {
                    Text("No Folders Added")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                    
                    Text("Add project folders to get started with AI assistance")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
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
                        .shadow(color: ColorScheme.Dynamic.accentPrimary(colorScheme).opacity(0.3), radius: 4, x: 0, y: 2)
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
                                onIgnoredSelect: { filePath, reason in
                                    viewModel.ignoredFileToSelect = (path: filePath, reason: reason)
                                    viewModel.showingIgnoredFileConfirmation = true
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
