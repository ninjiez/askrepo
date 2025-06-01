import SwiftUI
import Foundation

struct ContentView: View {
    @State private var selectedDirectories: [URL] = []
    @State private var fileNodes: [FileNode] = []
    @State private var selectedFiles: Set<String> = []
    @State private var promptText: String = ""
    @State private var totalTokenCount: Int = 0
    @State private var showingDirectoryPicker = false
    @State private var showingClearAllConfirmation = false
    @State private var showingDeleteDirectoryConfirmation = false
    @State private var directoryToDelete: Int?
    @State private var copyFeedbackShown = false
    @State private var saveFeedbackShown = false
    @State private var showingGitIgnoreConfirmation = false
    @State private var gitIgnoreFileToSelect: String?
    @State private var showingSettings = false

    @StateObject private var settings = Settings()
    @FocusState private var isPromptFocused: Bool
    @State private var showingPromptsMenu = false
    
    // Performance optimization: Cache file token counts and debounce prompt token counting
    @State private var fileTokenCache: [String: Int] = [:]
    @State private var promptTokenCount: Int = 0
    @State private var tokenCountingTask: Task<Void, Never>?
    
    private let appVersion = "0.8"
    
    private let systemStructuredOutputPrompt = """


        1. Specify locations and changes:
           - File path/name
           - Function/class being modified
           - The type of change (add/modify/remove)

        2. Show complete code for:
           - Any modified functions (entire function)
           - New functions or methods
           - Changed class definitions
           - Modified configuration blocks
           Only show code units that actually change.

        3. Format all responses as:

           File: path/filename.ext
           Change: Brief description of what's changing
           ```language
           [Complete code block for this change]

        You only need to specify the file and path for the first change in a file, and split the rest into separate codeblocks.
    """
    
    
    
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
            isPresented: $showingDirectoryPicker,
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
        .onChange(of: selectedFiles) { _ in
            calculateFileTokensOnly()
            updateTotalTokenCount()
        }
        .onChange(of: promptText) { _ in
            debouncedPromptTokenCount()
        }
        .onChange(of: settings.systemIgnores) { _ in
            // Reload directories when system ignores change
            loadDirectories()
            // Remove any selected files that are now ignored
            let ignoredFiles = selectedFiles.filter { filePath in
                settings.shouldIgnore(path: filePath, isDirectory: false)
            }
            for ignoredFile in ignoredFiles {
                selectedFiles.remove(ignoredFile)
            }
            calculateFileTokensOnly()
            updateTotalTokenCount()
        }
        .frame(minWidth: 1200, minHeight: 800)
        .onAppear {
            loadPersistedDirectories()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPromptFocused = true
            }
        }
        .onDisappear {
            saveDirectoriesToUserDefaults()
            tokenCountingTask?.cancel()
        }
        .overlay {
            if showingClearAllConfirmation {
                modernConfirmationOverlay(
                    title: "Clear All Directories",
                    message: "Are you sure you want to remove all directories and clear all selected files? This action cannot be undone.",
                    confirmText: "Clear All",
                    onConfirm: {
                        confirmClearAll()
                        showingClearAllConfirmation = false
                    },
                    onCancel: {
                        showingClearAllConfirmation = false
                    }
                )
            }
        }
        .overlay {
            if showingDeleteDirectoryConfirmation {
                modernConfirmationOverlay(
                    title: "Remove Directory",
                    message: {
                        if let index = directoryToDelete, index < selectedDirectories.count {
                            return "Are you sure you want to remove '\(selectedDirectories[index].lastPathComponent)' from the file explorer? All selected files from this directory will also be deselected."
                        } else {
                            return "Are you sure you want to remove this directory from the file explorer?"
                        }
                    }(),
                    confirmText: "Remove",
                    onConfirm: {
                        confirmRemoveDirectory()
                        showingDeleteDirectoryConfirmation = false
                    },
                    onCancel: {
                        directoryToDelete = nil
                        showingDeleteDirectoryConfirmation = false
                    }
                )
            }
        }
        .overlay {
            if showingGitIgnoreConfirmation {
                modernConfirmationOverlay(
                    title: "Include Git-Ignored File",
                    message: {
                        if let filePath = gitIgnoreFileToSelect {
                            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                            return "'\(fileName)' is ignored by .gitignore. Are you sure you want to include it in your AI prompt?"
                        } else {
                            return "This file is ignored by .gitignore. Are you sure you want to include it?"
                        }
                    }(),
                    confirmText: "Include File",
                    onConfirm: {
                        confirmIncludeGitIgnoredFile()
                        showingGitIgnoreConfirmation = false
                    },
                    onCancel: {
                        gitIgnoreFileToSelect = nil
                        showingGitIgnoreConfirmation = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
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
                    value: "\(selectedDirectories.count)",
                    label: "Folders",
                    color: ModernDesign.accentPrimary
                )
                
                modernStatCard(
                    icon: "doc.text.fill",
                    value: "\(selectedFiles.count)",
                    label: "Files",
                    color: ModernDesign.accentSuccess
                )
                
                modernStatCard(
                    icon: "textformat.abc",
                    value: "\(formatTokenCount(totalTokenCount))",
                    label: "Tokens",
                    color: ModernDesign.accentWarning
                )
                
                // Settings button
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ModernDesign.accentPrimary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .background(
                    Circle()
                        .fill(ModernDesign.accentPrimary.opacity(0.12))
                )
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
            fileExplorerPanel
            instructionsPanel
        }
        .padding(.horizontal, ModernDesign.spacing5)
        .padding(.vertical, ModernDesign.spacing4)
    }
    
    private var fileExplorerPanel: some View {
        VStack(spacing: 0) {
            // Panel header
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
                    Button {
                        showingDirectoryPicker = true
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
                    }
                    .background(
                        Capsule()
                            .fill(ModernDesign.accentPrimary)
                    )
                    .buttonStyle(.plain)
                    
                    if !selectedDirectories.isEmpty {
                        Button {
                            showingClearAllConfirmation = true
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
                        }
                        .background(
                            Capsule()
                                .fill(ModernDesign.accentDanger)
                        )
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, ModernDesign.spacing4)
            .padding(.vertical, ModernDesign.spacing3)
            
            Divider()
                .background(ModernDesign.borderLight)
            
            // File tree content
            Group {
                if fileNodes.isEmpty {
                    modernEmptyState
                } else {
                    modernFileTree
                }
            }
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
    
    private var instructionsPanel: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack(spacing: ModernDesign.spacing3) {
                HStack(spacing: ModernDesign.spacing2) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ModernDesign.accentSecondary)
                    
                    Text("AI Instructions")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ModernDesign.textPrimary)
                }
                
                Spacer()
                
                HStack(spacing: ModernDesign.spacing2) {
                    modernPromptsDropdown
                    modernSaveButton
                    modernCopyButton
                }
            }
            .padding(.horizontal, ModernDesign.spacing4)
            .padding(.vertical, ModernDesign.spacing3)
            
            Divider()
                .background(ModernDesign.borderLight)
            
            // Instructions content
            VStack(spacing: ModernDesign.spacing4) {
                modernPromptSection
                modernSelectedFilesSection
            }
            .padding(ModernDesign.spacing4)
        }
        .frame(minWidth: 450, idealWidth: 550)
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
    
    private func modernActionButton(icon: String, action: @escaping () -> Void, style: ButtonStyle) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(style.foregroundColor)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .background(
            Circle()
                .fill(style.backgroundColor)
        )
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
    
    private enum ButtonStyle {
        case primary, danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return ModernDesign.accentPrimary.opacity(0.12)
            case .danger: return ModernDesign.accentDanger.opacity(0.12)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return ModernDesign.accentPrimary
            case .danger: return ModernDesign.accentDanger
            }
        }
    }
    private var modernCopyButton: some View {
        Button {
            copyToClipboard()
            // Show copy feedback
            withAnimation(.easeInOut(duration: 0.2)) {
                copyFeedbackShown = true
            }
            
            // Hide feedback after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    copyFeedbackShown = false
                }
            }
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: copyFeedbackShown ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text(copyFeedbackShown ? "Copied!" : "Copy ⌘⇧C")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .keyboardShortcut("c", modifiers: [.command, .shift]) // Added keyboard shortcut
        .disabled(selectedFiles.isEmpty && promptText.isEmpty)
        .background(
            Capsule()
                .fill(
                    copyFeedbackShown
                    ? ModernDesign.accentSuccess
                    : (selectedFiles.isEmpty && promptText.isEmpty
                        ? ModernDesign.textTertiary
                        : ModernDesign.accentPrimary)
                )
        )
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: copyFeedbackShown)
    }
    
    private var modernPromptsDropdown: some View {
        Menu {
            if settings.promptTemplates.isEmpty {
                Text("No templates available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(settings.promptTemplates) { template in
                    Button {
                        promptText = template.content
                        debouncedPromptTokenCount()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.system(size: 13, weight: .semibold))
                            
                            Text(String(template.content.prefix(50)) + (template.content.count > 50 ? "..." : ""))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    showingSettings = true
                } label: {
                    Label("Manage Templates", systemImage: "gearshape")
                }
            }
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Prompts")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .background(
                Capsule()
                    .fill(ModernDesign.accentPrimary)
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }
    
    private var modernSaveButton: some View {
        Button {
            saveToFile()
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: saveFeedbackShown ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text(saveFeedbackShown ? "Saved!" : "Save")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .disabled(selectedFiles.isEmpty && promptText.isEmpty)
        .background(
            Capsule()
                .fill(
                    saveFeedbackShown 
                    ? ModernDesign.accentSuccess
                    : (selectedFiles.isEmpty && promptText.isEmpty 
                        ? ModernDesign.textTertiary
                        : ModernDesign.accentPrimary)
                )
        )
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: saveFeedbackShown)
    }
    
    private var modernEmptyState: some View {
        VStack(spacing: ModernDesign.spacing5) {
            Spacer()
            
            VStack(spacing: ModernDesign.spacing3) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ModernDesign.accentPrimary.opacity(0.15),
                                    ModernDesign.accentSecondary.opacity(0.15)
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
                        .foregroundColor(ModernDesign.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            Button {
                showingDirectoryPicker = true
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
            }
            .background(
                Capsule()
                    .fill(ModernDesign.accentPrimary)
                    .shadow(color: ModernDesign.accentPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ModernDesign.spacing4)
    }
    
    private var modernFileTree: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                ForEach(Array(fileNodes.enumerated()), id: \.element.path) { index, node in
                    FileRowView(
                        node: node,
                        selectedFiles: $selectedFiles,
                        level: 0,
                        isTopLevel: true,
                        onRemoveDirectory: { removeDirectory(at: index) },
                        onGitIgnoreSelect: { filePath in
                            gitIgnoreFileToSelect = filePath
                            showingGitIgnoreConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal, ModernDesign.spacing3)
            .padding(.vertical, ModernDesign.spacing3)
        }
        .scrollContentBackground(.hidden)
    }
    
    private var modernPromptSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
            HStack {
                Label {
                    Text("Prompt")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ModernDesign.textPrimary)
                } icon: {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ModernDesign.accentSecondary)
                }
                
                Spacer()
                
                Text("\(promptTokenCount) tokens")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(ModernDesign.textTertiary)
                    .padding(.horizontal, ModernDesign.spacing1)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(ModernDesign.backgroundTertiary)
                    )
                    .monospacedDigit()
            }
            
            ZStack {
                // Background and border
                RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                    .fill(ModernDesign.backgroundSecondary)
                    .shadow(color: ModernDesign.shadowCard, radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                            .stroke(
                                isPromptFocused 
                                ? ModernDesign.accentPrimary.opacity(0.8)
                                : ModernDesign.borderLight,
                                lineWidth: isPromptFocused ? 2 : 1
                            )
                    )
                
                // TextEditor with exact same behavior as Selected Files ScrollView
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $promptText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ModernDesign.textPrimary)
                        .scrollContentBackground(.hidden)
                        .focused($isPromptFocused)
                        .padding(.top, 6)
                        .onTapGesture {
                            isPromptFocused = true
                        }
                    
                    if promptText.isEmpty && !isPromptFocused {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Describe what you want the AI to do with your selected files...")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernDesign.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .allowsHitTesting(false)
                        .padding(ModernDesign.spacing3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: ModernDesign.radiusMedium))
            }
            .frame(minHeight: 120, maxHeight: 180)
        }
    }
    
    private var modernSelectedFilesSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
            HStack {
                Label {
                    Text("Selected Files")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ModernDesign.textPrimary)
                } icon: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ModernDesign.accentSuccess)
                }
                
                Spacer()
                
                HStack(spacing: ModernDesign.spacing2) {
                    modernMetricBadge(
                        value: "\(selectedFiles.count)",
                        label: "files",
                        color: ModernDesign.accentSuccess
                    )
                    
                    modernMetricBadge(
                        value: "\(formatTokenCount(totalTokenCount - promptTokenCount))",
                        label: "tokens",
                        color: ModernDesign.accentWarning
                    )
                }
            }
            
            if !selectedFiles.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                        ForEach(Array(selectedFiles).sorted(), id: \.self) { filePath in
                            modernFileChip(filePath: filePath)
                        }
                    }
                    .padding(ModernDesign.spacing2)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                        .fill(ModernDesign.backgroundSecondary)
                        .shadow(color: ModernDesign.shadowCard, radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                        .stroke(ModernDesign.borderLight, lineWidth: 1)
                )
            } else {
                modernEmptyFilesState
            }
        }
    }
    
    private func modernMetricBadge(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(ModernDesign.textTertiary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, ModernDesign.spacing1)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
    
    private var modernEmptyFilesState: some View {
        VStack(spacing: ModernDesign.spacing3) {
            Spacer()
            
            VStack(spacing: ModernDesign.spacing2) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(ModernDesign.textTertiary)
                
                VStack(spacing: 4) {
                    Text("No Files Selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ModernDesign.textSecondary)
                    
                    Text("Choose files from the explorer to include in your AI prompt")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(ModernDesign.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                .fill(ModernDesign.backgroundTertiary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                .stroke(ModernDesign.borderLight, lineWidth: 1)
                .opacity(0.5)
        )
    }
    
    private func modernFileChip(filePath: String) -> some View {
        let fileTokens = getFileTokenCount(for: filePath)
        
        return HStack(spacing: ModernDesign.spacing2) {
            Image(systemName: getFileIconForPath(filePath))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(getFileIconColorForPath(filePath))
                .frame(width: 14)
            
            Text(getRelativePath(for: filePath))
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundColor(ModernDesign.textPrimary)
            
            Spacer(minLength: 0)
            
            // Token count badge
            Text("\(formatTokenCount(fileTokens))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(ModernDesign.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(ModernDesign.backgroundTertiary)
                )
                .monospacedDigit()
            
            Button {
                selectedFiles.remove(filePath)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(ModernDesign.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ModernDesign.spacing2)
        .padding(.vertical, ModernDesign.spacing1)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .fill(ModernDesign.backgroundTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .stroke(ModernDesign.borderLight, lineWidth: 0.5)
        )
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
                
                Link("@flashloanz", destination: URL(string: "https://x.com/flashloanz")!)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ModernDesign.accentPrimary)
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
    
    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
    
    private func addDirectory(_ url: URL) {
        // Don't add if already exists
        if selectedDirectories.contains(where: { $0.path == url.path }) {
            return
        }
        
        selectedDirectories.append(url)
        loadDirectories()
        
        // Automatically select all non-ignored files in the newly added directory
        let newRootNode = fileNodes.last // The most recently added directory
        if let rootNode = newRootNode {
            // Load gitignore parser for this directory
            let gitignoreParser = GitIgnoreParser.loadFromDirectory(url)
            let allFilePaths = FileSystemHelper.getAllNonIgnoredFilePaths(
                from: rootNode, 
                gitignoreParser: gitignoreParser, 
                basePath: url.path
            )
            for filePath in allFilePaths {
                selectedFiles.insert(filePath)
            }
        }
        
        // Save to UserDefaults
        saveDirectoriesToUserDefaults()
    }
    
    private func removeDirectory(at index: Int) {
        directoryToDelete = index
        showingDeleteDirectoryConfirmation = true
    }
    
    private func confirmRemoveDirectory() {
        guard let index = directoryToDelete else { return }
        
        let removedDirectory = selectedDirectories[index]
        selectedDirectories.remove(at: index)
        
        // Remove selected files that belong to this directory
        let directoryPath = removedDirectory.path
        selectedFiles = selectedFiles.filter { !$0.hasPrefix(directoryPath) }
        
        loadDirectories()
        
        // Save to UserDefaults
        saveDirectoriesToUserDefaults()
        
        // Reset confirmation state
        directoryToDelete = nil
    }
    
    private func confirmClearAll() {
        selectedDirectories.removeAll()
        fileNodes.removeAll()
        selectedFiles.removeAll()
        
        // Save to UserDefaults
        saveDirectoriesToUserDefaults()
    }
    
    private func confirmIncludeGitIgnoredFile() {
        guard let filePath = gitIgnoreFileToSelect else { return }
        
        // Add the ignored file to selected files
        selectedFiles.insert(filePath)
        
        // Reset confirmation state
        gitIgnoreFileToSelect = nil
    }
    
    private func loadDirectories() {
        fileNodes = selectedDirectories.map { url in
            FileNode(
                name: url.lastPathComponent,
                path: url.path,
                isDirectory: true,
                children: FileSystemHelper.loadDirectory(url, settings: settings),
                isExpanded: true,
                isIgnored: false
            )
        }
    }
    
    private func getRelativePath(for absolutePath: String) -> String {
        // Find which root directory this file belongs to
        for directory in selectedDirectories {
            let directoryPath = directory.path
            if absolutePath.hasPrefix(directoryPath) {
                let relativePath = String(absolutePath.dropFirst(directoryPath.count))
                let cleanRelativePath = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
                
                // Only include the top-level directory name if there are multiple directories
                if selectedDirectories.count > 1 {
                    return "\(directory.lastPathComponent)/\(cleanRelativePath)"
                } else {
                    return cleanRelativePath
                }
            }
        }
        
        // Fallback to filename if no matching directory found
        return URL(fileURLWithPath: absolutePath).lastPathComponent
    }
    
    private func getAllFilePaths(from node: FileNode) -> [String] {
        var filePaths: [String] = []
        
        if !node.isDirectory {
            filePaths.append(node.path)
        } else {
            for child in node.children {
                filePaths.append(contentsOf: getAllFilePaths(from: child))
            }
        }
        
        return filePaths
    }
    
    // MARK: - Performance Optimized Token Counting
    
    private func debouncedPromptTokenCount() {
        // Cancel any existing task
        tokenCountingTask?.cancel()
        
        // Start a new debounced task
        tokenCountingTask = Task {
            // Wait for 300ms of no typing
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Check if task was cancelled
            if !Task.isCancelled {
                await MainActor.run {
                    promptTokenCount = TokenCounter.countTokens(in: promptText)
                    updateTotalTokenCount()
                }
            }
        }
    }
    
    private func calculateFileTokensOnly() {
        // Only recalculate tokens for files that aren't cached
        for filePath in selectedFiles {
            if fileTokenCache[filePath] == nil {
                if let content = FileSystemHelper.readFileContent(filePath) {
                    fileTokenCache[filePath] = TokenCounter.countTokens(in: content)
                }
            }
        }
        
        // Remove cached tokens for files that are no longer selected
        let selectedFilesSet = Set(selectedFiles)
        fileTokenCache = fileTokenCache.filter { selectedFilesSet.contains($0.key) }
    }
    
    private func updateTotalTokenCount() {
        let fileTokens = selectedFiles.compactMap { fileTokenCache[$0] }.reduce(0, +)
        totalTokenCount = promptTokenCount + fileTokens
    }
    
    private func calculateTokenCount() {
        // Legacy function for initial load - calculate everything at once
        promptTokenCount = TokenCounter.countTokens(in: promptText)
        calculateFileTokensOnly()
        updateTotalTokenCount()
    }
    
    private func copyToClipboard() {
        var output = ""
        
        
        
        if !promptText.isEmpty {
            output += "<prompt>\n\(promptText)\n</prompt>\n\n"
        }
        
        output += "<prompt>\n\(systemStructuredOutputPrompt)\n</prompt>\n\n"
        
        if !selectedFiles.isEmpty {
            output += "<codebase>\n"
            
            for filePath in selectedFiles.sorted() {
                let relativePath = getRelativePath(for: filePath)
                if let content = FileSystemHelper.readFileContent(filePath) {
                    output += "## \(relativePath)\n\n```\n\(content)\n```\n\n"
                }
            }
            
            output += "</codebase>"
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
    
    private func saveToFile() {
        var output = ""
        
        if !promptText.isEmpty {
            output += "<prompt>\n\(promptText)\n</prompt>\n\n"
        }
        
        if !selectedFiles.isEmpty {
            output += "<codebase>\n"
            
            for filePath in selectedFiles.sorted() {
                let relativePath = getRelativePath(for: filePath)
                if let content = FileSystemHelper.readFileContent(filePath) {
                    output += "## \(relativePath)\n\n```\n\(content)\n```\n\n"
                }
            }
            
            output += "</codebase>"
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "askrepo-export.txt"
        savePanel.title = "Save AskRepo Export"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try output.write(to: url, atomically: true, encoding: .utf8)
                    
                    // Show save feedback
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.saveFeedbackShown = true
                        }
                        
                        // Hide feedback after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.saveFeedbackShown = false
                            }
                        }
                    }
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
    
    private func getFileIconForPath(_ filePath: String) -> String {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent.lowercased()
        let fileExtension = (fileName as NSString).pathExtension
        
        // Map file extensions to appropriate SF Symbols
        switch fileExtension {
        case "swift":
            return "doc.text.fill"
        case "js", "jsx":
            return "curlybraces"
        case "ts", "tsx":
            return "curlybraces.square"
        case "html", "htm":
            return "globe"
        case "css", "scss", "less":
            return "paintbrush.fill"
        case "md", "markdown":
            return "doc.richtext"
        case "json":
            return "curlybraces.square.fill"
        case "xml":
            return "doc.badge.gearshape"
        case "yml", "yaml":
            return "doc.plaintext"
        case "txt":
            return "doc.plaintext.fill"
        case "pdf":
            return "doc.fill"
        case "png", "jpg", "jpeg", "gif", "svg", "webp":
            return "photo.fill"
        case "mp4", "mov", "avi":
            return "video.fill"
        case "mp3", "wav", "m4a":
            return "music.note"
        case "zip", "tar", "gz", "rar":
            return "archivebox.fill"
        case "py":
            return "terminal.fill"
        case "rb":
            return "diamond.fill"
        case "go":
            return "arrow.right.circle.fill"
        case "rs":
            return "gear.circle.fill"
        case "c", "cpp", "h", "hpp":
            return "c.circle.fill"
        case "java":
            return "cup.and.saucer.fill"
        case "php":
            return "server.rack"
        default:
            return "doc.text"
        }
    }
    
    private func getFileIconColorForPath(_ filePath: String) -> Color {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent.lowercased()
        let fileExtension = (fileName as NSString).pathExtension
        
        switch fileExtension {
        case "swift":
            return .orange
        case "js", "jsx":
            return Color(red: 0.8, green: 0.6, blue: 0.0) // Dark yellow instead of yellow
        case "ts", "tsx":
            return .blue
        case "html", "htm":
            return .orange
        case "css", "scss", "less":
            return .blue
        case "md", "markdown":
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Dark gray instead of gray
        case "json":
            return .green
        case "xml":
            return .purple
        case "yml", "yaml":
            return .red
        case "png", "jpg", "jpeg", "gif", "svg", "webp":
            return .pink
        case "mp4", "mov", "avi":
            return .purple
        case "mp3", "wav", "m4a":
            return .green
        case "py":
            return .blue
        case "rb":
            return .red
        case "go":
            return .cyan
        case "rs":
            return .orange
        case "java":
            return .red
        case "php":
            return .purple
        default:
            return Color(red: 0.3, green: 0.3, blue: 0.3) // Dark gray instead of primary
        }
    }
    
    private func getFileTokenCount(for filePath: String) -> Int {
        // Use cached value if available
        if let cachedCount = fileTokenCache[filePath] {
            return cachedCount
        }
        
        // Calculate and cache if not available
        if let content = FileSystemHelper.readFileContent(filePath) {
            let tokenCount = TokenCounter.countTokens(in: content)
            fileTokenCache[filePath] = tokenCount
            return tokenCount
        }
        return 0
    }
    
    private func loadPersistedDirectories() {
        if let savedPaths = UserDefaults.standard.array(forKey: "SelectedDirectoryPaths") as? [String] {
            for path in savedPaths {
                let url = URL(fileURLWithPath: path)
                // Check if directory still exists and is accessible
                if FileManager.default.fileExists(atPath: path) {
                    addDirectory(url)
                }
            }
        }
    }
    
    private func saveDirectoriesToUserDefaults() {
        let paths = selectedDirectories.map { $0.path }
        UserDefaults.standard.set(paths, forKey: "SelectedDirectoryPaths")
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
