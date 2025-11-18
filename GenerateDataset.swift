import Foundation

let fileManager = FileManager.default
let rootPath = fileManager.currentDirectoryPath + "/LargeTestRepo"

if fileManager.fileExists(atPath: rootPath) {
    try fileManager.removeItem(atPath: rootPath)
}
try fileManager.createDirectory(atPath: rootPath, withIntermediateDirectories: true)

let depth = 5
let width = 5
let filesPerDir = 5

func createStructure(at path: String, currentDepth: Int) {
    if currentDepth >= depth { return }
    
    for i in 0..<width {
        let subDir = path + "/dir_\(i)"
        try? fileManager.createDirectory(atPath: subDir, withIntermediateDirectories: true)
        
        for j in 0..<filesPerDir {
            let file = subDir + "/file_\(j).swift"
            let content = "// Some swift code\nfunc foo() { print(\"bar\") }"
            fileManager.createFile(atPath: file, contents: content.data(using: .utf8))
        }
        
        createStructure(at: subDir, currentDepth: currentDepth + 1)
    }
}

print("Generating large dataset at \(rootPath)...")
createStructure(at: rootPath, currentDepth: 0)
print("Done.")
