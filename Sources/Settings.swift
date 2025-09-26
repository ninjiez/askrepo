import Foundation
import SwiftUI

// MARK: - Prompt Template Model
struct PromptTemplate: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var content: String
    
    init(name: String, content: String) {
        self.id = UUID()
        self.name = name
        self.content = content
    }
    
    // Custom CodingKeys to handle UUID properly
    private enum CodingKeys: String, CodingKey {
        case id, name, content
    }
}

// MARK: - Settings Model
class Settings: ObservableObject {
    @Published var systemIgnores: [String] = []
    @Published var promptTemplates: [PromptTemplate] = []
    
    private let userDefaults = UserDefaults.standard
    private let systemIgnoresKey = "systemIgnores"
    private let promptTemplatesKey = "promptTemplates"
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        systemIgnores = userDefaults.stringArray(forKey: systemIgnoresKey) ?? defaultSystemIgnores()
        
        if let data = userDefaults.data(forKey: promptTemplatesKey),
           let templates = try? JSONDecoder().decode([PromptTemplate].self, from: data) {
            promptTemplates = templates
        } else {
            promptTemplates = defaultPromptTemplates()
        }
    }
    
    func saveSettings() {
        userDefaults.set(systemIgnores, forKey: systemIgnoresKey)
        
        if let data = try? JSONEncoder().encode(promptTemplates) {
            userDefaults.set(data, forKey: promptTemplatesKey)
        }
    }
    
    func addSystemIgnore(_ pattern: String) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !systemIgnores.contains(trimmed) {
            systemIgnores.append(trimmed)
            saveSettings()
        }
    }
    
    func removeSystemIgnore(at index: Int) {
        guard index >= 0 && index < systemIgnores.count else { return }
        systemIgnores.remove(at: index)
        saveSettings()
    }
    
    func resetToDefaults() {
        systemIgnores = defaultSystemIgnores()
        saveSettings()
    }
    
    // MARK: - Prompt Template Management
    func addPromptTemplate(name: String, content: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty && !trimmedContent.isEmpty {
            let template = PromptTemplate(name: trimmedName, content: trimmedContent)
            promptTemplates.append(template)
            saveSettings()
        }
    }
    
    func updatePromptTemplate(_ template: PromptTemplate, name: String, content: String) {
        if let index = promptTemplates.firstIndex(where: { $0.id == template.id }) {
            promptTemplates[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            promptTemplates[index].content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            saveSettings()
        }
    }
    
    func removePromptTemplate(_ template: PromptTemplate) {
        promptTemplates.removeAll { $0.id == template.id }
        saveSettings()
    }
    
    private func defaultPromptTemplates() -> [PromptTemplate] {
        return [
            PromptTemplate(
                name: "Code Review",
                content: "Please review this code and provide feedback on:\n- Code quality and best practices\n- Performance optimizations\n- Security considerations\n- Maintainability improvements"
            ),
            PromptTemplate(
                name: "Bug Analysis",
                content: "Please analyze this code for potential bugs and issues:\n- Logic errors\n- Edge cases\n- Memory leaks\n- Race conditions\n- Error handling"
            ),
            PromptTemplate(
                name: "Documentation",
                content: "Please help me document this code:\n- Add comprehensive comments\n- Create API documentation\n- Explain complex algorithms\n- Provide usage examples"
            ),
            PromptTemplate(
                name: "Refactoring",
                content: "Please suggest refactoring improvements for this code:\n- Extract reusable components\n- Improve code organization\n- Reduce complexity\n- Follow design patterns"
            ),
            PromptTemplate(
                name: "Testing",
                content: "Please help me create tests for this code:\n- Unit tests\n- Integration tests\n- Edge case scenarios\n- Mock implementations"
            )
        ]
    }
    
    private func defaultSystemIgnores() -> [String] {
        return [
            ".DS_Store",
            "Thumbs.db",
            "*.log",
            "*.tmp",
            "*.temp",
            ".git/",
            ".svn/",
            ".hg/",
            "node_modules/",
            ".vscode/",
            ".idea/",
            "*.xcworkspace/",
            "*.xcodeproj/",
            "build/",
            "dist/",
            "target/",
            "*.class",
            "*.jar",
            "*.war",
            "*.exe",
            "*.dll",
            "*.so",
            "*.dylib"
        ]
    }
    
    func shouldIgnore(path: String, isDirectory: Bool) -> Bool {
        ignoreSnapshot().shouldIgnore(path: path, isDirectory: isDirectory)
    }

    func ignoreSnapshot() -> SystemIgnoreMatcher {
        SystemIgnoreMatcher(patterns: systemIgnores)
    }
}

// MARK: - Sendable Ignore Matcher
struct SystemIgnoreMatcher: Sendable {
    let patterns: [String]

    func shouldIgnore(path: String, isDirectory: Bool) -> Bool {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        let relativePath = path

        for pattern in patterns {
            if Self.matchesPattern(pattern: pattern, path: relativePath, fileName: fileName, isDirectory: isDirectory) {
                return true
            }
        }

        return false
    }

    private static func matchesPattern(pattern: String, path: String, fileName: String, isDirectory: Bool) -> Bool {
        let trimmedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)

        // Directory-only patterns (ending with /)
        if trimmedPattern.hasSuffix("/") {
            if !isDirectory { return false }
            let dirPattern = String(trimmedPattern.dropLast())
            return matchesWildcard(pattern: dirPattern, text: fileName) ||
                   path.contains("/" + dirPattern + "/") ||
                   path.hasSuffix("/" + dirPattern)
        }

        // Wildcard patterns
        if trimmedPattern.contains("*") || trimmedPattern.contains("?") {
            return matchesWildcard(pattern: trimmedPattern, text: fileName)
        }

        // Exact filename match
        return fileName == trimmedPattern || path.hasSuffix("/" + trimmedPattern)
    }

    private static func matchesWildcard(pattern: String, text: String) -> Bool {
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")

        guard let regex = try? NSRegularExpression(pattern: "^" + regexPattern + "$", options: [.caseInsensitive]) else {
            return false
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

// MARK: - Settings Pages Enum
enum SettingsPage: String, CaseIterable {
    case systemIgnores = "Blacklist"
    case prompts = "Prompts"
    case about = "About"
    
    var icon: String {
        switch self {
        case .systemIgnores: return "eye.slash.fill"
        case .prompts: return "text.bubble.fill"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPage: SettingsPage = .prompts
    @State private var newIgnorePattern: String = ""
    
    // Prompt template states
    @State private var showingAddPromptDialog = false
    @State private var showingEditPromptDialog = false
    @State private var newPromptName: String = ""
    @State private var newPromptContent: String = ""
    @State private var editingTemplate: PromptTemplate?
    @State private var editingName: String = ""
    @State private var editingContent: String = ""
    
    private struct ModernDesign {
        static let spacing1: CGFloat = 6
        static let spacing2: CGFloat = 12
        static let spacing3: CGFloat = 18
        static let spacing4: CGFloat = 24
        static let spacing5: CGFloat = 32
        
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        static let radiusLarge: CGFloat = 16
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ColorScheme.Dynamic.backgroundPrimary(colorScheme), ColorScheme.Dynamic.backgroundSecondary(colorScheme)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                HStack(spacing: 0) {
                    sidebarSection
                    contentSection
                }
            }
        }
        .frame(width: 800, height: 650)

        .sheet(isPresented: $showingAddPromptDialog) {
            addPromptDialog
        }
        .sheet(isPresented: $showingEditPromptDialog) {
            editPromptDialog
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                
                Text("Configure application preferences")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing3)
            .padding(.vertical, ModernDesign.spacing1)
            .background(
                Capsule()
                    .fill(ColorScheme.Dynamic.accentPrimary(colorScheme))
            )
            .buttonStyle(.plain)
        }
        .padding(ModernDesign.spacing4)
        .background(
            ColorScheme.Dynamic.backgroundSecondary(colorScheme)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ColorScheme.Dynamic.borderLight(colorScheme)),
                    alignment: .bottom
                )
        )
    }
    
    private var sidebarSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
            ForEach(SettingsPage.allCases, id: \.self) { page in
                sidebarItem(page: page)
            }
            
            Spacer()
        }
        .padding(ModernDesign.spacing3)
        .frame(width: 200)
        .background(
            ColorScheme.Dynamic.backgroundTertiary(colorScheme)
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(ColorScheme.Dynamic.borderLight(colorScheme)),
                    alignment: .trailing
                )
        )
    }
    
    private func sidebarItem(page: SettingsPage) -> some View {
        Button {
            selectedPage = page
        } label: {
            HStack(spacing: ModernDesign.spacing2) {
                Image(systemName: page.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedPage == page ? ColorScheme.Dynamic.accentPrimary(colorScheme) : ColorScheme.Dynamic.textSecondary(colorScheme))
                    .frame(width: 16)
                
                Text(page.rawValue)
                    .font(.system(size: 14, weight: selectedPage == page ? .semibold : .medium))
                    .foregroundColor(selectedPage == page ? ColorScheme.Dynamic.textPrimary(colorScheme) : ColorScheme.Dynamic.textSecondary(colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                    .fill(selectedPage == page ? ColorScheme.Dynamic.accentPrimary(colorScheme).opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch selectedPage {
            case .systemIgnores:
                systemIgnoresContent
            case .prompts:
                promptsContent
            case .about:
                aboutContent
            }
        }
        .padding(ModernDesign.spacing4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
    }
    
    private var systemIgnoresContent: some View {
        systemIgnoresSection
    }
    
    private var promptsContent: some View {
        promptsSection
    }
    
    private var aboutContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ModernDesign.spacing4) {
            // App Info Section
            VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
                HStack(spacing: ModernDesign.spacing3) {
                    ZStack {
                        RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                            .fill(
                                LinearGradient(
                                    colors: [ColorScheme.Dynamic.accentPrimary(colorScheme), ColorScheme.Dynamic.accentSecondary(colorScheme)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                        Text("AskRepo")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                        
                        Text("AI Code Assistant")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                        
                        Text("Version 0.9")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorScheme.Dynamic.textTertiary(colorScheme))
                    }
                }
            }
            
            Divider()
                .background(ColorScheme.Dynamic.borderLight(colorScheme))
            
            // Description Section
            VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                Text("About")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                
                Text("AskRepo is a powerful AI code assistant that helps you prepare your codebase for AI analysis. Select files and directories, write prompts, and copy everything to your clipboard for use with AI tools like ChatGPT, Claude, or any other AI assistant.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                    .lineSpacing(2)
            }
            
            Divider()
                .background(ColorScheme.Dynamic.borderLight(colorScheme))
            
            // Features Section
            VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                Text("Features")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                
                VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                    featureRow(icon: "folder.fill", text: "Smart file and directory selection")
                    featureRow(icon: "eye.slash.fill", text: "Configurable blacklist")
                    featureRow(icon: "doc.badge.gearshape", text: "Automatic .gitignore support")
                    featureRow(icon: "textformat.abc", text: "Real-time token counting")
                    featureRow(icon: "doc.on.clipboard.fill", text: "One-click copy to clipboard")
                }
            }
            
            Divider()
                .background(ColorScheme.Dynamic.borderLight(colorScheme))
            
            // Developer Section
            VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                Text("Developer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                
                HStack(spacing: ModernDesign.spacing2) {
                    Text("Built with ❤️ by")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                    
                    if let url = URL(string: "https://x.com/flashloanz") {
                        Link("@flashloanz", destination: url)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                    } else {
                        Text("@flashloanz")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                    }
                }
            }
            
            Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: ModernDesign.spacing2) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
        }
    }
    
    private var systemIgnoresSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
            VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                Text("Files and directories that will always be ignored, regardless of .gitignore settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
            }
            
            addIgnoreSection
            ignoreListSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var addIgnoreSection: some View {
        HStack(spacing: ModernDesign.spacing2) {
            TextField("Add pattern (e.g., *.log, node_modules/, .DS_Store)", text: $newIgnorePattern)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                .padding(ModernDesign.spacing2)
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                        .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                )
                .onSubmit {
                    addNewIgnore()
                }
            
            Button {
                addNewIgnore()
            } label: {
                HStack(spacing: ModernDesign.spacing1) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, ModernDesign.spacing2)
                .padding(.vertical, ModernDesign.spacing1)
            }
            .background(
                Capsule()
                    .fill(newIgnorePattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                          ? ColorScheme.Dynamic.textTertiary(colorScheme) 
                          : ColorScheme.Dynamic.accentPrimary(colorScheme))
            )
            .buttonStyle(.plain)
            .disabled(newIgnorePattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private var ignoreListSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
            Text("Current Blacklist (\(settings.systemIgnores.count))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
            
            ScrollView {
                LazyVStack(spacing: ModernDesign.spacing1) {
                    ForEach(Array(settings.systemIgnores.sorted().enumerated()), id: \.offset) { index, pattern in
                        ignorePatternRow(pattern: pattern, index: settings.systemIgnores.firstIndex(of: pattern) ?? index)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                    .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                            .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                    )
            )
        }
    }
    
    private func ignorePatternRow(pattern: String, index: Int) -> some View {
        HStack {
            Image(systemName: pattern.hasSuffix("/") ? "folder.fill" : "doc.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ColorScheme.Dynamic.textTertiary(colorScheme))
                .frame(width: 16)
            
            Text(pattern)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
            
            Spacer()
            
            Button {
                settings.removeSystemIgnore(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.accentDanger)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ModernDesign.spacing2)
        .padding(.vertical, ModernDesign.spacing1)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    private func addNewIgnore() {
        settings.addSystemIgnore(newIgnorePattern)
        newIgnorePattern = ""
    }
    
    // MARK: - Prompt Templates Section
    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
            VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                Text("Create and manage prompt templates for common AI tasks")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
            }
            
            addPromptSection
            promptListSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var addPromptSection: some View {
        HStack {
            Text("Manage your prompt templates")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
            
            Spacer()
            
            Button {
                newPromptName = ""
                newPromptContent = ""
                showingAddPromptDialog = true
            } label: {
                HStack(spacing: ModernDesign.spacing1) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Add Template")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, ModernDesign.spacing3)
                .padding(.vertical, ModernDesign.spacing1)
            }
            .background(
                Capsule()
                    .fill(ColorScheme.Dynamic.accentPrimary(colorScheme))
            )
            .buttonStyle(.plain)
        }
    }
    
    private var promptListSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
            Text("Templates (\(settings.promptTemplates.count))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
            
            ScrollView {
                LazyVStack(spacing: ModernDesign.spacing2) {
                    ForEach(settings.promptTemplates) { template in
                        promptTemplateRow(template: template)
                    }
                }
                .padding(ModernDesign.spacing2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                    .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                            .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                    )
            )
        }
    }
    
    private func promptTemplateRow(template: PromptTemplate) -> some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
            HStack {
                Text(template.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                
                Spacer()
                
                HStack(spacing: ModernDesign.spacing1) {
                    Button {
                        editingTemplate = template
                        editingName = template.name
                        editingContent = template.content
                        showingEditPromptDialog = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        settings.removePromptTemplate(template)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorScheme.Dynamic.accentDanger)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(template.content)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(ModernDesign.spacing2)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                        .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                )
        )
    }
    
    private func addNewPrompt() {
        settings.addPromptTemplate(name: newPromptName, content: newPromptContent)
        newPromptName = ""
        newPromptContent = ""
        showingAddPromptDialog = false
    }
    
    // MARK: - Dialog Views
    private var addPromptDialog: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(colorScheme == .dark ? 0.55 : 0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingAddPromptDialog = false
                }
            
            // Dialog content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Add Prompt Template")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                    
                    Spacer()
                    
                    Button {
                        showingAddPromptDialog = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(ColorScheme.Dynamic.textTertiary(colorScheme))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, ModernDesign.spacing5)
                .padding(.vertical, ModernDesign.spacing4)
                .background(
                    ColorScheme.Dynamic.surfaceElevated(colorScheme)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ColorScheme.Dynamic.borderLight(colorScheme)),
                            alignment: .bottom
                        )
                )
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: ModernDesign.spacing4) {
                        VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                            Text("Template Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                            
                            TextField("Enter template name", text: $newPromptName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                                .padding(ModernDesign.spacing2)
                                .background(
                                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                        .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                        .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                            Text("Template Content")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                    .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                            .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                                    )
                                
                                TextEditor(text: $newPromptContent)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                                    .scrollContentBackground(.hidden)
                                    .padding(ModernDesign.spacing2)
                                
                                if newPromptContent.isEmpty {
                                    Text("Enter your prompt template content...")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(ColorScheme.Dynamic.textTertiary(colorScheme))
                                        .padding(.top, ModernDesign.spacing2 + 8)
                                        .padding(.leading, ModernDesign.spacing2 + 4)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                    .padding(.horizontal, ModernDesign.spacing5)
                    .padding(.vertical, ModernDesign.spacing4)
                }
                .background(ColorScheme.Dynamic.surfaceElevated(colorScheme))
                
                // Footer
                HStack(spacing: ModernDesign.spacing3) {
                    Spacer()
                    
                    Button("Cancel") {
                        showingAddPromptDialog = false
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                    .padding(.horizontal, ModernDesign.spacing4)
                    .padding(.vertical, ModernDesign.spacing2)
                    .background(
                        Capsule()
                            .fill(ColorScheme.Dynamic.backgroundTertiary(colorScheme))
                    )
                    .buttonStyle(.plain)
                    
                    Button("Add Template") {
                        addNewPrompt()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, ModernDesign.spacing4)
                    .padding(.vertical, ModernDesign.spacing2)
                    .background(
                        Capsule()
                            .fill(
                                newPromptName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newPromptContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? ColorScheme.Dynamic.textTertiary(colorScheme)
                                : ColorScheme.Dynamic.accentPrimary(colorScheme)
                            )
                    )
                    .buttonStyle(.plain)
                    .disabled(newPromptName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newPromptContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, ModernDesign.spacing5)
                .padding(.vertical, ModernDesign.spacing4)
                .background(
                    ColorScheme.Dynamic.surfaceElevated(colorScheme)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ColorScheme.Dynamic.borderLight(colorScheme)),
                            alignment: .top
                        )
                )
            }
            .frame(width: 600, height: 500)
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                    .fill(ColorScheme.Dynamic.surfaceElevated(colorScheme))
                    .shadow(color: ColorScheme.Dynamic.shadowDeep(colorScheme), radius: 30, x: 0, y: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: ModernDesign.radiusLarge))
        }
    }
    
    private var editPromptDialog: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(colorScheme == .dark ? 0.55 : 0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingEditPromptDialog = false
                }
            
            // Dialog content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Edit Prompt Template")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                    
                    Spacer()
                    
                    Button {
                        showingEditPromptDialog = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(ColorScheme.Dynamic.textTertiary(colorScheme))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, ModernDesign.spacing5)
                .padding(.vertical, ModernDesign.spacing4)
                .background(
                    ColorScheme.Dynamic.surfaceElevated(colorScheme)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ColorScheme.Dynamic.borderLight(colorScheme)),
                            alignment: .bottom
                        )
                )
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: ModernDesign.spacing4) {
                        VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                            Text("Template Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                            
                            TextField("Enter template name", text: $editingName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                                .padding(ModernDesign.spacing2)
                                .background(
                                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                        .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                        .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: ModernDesign.spacing2) {
                            Text("Template Content")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                    .fill(ColorScheme.Dynamic.backgroundSecondary(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                                            .stroke(ColorScheme.Dynamic.borderLight(colorScheme), lineWidth: 1)
                                    )
                                
                                TextEditor(text: $editingContent)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                                    .scrollContentBackground(.hidden)
                                    .padding(ModernDesign.spacing2)
                            }
                            .frame(height: 180)
                        }
                    }
                    .padding(.horizontal, ModernDesign.spacing5)
                    .padding(.vertical, ModernDesign.spacing4)
                }
                .background(ColorScheme.Dynamic.surfaceElevated(colorScheme))
                
                // Footer
                HStack(spacing: ModernDesign.spacing3) {
                    Spacer()
                    
                    Button("Cancel") {
                        showingEditPromptDialog = false
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                    .padding(.horizontal, ModernDesign.spacing4)
                    .padding(.vertical, ModernDesign.spacing2)
                    .background(
                        Capsule()
                            .fill(ColorScheme.Dynamic.backgroundTertiary(colorScheme))
                    )
                    .buttonStyle(.plain)
                    
                    Button("Save Changes") {
                        if let template = editingTemplate {
                            settings.updatePromptTemplate(template, name: editingName, content: editingContent)
                        }
                        showingEditPromptDialog = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, ModernDesign.spacing4)
                    .padding(.vertical, ModernDesign.spacing2)
                    .background(
                        Capsule()
                            .fill(
                                editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? ColorScheme.Dynamic.textTertiary(colorScheme)
                                : ColorScheme.Dynamic.accentPrimary(colorScheme)
                            )
                    )
                    .buttonStyle(.plain)
                    .disabled(editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, ModernDesign.spacing5)
                .padding(.vertical, ModernDesign.spacing4)
                .background(
                    ColorScheme.Dynamic.surfaceElevated(colorScheme)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ColorScheme.Dynamic.borderLight(colorScheme)),
                            alignment: .top
                        )
                )
            }
            .frame(width: 600, height: 500)
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                    .fill(ColorScheme.Dynamic.surfaceElevated(colorScheme))
                    .shadow(color: ColorScheme.Dynamic.shadowDeep(colorScheme), radius: 30, x: 0, y: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: ModernDesign.radiusLarge))
        }
    }
} 
