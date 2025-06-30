import SwiftUI

/// Provides consistent file icons and colors throughout the application
struct FileIconProvider {
    
    /// Returns the appropriate SF Symbol icon for a file extension
    /// - Parameter filePath: The file path or name
    /// - Returns: SF Symbol name for the file type
    static func icon(for filePath: String) -> String {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent.lowercased()
        let fileExtension = (fileName as NSString).pathExtension
        
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
    
    /// Returns the appropriate color for a file extension
    /// - Parameter filePath: The file path or name
    /// - Returns: Color for the file type
    static func color(for filePath: String) -> Color {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent.lowercased()
        let fileExtension = (fileName as NSString).pathExtension
        
        switch fileExtension {
        case "swift":
            return .orange
        case "js", "jsx":
            return Color(red: 0.8, green: 0.6, blue: 0.0) // Dark yellow
        case "ts", "tsx":
            return .blue
        case "html", "htm":
            return .orange
        case "css", "scss", "less":
            return .blue
        case "md", "markdown":
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Dark gray
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
            return Color(red: 0.3, green: 0.3, blue: 0.3) // Dark gray
        }
    }
    
    /// Returns both icon and color for a file type
    /// - Parameter filePath: The file path or name
    /// - Returns: Tuple containing icon name and color
    static func iconAndColor(for filePath: String) -> (icon: String, color: Color) {
        return (icon: icon(for: filePath), color: color(for: filePath))
    }
}