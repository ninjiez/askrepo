import Foundation

struct FileSystemHelper {
    static func loadDirectory(_ url: URL, settings: Settings? = nil) -> [FileNode] {
        guard url.startAccessingSecurityScopedResource() else {
            return []
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Load .gitignore if it exists
        let gitignoreParser = GitIgnoreParser.loadFromDirectory(url)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: []
            )
            
            return contents.compactMap { fileURL in
                createFileNode(from: fileURL, gitignoreParser: gitignoreParser, basePath: url.path, settings: settings)
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
        } catch {
            print("Error loading directory: \(error)")
            return []
        }
    }
    
    private static func createFileNode(from url: URL, gitignoreParser: GitIgnoreParser?, basePath: String, settings: Settings? = nil) -> FileNode? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            let isDirectory = resourceValues.isDirectory ?? false
            let isRegularFile = resourceValues.isRegularFile ?? false
            
            // Skip if it's neither a directory nor a regular file
            guard isDirectory || isRegularFile else { return nil }
            
            let name = url.lastPathComponent
            
            // Check if file should be ignored by gitignore
            let isIgnored = gitignoreParser?.shouldIgnore(path: url.path, isDirectory: isDirectory, relativeTo: basePath) ?? false
            
            // Check if file should be ignored by system ignores
            let isSystemIgnored = settings?.shouldIgnore(path: url.path, isDirectory: isDirectory) ?? false
            
            // Skip gitignored files and directories entirely
            if isIgnored {
                return nil
            }
            
            // Skip system ignored files and directories entirely
            if isSystemIgnored {
                return nil
            }
            
            // Skip certain file types and directories (but keep gitignore files)
            if shouldSkipFile(name: name, isDirectory: isDirectory) {
                return nil
            }
            
            var children: [FileNode] = []
            if isDirectory {
                // Load children for directories (but don't recurse too deep)
                children = loadDirectory(url, settings: settings)
            }
            
            return FileNode(
                name: name,
                path: url.path,
                isDirectory: isDirectory,
                children: children,
                isExpanded: false,
                isIgnored: false
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
    
    static func readFileContent(_ filePath: String) -> String? {
        guard !filePath.isEmpty else { return nil }
        
        let url = URL(fileURLWithPath: filePath)
        
        do {
            // Check if file is readable text
            let data = try Data(contentsOf: url)
            
            // Try to decode as UTF-8 text
            if let content = String(data: data, encoding: .utf8) {
                return content
            }
            
            // If UTF-8 fails, try other encodings
            if let content = String(data: data, encoding: .ascii) {
                return content
            }
            
            return nil
        } catch {
            print("Error reading file \(filePath): \(error)")
            return nil
        }
    }
    
    static func getAllNonIgnoredFilePaths(from node: FileNode, gitignoreParser: GitIgnoreParser?, basePath: String) -> [String] {
        var filePaths: [String] = []
        
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