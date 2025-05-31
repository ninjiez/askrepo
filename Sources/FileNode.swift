import Foundation

struct FileNode {
    let name: String
    let path: String
    let isDirectory: Bool
    let children: [FileNode]
    let isExpanded: Bool
    let isIgnored: Bool
    
    init(name: String, path: String, isDirectory: Bool, children: [FileNode] = [], isExpanded: Bool = false, isIgnored: Bool = false) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.children = children
        self.isExpanded = isExpanded
        self.isIgnored = isIgnored
    }
} 