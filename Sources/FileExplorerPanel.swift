import SwiftUI

struct FileExplorerPanel: View {
    @ObservedObject var viewModel: ContentViewViewModel
    
    // Modern Design System - matching ContentView
    private struct ModernDesign {
        static let spacing1: CGFloat = 6
        static let spacing2: CGFloat = 12
        static let spacing3: CGFloat = 18
        static let spacing4: CGFloat = 24
        static let spacing5: CGFloat = 32
        
        static let radiusSmall: CGFloat = 8
        static let radiusLarge: CGFloat = 16
        
        static let backgroundTertiary = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let surfaceCard = Color(red: 0.99, green: 0.99, blue: 1.0)
        static let backgroundGlass = Color.white.opacity(0.8)
        
        static let accentPrimary = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentSuccess = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let accentDanger = Color(red: 0.96, green: 0.26, blue: 0.21)
        
        static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
        static let borderLight = Color(red: 0.90, green: 0.90, blue: 0.92)
        static let shadowCard = Color.black.opacity(0.05)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            headerSection
            
            Divider()
                .background(ModernDesign.borderLight)
            
            // File tree content
            contentSection
        }
        .frame(minWidth: 350, idealWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                .fill(ModernDesign.surfaceCard)
                .shadow(color: ModernDesign.shadowCard, radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                .stroke(ModernDesign.borderLight, lineWidth: 1)
        )
    }
    
    private var headerSection: some View {
        HStack(spacing: ModernDesign.spacing3) {
            HStack(spacing: ModernDesign.spacing2) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ModernDesign.accentPrimary)
                
                Text("File Explorer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ModernDesign.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: ModernDesign.spacing2) {
                addFolderButton
                
                if !viewModel.selectedDirectories.isEmpty {
                    refreshButton
                    clearAllButton
                }
            }
        }
        .padding(.horizontal, ModernDesign.spacing4)
        .padding(.vertical, ModernDesign.spacing3)
    }
    
    private var addFolderButton: some View {
        Button {
            viewModel.showingDirectoryPicker = true
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Add Folder")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ModernDesign.accentPrimary)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var refreshButton: some View {
        Button {
            viewModel.refreshDirectories()
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Refresh")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ModernDesign.accentSuccess)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var clearAllButton: some View {
        Button {
            viewModel.showingClearAllConfirmation = true
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Clear All")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ModernDesign.accentDanger)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.fileNodes.isEmpty {
            emptyState
        } else {
            fileTree
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: ModernDesign.spacing5) {
            Spacer()
            
            VStack(spacing: ModernDesign.spacing3) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ModernDesign.accentPrimary.opacity(0.15),
                                    ModernDesign.accentPrimary.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(ModernDesign.accentPrimary)
                }
                
                VStack(spacing: ModernDesign.spacing1) {
                    Text("No Folders Added")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ModernDesign.textPrimary)
                    
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
                HStack(spacing: ModernDesign.spacing2) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Choose Folder")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, ModernDesign.spacing4)
                .padding(.vertical, ModernDesign.spacing2)
                .background(
                    Capsule()
                        .fill(ModernDesign.accentPrimary)
                        .shadow(color: ModernDesign.accentPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ModernDesign.spacing4)
    }
    
    private var fileTree: some View {
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
                    LazyVStack(alignment: .leading, spacing: ModernDesign.spacing2) {
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
                    .padding(.horizontal, ModernDesign.spacing3)
                    .padding(.vertical, ModernDesign.spacing3)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}
