import Foundation

let path = FileManager.default.currentDirectoryPath + "/LargeTestRepo"
let url = URL(fileURLWithPath: path)
print("Scanning directory: \(url.path)")

let start = Date()
let result = await FileSystemHelper.loadDirectoryParallel(url, settings: nil)
let nodes = (try? result.get()) ?? []
let duration = Date().timeIntervalSince(start)

print("Scanned in \(String(format: "%.4f", duration)) seconds")

func countFiles(_ nodes: [FileNode]) -> Int {
    var count = 0
    for node in nodes {
        if node.isDirectory {
            count += countFiles(node.children)
        } else {
            count += 1
        }
    }
    return count
}

print("Total files found: \(countFiles(nodes))")
