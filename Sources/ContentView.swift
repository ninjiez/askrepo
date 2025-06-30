import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var viewModel = ContentViewViewModel()


    private let appVersion = "0.8"
    
    
    // MARK: - App Icon Loading
    private func loadAppIcon() -> NSImage? {
        // Try to load from bundle resources
        if let resourcePath = Bundle.main.path(forResource: "AppIcon", ofType: "icns", inDirectory: "Resources") {
            return NSImage(contentsOfFile: resourcePath)
        }
        
        // Try alternative paths
        if let resourcePath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            return NSImage(contentsOfFile: resourcePath)
        }
        
        // Try loading from Resources directory relative to bundle
        if let bundlePath = Bundle.main.resourcePath {
            let iconPath = "\(bundlePath)/Resources/AppIcon.icns"
            if FileManager.default.fileExists(atPath: iconPath) {
                return NSImage(contentsOfFile: iconPath)
            }
        }
        
        return nil
    }
    
    // MARK: - Modern Design System
    private struct ModernDesign {
        // Sophisticated Spacing Scale
        static let spacing1: CGFloat = 6
        static let spacing2: CGFloat = 12
        static let spacing3: CGFloat = 18
        static let spacing4: CGFloat = 24
        static let spacing5: CGFloat = 32
        static let spacing6: CGFloat = 40
        static let spacing7: CGFloat = 48
        static let spacing8: CGFloat = 64
        
        // Modern Corner Radius
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        static let radiusLarge: CGFloat = 16
        static let radiusXLarge: CGFloat = 20
        
        // Sophisticated Colors
        static let backgroundPrimary = Color(red: 0.98, green: 0.98, blue: 0.99)
        static let backgroundSecondary = Color.white
        static let backgroundTertiary = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let backgroundGlass = Color.white.opacity(0.8)
        
        static let surfaceElevated = Color.white
        static let surfaceCard = Color(red: 0.99, green: 0.99, blue: 1.0)
        
        static let accentPrimary = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentSecondary = Color(red: 0.34, green: 0.34, blue: 0.84)
        static let accentSuccess = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let accentWarning = Color(red: 1.0, green: 0.58, blue: 0.0)
        static let accentDanger = Color(red: 0.96, green: 0.26, blue: 0.21)
        
        static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
        static let textSecondary = Color(red: 0.47, green: 0.47, blue: 0.49)
        static let textTertiary = Color(red: 0.68, green: 0.68, blue: 0.70)
        
        static let borderLight = Color(red: 0.90, green: 0.90, blue: 0.92)
        static let borderMedium = Color(red: 0.82, green: 0.82, blue: 0.84)
        
        // Modern Shadows
        static let shadowCard = Color.black.opacity(0.05)
        static let shadowElevated = Color.black.opacity(0.10)
        static let shadowDeep = Color.black.opacity(0.15)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    ModernDesign.backgroundPrimary,
                    ModernDesign.backgroundTertiary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                modernHeaderView
                mainContentArea
                modernStatusBar
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    addDirectory(url)
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
        .onChange(of: viewModel.selectedFiles) { _ in
            calculateFileTokensOnly()
            updateTotalTokenCount()
        }
        .onChange(of: viewModel.promptText) { _ in
            debouncedPromptTokenCount()
        }
        .onChange(of: viewModel.settings.systemIgnores) { _ in
            // Reload directories when system ignores change
            loadDirectories()
            // Remove any selected files that are now ignored
            let ignoredFiles = viewModel.selectedFiles.filter { filePath in
                viewModel.settings.shouldIgnore(path: filePath, isDirectory: false)
            }
            for ignoredFile in ignoredFiles {
                viewModel.selectedFiles.remove(ignoredFile)
            }
            calculateFileTokensOnly()
            updateTotalTokenCount()
        }
        .frame(minWidth: 1200, minHeight: 800)
        .onAppear {
            loadPersistedDirectories()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //isPromptFocused = true
            }
        }
        .onDisappear {
            saveDirectoriesToUserDefaults()
            viewModel.tokenCountingTask?.cancel()
        }
        .overlay {
            if viewModel.showingClearAllConfirmation {
                modernConfirmationOverlay(
                    title: "Clear All Directories",
                    message: "Are you sure you want to remove all directories and clear all selected files? This action cannot be undone.",
                    confirmText: "Clear All",
                    onConfirm: {
                        confirmClearAll()
                        viewModel.showingClearAllConfirmation = false
                    },
                    onCancel: {
                        viewModel.showingClearAllConfirmation = false
                    }
                )
            }
        }
        .overlay {
            if viewModel.showingDeleteDirectoryConfirmation {
                modernConfirmationOverlay(
                    title: "Remove Directory",
                    message: {
                        if let index = viewModel.directoryToDelete, index < viewModel.selectedDirectories.count {
                            return "Are you sure you want to remove '\(viewModel.selectedDirectories[index].lastPathComponent)' from the file explorer? All selected files from this directory will also be deselected."
                        } else {
                            return "Are you sure you want to remove this directory from the file explorer?"
                        }
                    }(),
                    confirmText: "Remove",
                    onConfirm: {
                        confirmRemoveDirectory()
                        viewModel.showingDeleteDirectoryConfirmation = false
                    },
                    onCancel: {
                        viewModel.directoryToDelete = nil
                        viewModel.showingDeleteDirectoryConfirmation = false
                    }
                )
            }
        }
        .overlay {
            if viewModel.showingGitIgnoreConfirmation {
                modernConfirmationOverlay(
                    title: "Include Git-Ignored File",
                    message: {
                        if let filePath = viewModel.gitIgnoreFileToSelect {
                            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                            return "'\(fileName)' is ignored by .gitignore. Are you sure you want to include it in your AI prompt?"
                        } else {
                            return "This file is ignored by .gitignore. Are you sure you want to include it?"
                        }
                    }(),
                    confirmText: "Include File",
                    onConfirm: {
                        confirmIncludeGitIgnoredFile()
                        viewModel.showingGitIgnoreConfirmation = false
                    },
                    onCancel: {
                        viewModel.gitIgnoreFileToSelect = nil
                        viewModel.showingGitIgnoreConfirmation = false
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(settings: viewModel.settings)
        }
    }
    
    private var modernHeaderView: some View {
        HStack(spacing: ModernDesign.spacing4) {
            // App branding
            HStack(spacing: ModernDesign.spacing2) {
                if let appIconImage = NSImage(named: "AppIcon") ?? loadAppIcon() {
                    Image(nsImage: appIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: ModernDesign.radiusSmall))
                } else {
                    // Fallback to the original gradient design
                ZStack {
                    RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                        .fill(
                            LinearGradient(
                                colors: [ModernDesign.accentPrimary, ModernDesign.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                            .frame(width: 48, height: 48)
                    
                    Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AskRepo")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ModernDesign.textPrimary)
                    
                    Text("AI Code Assistant")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ModernDesign.textSecondary)
                }
            }
            
            Spacer()
            
            // Quick stats
            HStack(spacing: ModernDesign.spacing3) {
                modernStatCard(
                    icon: "folder.fill",
                    value: "\(viewModel.selectedDirectories.count)",
                    label: "Folders",
                    color: ModernDesign.accentPrimary
                )
                
                modernStatCard(
                    icon: "doc.text.fill",
                    value: "\(viewModel.selectedFiles.count)",
                    label: "Files",
                    color: ModernDesign.accentSuccess
                )
                
                modernStatCard(
                    icon: "textformat.abc",
                    value: "\(viewModel.formatTokenCount(viewModel.totalTokenCount))",
                    label: "Tokens",
                    color: ModernDesign.accentWarning
                )
                
                // Settings button
                Button {
                    viewModel.showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ModernDesign.accentPrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(ModernDesign.accentPrimary.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ModernDesign.spacing5)
        .padding(.vertical, ModernDesign.spacing4)
        .background(
            ModernDesign.backgroundGlass
                .background(.ultraThinMaterial)
        )
    }
    
    private func modernStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: ModernDesign.spacing1) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(ModernDesign.textPrimary)
                    .monospacedDigit()
                
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(ModernDesign.textTertiary)
                    .textCase(.uppercase)
            }
        }
        .padding(.horizontal, ModernDesign.spacing2)
        .padding(.vertical, ModernDesign.spacing1)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .fill(color.opacity(0.08))
        )
    }
    
    private var mainContentArea: some View {
        HStack(spacing: ModernDesign.spacing4) {
            FileExplorerView(viewModel: viewModel)
            InstructionsView(viewModel: viewModel)
        }
        .padding(.horizontal, ModernDesign.spacing5)
        .padding(.vertical, ModernDesign.spacing4)
    }
    
    
    
    
    
    private var modernStatusBar: some View {
        HStack(spacing: ModernDesign.spacing4) {
            Text("AskRepo v\(appVersion)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ModernDesign.textTertiary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("Built with ❤️ by")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ModernDesign.textTertiary)
                
                if let url = URL(string: "https://x.com/flashloanz") {
                    Link("@flashloanz", destination: url)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ModernDesign.accentPrimary)
                } else {
                    Text("@flashloanz")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ModernDesign.accentPrimary)
                }
            }
        }
        .padding(.horizontal, ModernDesign.spacing5)
        .padding(.vertical, ModernDesign.spacing2)
        .background(
            ModernDesign.backgroundGlass
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ModernDesign.borderLight),
            alignment: .top
        )
    }
    
    
    private func addDirectory(_ url: URL) {
        viewModel.addDirectory(url)
    }
    
    private func removeDirectory(at index: Int) {
        viewModel.removeDirectory(at: index)
    }
    
    private func confirmRemoveDirectory() {
        viewModel.confirmRemoveDirectory()
    }
    
    private func confirmClearAll() {
        viewModel.confirmClearAll()
    }
    
    private func refreshDirectories() {
        viewModel.refreshDirectories()
    }
    
    private func confirmIncludeGitIgnoredFile() {
        viewModel.confirmIncludeGitIgnoredFile()
    }
    
    private func loadDirectories() {
        viewModel.loadDirectories()
    }
    
    private func getRelativePath(for absolutePath: String) -> String {
        return viewModel.getRelativePath(for: absolutePath)
    }
    
    private func getAllFilePaths(from node: FileNode) -> [String] {
        return viewModel.getAllFilePaths(from: node)
    }
    
    // MARK: - Performance Optimized Token Counting
    
    private func debouncedPromptTokenCount() {
        viewModel.debouncedPromptTokenCount()
    }
    
    private func calculateFileTokensOnly() {
        viewModel.calculateFileTokensOnly()
    }
    
    private func updateTotalTokenCount() {
        viewModel.updateTotalTokenCount()
    }
    
    private func calculateTokenCount() {
        viewModel.calculateTokenCount()
    }
    
    private func copyToClipboard() {
        viewModel.copyToClipboard()
    }
    
    private func saveToFile() {
        viewModel.saveToFile()
    }
    
    private func getFileIconForPath(_ filePath: String) -> String {
        return viewModel.getFileIconForPath(filePath)
    }
    
    private func getFileIconColorForPath(_ filePath: String) -> Color {
        return viewModel.getFileIconColorForPath(filePath)
    }
    
    private func getFileTokenCount(for filePath: String) -> Int {
        return viewModel.getFileTokenCount(for: filePath)
    }
    
    private func loadPersistedDirectories() {
        viewModel.loadPersistedDirectories()
    }
    
    private func saveDirectoriesToUserDefaults() {
        viewModel.saveDirectoriesToUserDefaults()
    }
    
    private func modernConfirmationOverlay(
        title: String,
        message: String,
        confirmText: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Dialog card - small and centered
            VStack(spacing: 0) {
                // Header
                VStack(spacing: ModernDesign.spacing3) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(ModernDesign.accentDanger.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ModernDesign.accentDanger)
                    }
                    
                    // Title
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ModernDesign.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Message
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ModernDesign.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(ModernDesign.spacing4)
                
                // Divider
                Divider()
                    .background(ModernDesign.borderLight)
                
                // Action buttons
                HStack(spacing: 0) {
                    // Cancel button
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ModernDesign.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.plain)
                    .background(ModernDesign.backgroundSecondary)
                    
                    // Vertical divider
                    Rectangle()
                        .fill(ModernDesign.borderLight)
                        .frame(width: 1)
                    
                    // Confirm button
                    Button {
                        onConfirm()
                    } label: {
                        Text(confirmText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ModernDesign.accentDanger)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.plain)
                    .background(ModernDesign.backgroundSecondary)
                }
            }
            .frame(width: 320)
            .fixedSize(horizontal: true, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                    .fill(ModernDesign.surfaceCard)
                    .shadow(color: ModernDesign.shadowDeep, radius: 20, x: 0, y: 8)
            )
            .clipShape(RoundedRectangle(cornerRadius: ModernDesign.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                    .stroke(ModernDesign.borderLight, lineWidth: 1)
            )
        }
    }
} 