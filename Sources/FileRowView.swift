import SwiftUI

struct FileRowView: View {
    let node: FileNode
    @Binding var selectedFiles: Set<String>
    let level: Int
    let isTopLevel: Bool
    let onRemoveDirectory: (() -> Void)?
    let onGitIgnoreSelect: ((String) -> Void)?
    @State private var isExpanded: Bool = false
    @State private var isHovered: Bool = false
    
    // Modern Design System - matching ContentView
    private struct ModernDesign {
        static let spacing1: CGFloat = 6
        static let spacing2: CGFloat = 12
        static let spacing3: CGFloat = 18
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        
        static let backgroundTertiary = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let backgroundGlass = Color.white.opacity(0.8)
        static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
        static let textSecondary = Color(red: 0.47, green: 0.47, blue: 0.49)
        static let textTertiary = Color(red: 0.68, green: 0.68, blue: 0.70)
        static let accentPrimary = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentSuccess = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let borderLight = Color(red: 0.90, green: 0.90, blue: 0.92)
    }
    
    private let indentWidth: CGFloat = 16
    
    // Convenience initializer for non-top-level items
    init(node: FileNode, selectedFiles: Binding<Set<String>>, level: Int, onGitIgnoreSelect: ((String) -> Void)?) {
        self.node = node
        self._selectedFiles = selectedFiles
        self.level = level
        self.isTopLevel = false
        self.onRemoveDirectory = nil
        self.onGitIgnoreSelect = onGitIgnoreSelect
    }
    
    // Full initializer for top-level items
    init(node: FileNode, selectedFiles: Binding<Set<String>>, level: Int, isTopLevel: Bool, onRemoveDirectory: (() -> Void)?, onGitIgnoreSelect: ((String) -> Void)?) {
        self.node = node
        self._selectedFiles = selectedFiles
        self.level = level
        self.isTopLevel = isTopLevel
        self.onRemoveDirectory = onRemoveDirectory
        self.onGitIgnoreSelect = onGitIgnoreSelect
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing1) {
            mainRowView
            
            // Children (if directory is expanded)
            if node.isDirectory && isExpanded {
                ForEach(node.children, id: \.path) { child in
                    FileRowView(
                        node: child,
                        selectedFiles: $selectedFiles,
                        level: level + 1,
                        onGitIgnoreSelect: onGitIgnoreSelect
                    )
                }
            }
        }
        .onAppear {
            // Auto-expand the root directory
            if level == 0 {
                isExpanded = true
            }
        }
    }
    
    private var mainRowView: some View {
        HStack(spacing: ModernDesign.spacing2) {
            indentationView
            expandButtonView
            checkboxView
            iconView
            nameView
            Spacer(minLength: 0)
            selectionIndicatorView
            topLevelCloseButton
        }
        .padding(.horizontal, ModernDesign.spacing2)
        .padding(.vertical, ModernDesign.spacing1)
        .background(backgroundView)
        .overlay(overlayView)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if node.isDirectory {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } else {
                // Toggle file selection
                if selectedFiles.contains(node.path) {
                    selectedFiles.remove(node.path)
                } else {
                    selectedFiles.insert(node.path)
                }
            }
        }
    }
    
    @ViewBuilder
    private var topLevelCloseButton: some View {
        if isTopLevel && node.isDirectory {
            Button(action: {
                onRemoveDirectory?()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ModernDesign.textTertiary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.7)
        }
    }
    
    @ViewBuilder
    private var indentationView: some View {
        if level > 0 {
            Rectangle()
                .fill(Color.clear)
                .frame(width: CGFloat(level) * indentWidth)
        }
    }
    
    @ViewBuilder
    private var expandButtonView: some View {
        if node.isDirectory {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ModernDesign.textSecondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Rectangle()
                .fill(Color.clear)
                .frame(width: 12, height: 12)
        }
    }
    
    private var checkboxView: some View {
        Toggle("", isOn: Binding(
            get: { 
                if node.isDirectory {
                    return isDirectoryFullySelected()
                } else {
                    return selectedFiles.contains(node.path)
                }
            },
            set: { isSelected in
                // Check if this is an ignored file and user is trying to select it
                if isSelected && node.isIgnored && !node.isDirectory {
                    onGitIgnoreSelect?(node.path)
                    return
                }
                
                if node.isDirectory {
                    toggleDirectorySelection(isSelected)
                } else {
                    if isSelected {
                        selectedFiles.insert(node.path)
                    } else {
                        selectedFiles.remove(node.path)
                    }
                }
            }
        ))
        .toggleStyle(.checkbox)
        .scaleEffect(0.8)
    }
    
    private var iconView: some View {
        Image(systemName: node.isDirectory ? 
            (isExpanded ? "folder.fill" : "folder") : 
            getFileIcon()
        )
        .font(.system(size: isTopLevel ? 13 : 12, weight: .medium))
        .foregroundColor(node.isDirectory ? ModernDesign.accentPrimary : getFileIconColor())
        .frame(width: 16, alignment: .center)
    }
    
    private var nameView: some View {
        Text(node.name)
            .font(.system(size: isTopLevel ? 13 : 12, weight: isTopLevel ? .semibold : .medium))
            .lineLimit(1)
            .foregroundColor(ModernDesign.textPrimary)
    }
    
    @ViewBuilder
    private var selectionIndicatorView: some View {
        if node.isIgnored && !node.isDirectory {
            // Show "no entry" icon for ignored files
            Image(systemName: "nosign")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ModernDesign.textTertiary)
        } else if selectedFiles.contains(node.path) && !node.isDirectory {
            // Show green checkmark for selected files
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ModernDesign.accentSuccess)
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isHovered {
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .fill(ModernDesign.backgroundTertiary.opacity(0.6))
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        // No overlay for selection - only checkboxes indicate selection
        Color.clear
    }
    
    private func getFileIcon() -> String {
        return FileIconProvider.icon(for: node.path)
    }
    
    private func getFileIconColor() -> Color {
        return FileIconProvider.color(for: node.path)
    }
    
    private func isDirectoryFullySelected() -> Bool {
        // Check if all files in this directory (recursively) are selected
        let allFilePaths = getAllFilePaths(from: node)
        return !allFilePaths.isEmpty && allFilePaths.allSatisfy { selectedFiles.contains($0) }
    }
    
    private func toggleDirectorySelection(_ isSelected: Bool) {
        let allFilePaths = getAllFilePaths(from: node)
        
        if isSelected {
            // Add all files in this directory
            for filePath in allFilePaths {
                selectedFiles.insert(filePath)
            }
        } else {
            // Remove all files in this directory
            for filePath in allFilePaths {
                selectedFiles.remove(filePath)
            }
        }
    }
    
    private func getAllFilePaths(from node: FileNode) -> [String] {
        var filePaths: [String] = []
        
        if !node.isDirectory {
            filePaths.append(node.path)
        } else {
            for child in node.children {
                filePaths.append(contentsOf: getAllFilePaths(from: child))
            }
        }
        
        return filePaths
    }
} 