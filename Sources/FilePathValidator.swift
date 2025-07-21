import Foundation

/// Utility for validating file paths to prevent security vulnerabilities
struct FilePathValidator {
    
    /// Validates that a file path is safe to access
    /// - Parameter path: The file path to validate
    /// - Returns: True if the path is safe, false otherwise
    static func isValidPath(_ path: String) -> Bool {
        // Check for empty path
        guard !path.isEmpty else { return false }
        
        // Check for directory traversal attempts
        guard !path.contains("..") else { return false }
        
        // Check for null bytes (can be used for path injection)
        guard !path.contains("\0") else { return false }
        
        // Ensure path doesn't contain control characters
        guard path.rangeOfCharacter(from: CharacterSet.controlCharacters) == nil else { return false }
        
        // Check if path exists and is accessible
        guard FileManager.default.fileExists(atPath: path) else { return false }
        
        return true
    }
    
    /// Validates that a directory path is safe to access
    /// - Parameter path: The directory path to validate
    /// - Returns: True if the directory path is safe, false otherwise
    static func isValidDirectoryPath(_ path: String) -> Bool {
        guard isValidPath(path) else { return false }
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
        
        return isDirectory.boolValue
    }
    
    /// Sanitizes a file path by removing potentially dangerous components
    /// - Parameter path: The file path to sanitize
    /// - Returns: A sanitized version of the path
    static func sanitizePath(_ path: String) -> String {
        // Remove null bytes and control characters
        let sanitized = path
            .replacingOccurrences(of: "\0", with: "")
            .components(separatedBy: CharacterSet.controlCharacters)
            .joined()
        
        // Resolve any symbolic links or relative path components
        return (sanitized as NSString).standardizingPath
    }
    
    /// Checks if a file path is within allowed directories
    /// - Parameters:
    ///   - filePath: The file path to check
    ///   - allowedPaths: Array of allowed base paths
    /// - Returns: True if the file is within an allowed directory
    static func isPathWithinAllowedDirectories(_ filePath: String, allowedPaths: [String]) -> Bool {
        let sanitizedFilePath = sanitizePath(filePath)
        
        for allowedPath in allowedPaths {
            let sanitizedAllowedPath = sanitizePath(allowedPath)
            if sanitizedFilePath.hasPrefix(sanitizedAllowedPath) {
                return true
            }
        }
        
        return false
    }
}