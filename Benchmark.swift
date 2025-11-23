import Foundation

// MARK: - FileNode
struct FileNode {
    enum IgnoreReason: Sendable {
        case gitignore
        case system
    }

    let name: String
    let path: String
    let isDirectory: Bool
    let children: [FileNode]
    let isExpanded: Bool
    let ignoreReason: IgnoreReason?
    
    var isIgnored: Bool {
        ignoreReason != nil
    }
    
    init(name: String, path: String, isDirectory: Bool, children: [FileNode] = [], isExpanded: Bool = false, ignoreReason: IgnoreReason? = nil) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.children = children
        self.isExpanded = isExpanded
        self.ignoreReason = ignoreReason
    }
}

// MARK: - FileSystemError
enum FileSystemError: LocalizedError {
    case invalidPath(String)
    case accessDenied(String)
    case fileNotFound(String)
    case notADirectory(String)
    case unreadableFile(String)
    case encodingFailure(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidPath(let path): return "Invalid file path: \(path)"
        case .accessDenied(let path): return "Access denied to: \(path)"
        case .fileNotFound(let path): return "File not found: \(path)"
        case .notADirectory(let path): return "Path is not a directory: \(path)"
        case .unreadableFile(let path): return "Cannot read file: \(path)"
        case .encodingFailure(let path): return "Text encoding failed for: \(path)"
        case .unknown(let error): return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - FilePathValidator
struct FilePathValidator {
    static func isValidPath(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        guard !path.contains("..") else { return false }
        guard !path.contains("\0") else { return false }
        guard path.rangeOfCharacter(from: CharacterSet.controlCharacters) == nil else { return false }
        guard FileManager.default.fileExists(atPath: path) else { return false }
        return true
    }
    
    static func isValidDirectoryPath(_ path: String) -> Bool {
        guard isValidPath(path) else { return false }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
        return isDirectory.boolValue
    }
}

// MARK: - SystemIgnoreMatcher
struct SystemIgnoreMatcher: Sendable {
    private struct CachedPattern: Sendable {
        let original: String
        let type: PatternType
        let regex: NSRegularExpression?
        
        enum PatternType: Sendable {
            case exact
            case directory
            case wildcard
        }
    }
    
    private let matchers: [CachedPattern]
    
    init(patterns: [String]) {
        self.matchers = patterns.map { pattern in
            let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Directory-only patterns (ending with /)
            if trimmed.hasSuffix("/") {
                let dirPattern = String(trimmed.dropLast())
                // If it has wildcards, we need regex
                if dirPattern.contains("*") || dirPattern.contains("?") {
                    return CachedPattern(
                        original: trimmed,
                        type: .directory,
                        regex: Self.createRegex(from: dirPattern)
                    )
                } else {
                    // Simple directory match
                    return CachedPattern(original: dirPattern, type: .directory, regex: nil)
                }
            }
            
            // Wildcard patterns
            if trimmed.contains("*") || trimmed.contains("?") {
                return CachedPattern(
                    original: trimmed,
                    type: .wildcard,
                    regex: Self.createRegex(from: trimmed)
                )
            }
            
            // Exact filename match
            return CachedPattern(original: trimmed, type: .exact, regex: nil)
        }
    }

    func shouldIgnore(path: String, isDirectory: Bool) -> Bool {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        
        for matcher in matchers {
            switch matcher.type {
            case .directory:
                if !isDirectory { continue }
                if let regex = matcher.regex {
                    if matchesRegex(regex, text: fileName) { return true }
                } else {
                    // Simple directory check
                    if fileName == matcher.original { return true }
                }
                
                // Also check path containment for directories (common for things like node_modules/)
                if path.contains("/" + matcher.original + "/") || path.hasSuffix("/" + matcher.original) {
                    return true
                }
                
            case .wildcard:
                if let regex = matcher.regex {
                    if matchesRegex(regex, text: fileName) { return true }
                }
                
            case .exact:
                if fileName == matcher.original { return true }
            }
        }

        return false
    }

    private static func createRegex(from pattern: String) -> NSRegularExpression? {
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")

        return try? NSRegularExpression(pattern: "^" + regexPattern + "$", options: [.caseInsensitive])
    }
    
    private func matchesRegex(_ regex: NSRegularExpression, text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

// MARK: - GitIgnoreParser
struct GitIgnoreParser {
    private let patterns: [GitIgnorePattern]
    
    struct GitIgnorePattern {
        let pattern: String
        let isNegation: Bool
        let isDirectoryOnly: Bool
        let regex: NSRegularExpression?
        
        init(line: String) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("!") {
                isNegation = true
                pattern = String(trimmed.dropFirst())
            } else {
                isNegation = false
                pattern = trimmed
            }
            isDirectoryOnly = pattern.hasSuffix("/")
            let cleanPattern = isDirectoryOnly ? String(pattern.dropLast()) : pattern
            regex = Self.createRegex(from: cleanPattern)
        }
        
        private static func createRegex(from pattern: String) -> NSRegularExpression? {
            var regexPattern = pattern
            regexPattern = regexPattern.replacingOccurrences(of: ".", with: "\\.")
            regexPattern = regexPattern.replacingOccurrences(of: "+", with: "\\+")
            regexPattern = regexPattern.replacingOccurrences(of: "^", with: "\\^")
            regexPattern = regexPattern.replacingOccurrences(of: "$", with: "\\$")
            regexPattern = regexPattern.replacingOccurrences(of: "(", with: "\\(")
            regexPattern = regexPattern.replacingOccurrences(of: ")", with: "\\)")
            regexPattern = regexPattern.replacingOccurrences(of: "[", with: "\\[")
            regexPattern = regexPattern.replacingOccurrences(of: "]", with: "\\]")
            regexPattern = regexPattern.replacingOccurrences(of: "{", with: "\\{")
            regexPattern = regexPattern.replacingOccurrences(of: "}", with: "\\}")
            regexPattern = regexPattern.replacingOccurrences(of: "|", with: "\\|")
            regexPattern = regexPattern.replacingOccurrences(of: "**", with: "DOUBLESTAR")
            regexPattern = regexPattern.replacingOccurrences(of: "*", with: "[^/]*")
            regexPattern = regexPattern.replacingOccurrences(of: "DOUBLESTAR", with: ".*")
            regexPattern = regexPattern.replacingOccurrences(of: "?", with: "[^/]")
            
            if !regexPattern.hasPrefix("/") {
                regexPattern = "(^|.*/)\\Q\\E" + regexPattern
            } else {
                regexPattern = "^" + String(regexPattern.dropFirst())
            }
            regexPattern += "(/.*)?$"
            regexPattern = regexPattern.replacingOccurrences(of: "\\Q\\E", with: "")
            
            return try? NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])
        }
    }
    
    init(gitignoreContent: String) {
        patterns = gitignoreContent
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { GitIgnorePattern(line: $0) }
    }
    
    static func loadFromDirectory(_ directoryURL: URL) -> GitIgnoreParser? {
        let gitignoreURL = directoryURL.appendingPathComponent(".gitignore")
        guard let content = try? String(contentsOf: gitignoreURL, encoding: .utf8) else {
            return nil
        }
        return GitIgnoreParser(gitignoreContent: content)
    }
    
    func shouldIgnore(path: String, isDirectory: Bool, relativeTo basePath: String) -> Bool {
        let relativePath = path.hasPrefix(basePath) ? 
            String(path.dropFirst(basePath.count).dropFirst()) : path
        
        if relativePath.isEmpty { return false }
        
        var isIgnored = false
        for pattern in patterns {
            if pattern.isDirectoryOnly && !isDirectory { continue }
            if let regex = pattern.regex {
                let range = NSRange(relativePath.startIndex..<relativePath.endIndex, in: relativePath)
                if regex.firstMatch(in: relativePath, options: [], range: range) != nil {
                    isIgnored = !pattern.isNegation
                }
            }
        }
        return isIgnored
    }
}

// MARK: - FileSystemHelper
struct FileSystemHelper {
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
    
    static func loadDirectorySafe(_ url: URL, ignoreMatcher: SystemIgnoreMatcher? = nil) -> Result<[FileNode], FileSystemError> {
        guard FilePathValidator.isValidDirectoryPath(url.path) else {
            return .failure(.invalidPath(url.path))
        }
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return .failure(.fileNotFound(url.path))
        }
        
        guard isDirectory.boolValue else {
            return .failure(.notADirectory(url.path))
        }
        
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
                if lhs.isDirectory && !rhs.isDirectory { return true }
                else if !lhs.isDirectory && rhs.isDirectory { return false }
                else { return lhs.name.localizedCompare(rhs.name) == .orderedAscending }
            }
            
            return .success(nodes)
            
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    private static func createFileNodeSafe(from url: URL, gitignoreParser: GitIgnoreParser?, basePath: String, ignoreMatcher: SystemIgnoreMatcher? = nil) -> FileNode? {
        guard FilePathValidator.isValidPath(url.path) else { return nil }
        return createFileNode(from: url, gitignoreParser: gitignoreParser, basePath: basePath, ignoreMatcher: ignoreMatcher)
    }

    private static func createFileNode(from url: URL, gitignoreParser: GitIgnoreParser?, basePath: String, ignoreMatcher: SystemIgnoreMatcher? = nil) -> FileNode? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            let isDirectory = resourceValues.isDirectory ?? false
            let isRegularFile = resourceValues.isRegularFile ?? false
            
            guard isDirectory || isRegularFile else { return nil }
            
            let name = url.lastPathComponent
            let isGitIgnored = gitignoreParser?.shouldIgnore(path: url.path, isDirectory: isDirectory, relativeTo: basePath) ?? false
            let isSystemIgnored = ignoreMatcher?.shouldIgnore(path: url.path, isDirectory: isDirectory) ?? false

            if isSystemIgnored { return nil }

            if shouldSkipFile(name: name, isDirectory: isDirectory) { return nil }
            
            var children: [FileNode] = []
            if isDirectory && !isGitIgnored {
                children = loadDirectorySync(url, ignoreMatcher: ignoreMatcher)
            }
            
            let ignoreReason: FileNode.IgnoreReason?
            if isGitIgnored { ignoreReason = .gitignore }
            else { ignoreReason = nil }

            return FileNode(
                name: name,
                path: url.path,
                isDirectory: isDirectory,
                children: children,
                isExpanded: false,
                ignoreReason: ignoreReason
            )
        } catch {
            print("Error reading file attributes for \(url.path): \(error)")
            return nil
        }
    }
    
    private static func shouldSkipFile(name: String, isDirectory: Bool) -> Bool {
        if isDirectory { return false }
        let skipExtensions = [".exe", ".dll", ".so", ".dylib", ".a", ".o", ".obj", ".bin", ".class", ".jar"]
        let fileExtension = "." + (name.split(separator: ".").last?.lowercased() ?? "")
        if skipExtensions.contains(fileExtension) { return true }
        return false
    }
}

// MARK: - Main Benchmark
func runBenchmark() {
    let currentDir = FileManager.default.currentDirectoryPath
    let benchmarkDir = URL(fileURLWithPath: currentDir).appendingPathComponent("benchmark_data")
    
    print("Starting benchmark on \(benchmarkDir.path)...")
    
    let defaultPatterns = [
        ".DS_Store", "Thumbs.db", "*.log", "*.tmp", "*.temp",
        ".git/", ".svn/", ".hg/", "node_modules/", ".vscode/", ".idea/",
        "*.xcworkspace/", "*.xcodeproj/", "build/", "dist/", "target/",
        "*.class", "*.jar", "*.war", "*.exe", "*.dll", "*.so", "*.dylib"
    ]
    let matcher = SystemIgnoreMatcher(patterns: defaultPatterns)
    
    let startTime = CFAbsoluteTimeGetCurrent()
    let nodes = FileSystemHelper.loadDirectorySync(benchmarkDir, ignoreMatcher: matcher)
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    
    print("Loaded \(nodes.count) top-level nodes.")
    print("Time elapsed: \(String(format: "%.4f", timeElapsed)) s")
    
    // Count total nodes
    func countNodes(_ nodes: [FileNode]) -> Int {
        var count = nodes.count
        for node in nodes {
            count += countNodes(node.children)
        }
        return count
    }
    
    let totalNodes = countNodes(nodes)
    print("Total nodes loaded: \(totalNodes)")
}

runBenchmark()
