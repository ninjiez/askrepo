
import SwiftUI

class ContentViewViewModel: ObservableObject {
    @Published var selectedDirectories: [URL] = []
    @Published var fileNodes: [FileNode] = []
    @Published var selectedFiles: Set<String> = []
    @Published var promptText: String = ""
    @Published var totalTokenCount: Int = 0
    @Published var showingDirectoryPicker = false
    @Published var showingClearAllConfirmation = false
    @Published var showingDeleteDirectoryConfirmation = false
    @Published var directoryToDelete: Int?
    @Published var copyFeedbackShown = false
    @Published var saveFeedbackShown = false
    @Published var showingGitIgnoreConfirmation = false
    @Published var gitIgnoreFileToSelect: String?
    @Published var showingSettings = false

    // Search and sorting for selected files
    @Published var searchText: String = ""
    @Published var sortOption: InstructionsPanel.FileSortOption = .hierarchical

    @Published var settings = Settings()
    @Published var isPromptFocused: Bool = false
    @Published var showingPromptsMenu = false
    
    // Performance optimization: Cache file token counts and debounce prompt token counting
    @Published var fileTokenCache: [String: Int] = [:]
    @Published var promptTokenCount: Int = 0
    @Published var tokenCountingTask: Task<Void, Never>?
    var fileTokenTask: Task<Void, Never>?
    
    @Published var isLoading: Bool = false

    func addDirectory(_ url: URL) {
        // Validate the directory path
        guard FilePathValidator.isValidDirectoryPath(url.path) else {
            print("Invalid directory path: \(url.path)")
            return
        }
        
        // Don't add if already exists
        if selectedDirectories.contains(where: { $0.path == url.path }) {
            return
        }
        
        selectedDirectories.append(url)
        loadDirectories(autoSelectNewFiles: true)
        
        // Save to UserDefaults
        saveDirectoriesToUserDefaults()
    }
    
    func removeDirectory(at index: Int) {
        directoryToDelete = index
        showingDeleteDirectoryConfirmation = true
    }
    
    func confirmRemoveDirectory() {
        guard let index = directoryToDelete else { return }
        
        let removedDirectory = selectedDirectories[index]
        selectedDirectories.remove(at: index)
        
        // Remove selected files that belong to this directory
        let directoryPath = removedDirectory.path
        selectedFiles = selectedFiles.filter { !$0.hasPrefix(directoryPath) }
        
        loadDirectories(autoSelectNewFiles: false)
        
        // Save to UserDefaults
        saveDirectoriesToUserDefaults()
        
        // Reset confirmation state
        directoryToDelete = nil
    }
    
    func confirmClearAll() {
        selectedDirectories.removeAll()
        fileNodes.removeAll()
        selectedFiles.removeAll()
        
        // Save to UserDefaults
        saveDirectoriesToUserDefaults()
    }
    
    func refreshDirectories() {
        // Store currently selected files to preserve selection where possible
        let previouslySelectedFiles = Set(selectedFiles)
        
        // Clear file token cache to force recalculation
        fileTokenCache.removeAll()
        
        // Reload all directories without auto-selecting manually deselected files
        loadDirectories(autoSelectNewFiles: false)
        
        // Update selected files - keep files that still exist, remove files that no longer exist
        var updatedSelectedFiles: Set<String> = []
        
        for filePath in previouslySelectedFiles {
            // Check if the file still exists
            if FileManager.default.fileExists(atPath: filePath) {
                // Check if the file is still not ignored by current settings
                if !settings.shouldIgnore(path: filePath, isDirectory: false) {
                    // Check if the file is still not ignored by gitignore
                    var shouldInclude = true
                    for directory in selectedDirectories {
                        if filePath.hasPrefix(directory.path) {
                            let gitignoreParser = GitIgnoreParser.loadFromDirectory(directory)
                            if let parser = gitignoreParser {
                                if parser.shouldIgnore(path: filePath, isDirectory: false, relativeTo: directory.path) {
                                    shouldInclude = false
                                    break
                                }
                            }
                        }
                    }
                    
                    if shouldInclude {
                        updatedSelectedFiles.insert(filePath)
                    }
                }
            }
        }
        
        // Update selected files
        selectedFiles = updatedSelectedFiles
        
        // Recalculate token counts
        calculateFileTokensOnly()
        updateTotalTokenCount()
    }
    
    func confirmIncludeGitIgnoredFile() {
        guard let filePath = gitIgnoreFileToSelect else { return }
        
        // Add the ignored file to selected files
        selectedFiles.insert(filePath)
        
        // Reset confirmation state
        gitIgnoreFileToSelect = nil
    }
    
    func loadDirectories(autoSelectNewFiles: Bool = true) {
        isLoading = true
        let group = DispatchGroup()
        var newFileNodes: [FileNode] = []
        let previouslyLoadedDirectories = Set(fileNodes.map { $0.path })

        for url in selectedDirectories {
            group.enter()
            FileSystemHelper.loadDirectoryAsync(url, settings: settings) { nodes in
                let fileNode = FileNode(
                    name: url.lastPathComponent,
                    path: url.path,
                    isDirectory: true,
                    children: nodes,
                    isExpanded: true,
                    isIgnored: false
                )
                newFileNodes.append(fileNode)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.fileNodes = newFileNodes
            self.isLoading = false
            
            guard autoSelectNewFiles else { return }

            // Automatically select files only for directories that are new to the tree
            for node in newFileNodes where !previouslyLoadedDirectories.contains(node.path) {
                let gitignoreParser = GitIgnoreParser.loadFromDirectory(URL(fileURLWithPath: node.path))
                let allFilePaths = FileSystemHelper.getAllNonIgnoredFilePaths(
                    from: node,
                    gitignoreParser: gitignoreParser,
                    basePath: node.path
                )
                for filePath in allFilePaths {
                    self.selectedFiles.insert(filePath)
                }
            }
        }
    }
    
    func getRelativePath(for absolutePath: String) -> String {
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
    
    func getAllFilePaths(from node: FileNode) -> [String] {
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
    
    func debouncedPromptTokenCount() {
        // Cancel any existing task
        tokenCountingTask?.cancel()
        
        // Start a new debounced task
        tokenCountingTask = Task {
            // Wait for 300ms of no typing
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Check if task was cancelled
            if !Task.isCancelled {
                let count = await TokenCounter.countTokensAsync(in: self.promptText)
                await MainActor.run {
                    self.promptTokenCount = count
                    self.updateTotalTokenCount()
                }
            }
        }
    }
    
    func calculateFileTokensOnly() {
        // Cancel any in-flight work before starting a new recount
        fileTokenTask?.cancel()

        // Remove cached tokens for files that are no longer selected
        let selectedFilesSet = Set(selectedFiles)
        fileTokenCache = fileTokenCache.filter { selectedFilesSet.contains($0.key) }

        // Launch an async task to populate accurate token counts
        fileTokenTask = Task { [weak self] in
            guard let self else { return }
            await self.calculateFileTokensAsync()
        }

        updateTotalTokenCount()
    }
    
    /// Async version of token calculation for better performance
    @MainActor
    func calculateFileTokensAsync() async {
        let filesToProcess = Array(selectedFiles.filter { fileTokenCache[$0] == nil })
        
        // Process files in batches to avoid overwhelming the system
        let batchSize = 10
        let batches = filesToProcess.chunked(into: batchSize)
        
        for batch in batches {
            if Task.isCancelled { break }
            await withTaskGroup(of: (String, Int?).self) { group in
                for filePath in batch {
                    group.addTask {
                        let result = await FileSystemHelper.readFileContentAsync(filePath)
                        switch result {
                        case .success(let content):
                            let tokenCount = await TokenCounter.countTokensAsync(in: content)
                            return (filePath, tokenCount)
                        case .failure:
                            return (filePath, nil)
                        }
                    }
                }
                
                for await (filePath, tokenCount) in group {
                    if let count = tokenCount {
                        fileTokenCache[filePath] = count
                    }
                }
            }
            
            // Update UI after each batch
            updateTotalTokenCount()
        }
        
        // Remove cached tokens for files that are no longer selected
        let selectedFilesSet = Set(selectedFiles)
        fileTokenCache = fileTokenCache.filter { selectedFilesSet.contains($0.key) }

        updateTotalTokenCount()
    }
    
    func updateTotalTokenCount() {
        let fileTokens = selectedFiles.compactMap { fileTokenCache[$0] }.reduce(0, +)
        totalTokenCount = promptTokenCount + fileTokens
    }
    
    func calculateTokenCount() {
        tokenCountingTask?.cancel()
        tokenCountingTask = Task { [weak self] in
            guard let self else { return }
            let count = await TokenCounter.countTokensAsync(in: self.promptText)
            await MainActor.run {
                self.promptTokenCount = count
                self.updateTotalTokenCount()
            }
        }

        calculateFileTokensOnly()
    }
    
    func copyToClipboard() {
        let prompt = promptText
        let fileMetadata = selectedFiles
            .sorted()
            .map { (absolute: $0, relative: getRelativePath(for: $0)) }

        Task.detached { [weak self] in
            guard let self else { return }
            let output = await self.buildExportOutput(prompt: prompt, files: fileMetadata)

            await MainActor.run {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(output, forType: .string)
                self.triggerCopyFeedback()
            }
        }
    }
    
    func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "askrepo-export.txt"
        savePanel.title = "Save AskRepo Export"
        
        savePanel.begin { [weak self] response in
            guard let self, response == .OK, let url = savePanel.url else { return }

            let prompt = self.promptText
            let fileMetadata = self.selectedFiles
                .sorted()
                .map { (absolute: $0, relative: self.getRelativePath(for: $0)) }

            Task.detached { [weak self] in
                guard let self else { return }
                let output = await self.buildExportOutput(prompt: prompt, files: fileMetadata)

                do {
                    try output.write(to: url, atomically: true, encoding: .utf8)
                    await MainActor.run {
                        self.triggerSaveFeedback()
                    }
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }

    private func buildExportOutput(prompt: String, files: [(absolute: String, relative: String)]) async -> String {
        var sections: [String: String] = [:]

        await withTaskGroup(of: (String, String?).self) { group in
            for file in files {
                group.addTask {
                    let result = await FileSystemHelper.readFileContentAsync(file.absolute)
                    switch result {
                    case .success(let content):
                        return (file.absolute, content)
                    case .failure:
                        return (file.absolute, nil)
                    }
                }
            }

            for await (path, content) in group {
                if let content {
                    sections[path] = content
                }
            }
        }

        var output = ""

        if !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output += "<prompt>\n\(prompt)\n</prompt>\n\n"
        }

        if !files.isEmpty {
            output += "<codebase>\n"
            for file in files {
                guard let content = sections[file.absolute] else { continue }
                output += "## \(file.relative)\n\n```\n\(content)\n```\n\n"
            }
            output += "</codebase>"
        }

        return output
    }

    @MainActor
    private func triggerCopyFeedback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            copyFeedbackShown = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.copyFeedbackShown = false
            }
        }
    }

    @MainActor
    private func triggerSaveFeedback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            saveFeedbackShown = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.saveFeedbackShown = false
            }
        }
    }
    
    func getFileIconForPath(_ filePath: String) -> String {
        return FileIconProvider.icon(for: filePath)
    }
    
    func getFileIconColorForPath(_ filePath: String) -> Color {
        return FileIconProvider.color(for: filePath)
    }
    
    func getFileTokenCount(for filePath: String) -> Int {
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
    
    func loadPersistedDirectories() {
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
    
    func saveDirectoriesToUserDefaults() {
        let paths = selectedDirectories.map { $0.path }
        UserDefaults.standard.set(paths, forKey: "SelectedDirectoryPaths")
    }
    
    func formatTokenCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}
