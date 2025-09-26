import Foundation

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
