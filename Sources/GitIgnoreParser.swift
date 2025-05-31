import Foundation

struct GitIgnoreParser {
    private let patterns: [GitIgnorePattern]
    
    struct GitIgnorePattern {
        let pattern: String
        let isNegation: Bool
        let isDirectoryOnly: Bool
        let regex: NSRegularExpression?
        
        init(line: String) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for negation
            if trimmed.hasPrefix("!") {
                isNegation = true
                pattern = String(trimmed.dropFirst())
            } else {
                isNegation = false
                pattern = trimmed
            }
            
            // Check if it's directory-only
            isDirectoryOnly = pattern.hasSuffix("/")
            
            // Convert gitignore pattern to regex
            let cleanPattern = isDirectoryOnly ? String(pattern.dropLast()) : pattern
            regex = Self.createRegex(from: cleanPattern)
        }
        
        private static func createRegex(from pattern: String) -> NSRegularExpression? {
            var regexPattern = pattern
            
            // Escape special regex characters except * and ?
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
            
            // Handle gitignore wildcards
            regexPattern = regexPattern.replacingOccurrences(of: "**", with: "DOUBLESTAR")
            regexPattern = regexPattern.replacingOccurrences(of: "*", with: "[^/]*")
            regexPattern = regexPattern.replacingOccurrences(of: "DOUBLESTAR", with: ".*")
            regexPattern = regexPattern.replacingOccurrences(of: "?", with: "[^/]")
            
            // Add anchors
            if !regexPattern.hasPrefix("/") {
                regexPattern = "(^|.*/)\\Q\\E" + regexPattern
            } else {
                regexPattern = "^" + String(regexPattern.dropFirst())
            }
            regexPattern += "(/.*)?$"
            
            // Clean up the regex
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
        
        if relativePath.isEmpty {
            return false
        }
        
        var isIgnored = false
        
        for pattern in patterns {
            // Skip directory-only patterns for files
            if pattern.isDirectoryOnly && !isDirectory {
                continue
            }
            
            if let regex = pattern.regex {
                let range = NSRange(relativePath.startIndex..<relativePath.endIndex, in: relativePath)
                let matches = regex.firstMatch(in: relativePath, options: [], range: range) != nil
                
                if matches {
                    isIgnored = !pattern.isNegation
                }
            }
        }
        
        return isIgnored
    }
} 