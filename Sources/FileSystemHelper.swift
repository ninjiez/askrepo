import Foundation

struct FileSystemHelper {
    static func loadDirectoryAsync(_ url: URL, ignoreMatcher: SystemIgnoreMatcher? = nil, completion: @escaping (Result<[FileNode], FileSystemError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = loadDirectorySafe(url, ignoreMatcher: ignoreMatcher)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Modern async/await version of directory loading
    static func loadDirectoryAsync(_ url: URL, ignoreMatcher: SystemIgnoreMatcher? = nil) async -> Result<[FileNode], FileSystemError> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = loadDirectorySafe(url, ignoreMatcher: ignoreMatcher)
                continuation.resume(returning: result)
            }
        }
    }
    
    static func loadDirectoryAsync(_ url: URL, ignoreMatcher: SystemIgnoreMatcher? = nil, completion: @escaping ([FileNode]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileNodes = loadDirectorySync(url, ignoreMatcher: ignoreMatcher)
            DispatchQueue.main.async {
                completion(fileNodes)
            }
        }
    }
    static func loadDirectorySafe(_ url: URL, ignoreMatcher: SystemIgnoreMatcher? = nil) -> Result<[FileNode], FileSystemError> {
        // Validate path first
        guard FilePathValidator.isValidDirectoryPath(url.path) else {
            return .failure(.invalidPath(url.path))
        }
        
        let didAccessSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Check if path exists and is a directory
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return .failure(.fileNotFound(url.path))
        }
        
        guard isDirectory.boolValue else {
            return .failure(.notADirectory(url.path))
        }
        
        // Load .gitignore if it exists
        let gitignoreParser = GitIgnoreParser.loadFromDirectory(url)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: []
            )
            
            let nodes = contents.compactMap { fileURL in
                createFileNodeSafe(from: fileURL, gitignoreParser: gitignoreParser, basePath: url.path, ignoreMatcher: ignoreMatcher)
            }.sorted { lhs, rhs in
                // Sort directories first, then files, both alphabetically
                if lhs.isDirectory && !rhs.isDirectory {
                    return true
                } else if !lhs.isDirectory && rhs.isDirectory {
                    return false
                } else {
                    return lhs.name.localizedCompare(rhs.name) == .orderedAscending
                }
            }
            
            return .success(nodes)
            
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    static func loadDirectorySync(_ url: URL, ignoreMatcher: SystemIgnoreMatcher? = nil) -> [FileNode] {
        let result = loadDirectorySafe(url, ignoreMatcher: ignoreMatcher)
        switch result {
        case .success(let nodes):
            return nodes
        case .failure(let error):
            print("Error loading directory: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func createFileNodeSafe(from url: URL, gitignoreParser: GitIgnoreParser?, basePath: String, ignoreMatcher: SystemIgnoreMatcher? = nil) -> FileNode? {
        // Validate the file path
        guard FilePathValidator.isValidPath(url.path) else {
            return nil
        }
        
        return createFileNode(from: url, gitignoreParser: gitignoreParser, basePath: basePath, ignoreMatcher: ignoreMatcher)
    }
    
    private static func createFileNode(from url: URL, gitignoreParser: GitIgnoreParser?, basePath: String, ignoreMatcher: SystemIgnoreMatcher? = nil) -> FileNode? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            let isDirectory = resourceValues.isDirectory ?? false
            let isRegularFile = resourceValues.isRegularFile ?? false
            
            // Skip if it's neither a directory nor a regular file
            guard isDirectory || isRegularFile else { return nil }
            
            let name = url.lastPathComponent
            
            // Check if file should be ignored by gitignore
            let isGitIgnored = gitignoreParser?.shouldIgnore(path: url.path, isDirectory: isDirectory, relativeTo: basePath) ?? false
            
            // Check if file should be ignored by system ignores
            let isSystemIgnored = ignoreMatcher?.shouldIgnore(path: url.path, isDirectory: isDirectory) ?? false
            
            // Skip system ignored files and directories entirely
            if isSystemIgnored {
                return nil
            }
            
            // Skip certain file types and directories (but keep gitignore files)
            if shouldSkipFile(name: name, isDirectory: isDirectory) {
                return nil
            }
            
            var children: [FileNode] = []
            if isDirectory && !isGitIgnored {
                // Load children for directories unless gitignored
                children = loadDirectorySync(url, ignoreMatcher: ignoreMatcher)
            }
            
            return FileNode(
                name: name,
                path: url.path,
                isDirectory: isDirectory,
                children: children,
                isExpanded: false,
                isIgnored: isGitIgnored
            )
        } catch {
            print("Error reading file attributes for \(url.path): \(error)")
            return nil
        }
    }
    
    private static func shouldSkipFile(name: String, isDirectory: Bool) -> Bool {
        // Show all directories now, including dot directories like .git, .svn, etc.
        if isDirectory {
            return false
        }
        
        // Only skip binary files and certain extensions that can't be read as text
        let skipExtensions = [".exe", ".dll", ".so", ".dylib", ".a", ".o", ".obj", ".bin", ".class", ".jar"]
        let fileExtension = "." + (name.split(separator: ".").last?.lowercased() ?? "")
        if skipExtensions.contains(fileExtension) {
            return true
        }
        
        return false
    }
    
    static func readFileContentSafe(_ filePath: String) -> Result<String, FileSystemError> {
        guard !filePath.isEmpty else {
            return .failure(.invalidPath(filePath))
        }
        
        // Validate the file path for security
        guard FilePathValidator.isValidPath(filePath) else {
            return .failure(.invalidPath(filePath))
        }
        
        let url = URL(fileURLWithPath: filePath)
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath) else {
            return .failure(.fileNotFound(filePath))
        }
        
        // Check if it's a regular file (not directory)
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
        guard !isDirectory.boolValue else {
            return .failure(.notADirectory(filePath))
        }
        
        do {
            // Check if file is readable text
            let data = try Data(contentsOf: url)
            
            // Try to decode as UTF-8 text
            if let content = String(data: data, encoding: .utf8) {
                return .success(content)
            }
            
            // If UTF-8 fails, try other encodings
            if let content = String(data: data, encoding: .ascii) {
                return .success(content)
            }
            
            return .failure(.encodingFailure(filePath))
            
        } catch CocoaError.fileReadNoPermission {
            return .failure(.accessDenied(filePath))
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    static func readFileContent(_ filePath: String) -> String? {
        let result = readFileContentSafe(filePath)
        switch result {
        case .success(let content):
            return content
        case .failure(let error):
            print("Error reading file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Asynchronously read file content to avoid blocking the main thread
    static func readFileContentAsync(_ filePath: String) async -> Result<String, FileSystemError> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = readFileContentSafe(filePath)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Convenience async method that returns optional string
    static func readFileContentAsyncOptional(_ filePath: String) async -> String? {
        let result = await readFileContentAsync(filePath)
        switch result {
        case .success(let content):
            return content
        case .failure(let error):
            print("Error reading file: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func getAllNonIgnoredFilePaths(from node: FileNode, gitignoreParser: GitIgnoreParser?, basePath: String) -> [String] {
        var filePaths: [String] = []
        
        if node.isIgnored {
            return filePaths
        }
        
        if !node.isDirectory {
            // Use the isIgnored property that was set during file loading
            if !node.isIgnored {
                filePaths.append(node.path)
            }
        } else {
            for child in node.children {
                filePaths.append(contentsOf: getAllNonIgnoredFilePaths(from: child, gitignoreParser: gitignoreParser, basePath: basePath))
            }
        }
        
        return filePaths
    }
} 
