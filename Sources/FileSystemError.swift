import Foundation

/// Errors that can occur during file system operations
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
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        case .accessDenied(let path):
            return "Access denied to: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .notADirectory(let path):
            return "Path is not a directory: \(path)"
        case .unreadableFile(let path):
            return "Cannot read file: \(path)"
        case .encodingFailure(let path):
            return "Text encoding failed for: \(path)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidPath:
            return "Please check that the path is valid and does not contain illegal characters."
        case .accessDenied:
            return "Please check file permissions or select a different location."
        case .fileNotFound:
            return "The file may have been moved or deleted. Please refresh and try again."
        case .notADirectory:
            return "Please select a directory instead of a file."
        case .unreadableFile:
            return "The file may be corrupted or in a binary format."
        case .encodingFailure:
            return "The file contains characters that cannot be displayed as text."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}