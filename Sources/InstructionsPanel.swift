import SwiftUI

struct InstructionsPanel: View {
    @ObservedObject var viewModel: ContentViewViewModel
    
    enum FileSortOption: String, CaseIterable {
        case hierarchical = "Structure"
        case tokens = "Tokens"
        
        var icon: String {
            switch self {
            case .hierarchical: return "folder.fill"
            case .tokens: return "number"
            }
        }
    }
    
    // Modern Design System - matching ContentView
    private struct ModernDesign {
        static let spacing1: CGFloat = 6
        static let spacing2: CGFloat = 12
        static let spacing3: CGFloat = 18
        static let spacing4: CGFloat = 24
        
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        static let radiusLarge: CGFloat = 16
        
        static let backgroundSecondary = Color.white
        static let backgroundTertiary = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let surfaceCard = Color(red: 0.99, green: 0.99, blue: 1.0)
        
        static let accentPrimary = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentSecondary = Color(red: 0.34, green: 0.34, blue: 0.84)
        static let accentSuccess = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let accentWarning = Color(red: 1.0, green: 0.58, blue: 0.0)
        
        static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
        static let textSecondary = Color(red: 0.47, green: 0.47, blue: 0.49)
        static let textTertiary = Color(red: 0.68, green: 0.68, blue: 0.70)
        
        static let borderLight = Color(red: 0.90, green: 0.90, blue: 0.92)
        static let shadowCard = Color.black.opacity(0.05)
    }
    
    // MARK: - Computed Properties
    private var filteredAndSortedFiles: [String] {
        let filtered = viewModel.searchText.isEmpty
            ? Array(viewModel.selectedFiles)
            : Array(viewModel.selectedFiles).filter { filePath in
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                let relativePath = viewModel.getRelativePath(for: filePath)
                return fileName.localizedCaseInsensitiveContains(viewModel.searchText) ||
                       relativePath.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        
        switch viewModel.sortOption {
        case .hierarchical:
            return filtered.sorted { (path1, path2) in
                // Sort hierarchically: by directory structure first, then by filename
                let components1 = path1.components(separatedBy: "/")
                let components2 = path2.components(separatedBy: "/")
                
                // Compare directory structure
                let minCount = min(components1.count, components2.count)
                for i in 0..<(minCount - 1) {
                    let comparison = components1[i].localizedCaseInsensitiveCompare(components2[i])
                    if comparison != .orderedSame {
                        return comparison == .orderedAscending
                    }
                }
                
                // If directory structure is the same, compare filenames
                if components1.count != components2.count {
                    return components1.count < components2.count
                }
                
                return components1.last?.localizedCaseInsensitiveCompare(components2.last ?? "") == .orderedAscending
            }
        case .tokens:
            return filtered.sorted { path1, path2 in
                let tokens1 = viewModel.getFileTokenCount(for: path1)
                let tokens2 = viewModel.getFileTokenCount(for: path2)
                return tokens1 > tokens2 // Sort by tokens descending
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            headerSection
            
            Divider()
                .background(ModernDesign.borderLight)
            
            // Instructions content
            VStack(spacing: ModernDesign.spacing4) {
                promptSection
                selectedFilesSection
            }
            .padding(ModernDesign.spacing4)
        }
        .frame(minWidth: 450, idealWidth: 550)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                .fill(ModernDesign.surfaceCard)
                .shadow(color: ModernDesign.shadowCard, radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.radiusLarge)
                .stroke(ModernDesign.borderLight, lineWidth: 1)
        )
    }
    
    private var headerSection: some View {
        HStack(spacing: ModernDesign.spacing3) {
            HStack(spacing: ModernDesign.spacing2) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ModernDesign.accentSecondary)
                
                Text("AI Instructions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ModernDesign.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: ModernDesign.spacing2) {
                promptsDropdown
                saveButton
                copyButton
            }
        }
        .padding(.horizontal, ModernDesign.spacing4)
        .padding(.vertical, ModernDesign.spacing3)
    }
    
    private var promptsDropdown: some View {
        Menu {
            if viewModel.settings.promptTemplates.isEmpty {
                Text("No templates available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.settings.promptTemplates) { template in
                    Button {
                        viewModel.promptText = template.content
                        viewModel.debouncedPromptTokenCount()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.system(size: 13, weight: .semibold))
                            
                            Text(String(template.content.prefix(50)) + (template.content.count > 50 ? "..." : ""))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    viewModel.showingSettings = true
                } label: {
                    Label("Manage Templates", systemImage: "gearshape")
                }
            }
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Prompts")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .background(
                Capsule()
                    .fill(ModernDesign.accentPrimary)
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }
    
    private var saveButton: some View {
        Button {
            viewModel.saveToFile()
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: viewModel.saveFeedbackShown ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text(viewModel.saveFeedbackShown ? "Saved!" : "Save")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Capsule()
                    .fill(
                        viewModel.saveFeedbackShown
                        ? ModernDesign.accentSuccess
                        : (viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty
                            ? ModernDesign.textTertiary
                            : ModernDesign.accentPrimary)
                    )
            )
        }
        .disabled(viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.saveFeedbackShown)
    }
    
    private var copyButton: some View {
        Button {
            viewModel.copyToClipboard()
            // Show copy feedback
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.copyFeedbackShown = true
            }
            
            // Hide feedback after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.copyFeedbackShown = false
                }
            }
        } label: {
            HStack(spacing: ModernDesign.spacing1) {
                Image(systemName: viewModel.copyFeedbackShown ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text(viewModel.copyFeedbackShown ? "Copied!" : "Copy")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesign.spacing2)
            .padding(.vertical, ModernDesign.spacing1)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Capsule()
                    .fill(
                        viewModel.copyFeedbackShown
                        ? ModernDesign.accentSuccess
                        : (viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty
                            ? ModernDesign.textTertiary
                            : ModernDesign.accentPrimary)
                    )
            )
        }
        .disabled(viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.copyFeedbackShown)
    }
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
            HStack {
                Label {
                    Text("Prompt")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ModernDesign.textPrimary)
                } icon: {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ModernDesign.accentSecondary)
                }
                
                Spacer()
                
                Text("\(viewModel.promptTokenCount) tokens")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(ModernDesign.textTertiary)
                    .padding(.horizontal, ModernDesign.spacing1)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(ModernDesign.backgroundTertiary)
                    )
                    .monospacedDigit()
            }
            
            ZStack {
                // Background and border
                RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                    .fill(ModernDesign.backgroundSecondary)
                    .shadow(color: ModernDesign.shadowCard, radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                            .stroke(ModernDesign.borderLight, lineWidth: 1)
                    )
                
                // TextEditor
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.promptText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ModernDesign.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.top, 6)
                    
                    if viewModel.promptText.isEmpty {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Describe what you want the AI to do with your selected files...")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ModernDesign.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .allowsHitTesting(false)
                        .padding(ModernDesign.spacing3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: ModernDesign.radiusMedium))
            }
            .frame(minHeight: 120, maxHeight: 180)
        }
    }
    
    private var selectedFilesSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.spacing3) {
            HStack {
                Label {
                    Text("Selected Files")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ModernDesign.textPrimary)
                } icon: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ModernDesign.accentSuccess)
                }
                
                Spacer()
                
                if !viewModel.selectedFiles.isEmpty {
                    HStack(spacing: ModernDesign.spacing1) {
                        // Search field
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(ModernDesign.textTertiary)
                            
                            TextField("Search...", text: $viewModel.searchText)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(ModernDesign.textPrimary)
                                .textFieldStyle(.plain)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(ModernDesign.backgroundSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ModernDesign.borderLight, lineWidth: 0.5)
                        )
                        
                        // Sort picker
                        Menu {
                            ForEach(FileSortOption.allCases, id: \.self) { option in
                                Button {
                                    viewModel.sortOption = option
                                } label: {
                                    HStack {
                                        Image(systemName: option.icon)
                                        Text(option.rawValue)
                                        if viewModel.sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: viewModel.sortOption.icon)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(ModernDesign.textPrimary)
                                Text(viewModel.sortOption.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(ModernDesign.textPrimary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(ModernDesign.textTertiary)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(ModernDesign.backgroundSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(ModernDesign.borderLight, lineWidth: 0.5)
                            )
                        }
                        .menuStyle(.button)
                        .fixedSize()
                        
                        metricBadge(
                            value: "\(filteredAndSortedFiles.count)",
                            label: "files",
                            color: ModernDesign.accentSuccess
                        )
                        
                        metricBadge(
                            value: "\(formatTokenCount(viewModel.totalTokenCount - viewModel.promptTokenCount))",
                            label: "tokens",
                            color: ModernDesign.accentWarning
                        )
                    }
                } else {
                    HStack(spacing: ModernDesign.spacing2) {
                        metricBadge(
                            value: "\(viewModel.selectedFiles.count)",
                            label: "files",
                            color: ModernDesign.accentSuccess
                        )
                        
                        metricBadge(
                            value: "\(formatTokenCount(viewModel.totalTokenCount - viewModel.promptTokenCount))",
                            label: "tokens",
                            color: ModernDesign.accentWarning
                        )
                    }
                }
            }
            
            if !viewModel.selectedFiles.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ModernDesign.spacing1) {
                        ForEach(filteredAndSortedFiles, id: \.self) { filePath in
                            fileChip(filePath: filePath)
                        }
                    }
                    .padding(ModernDesign.spacing2)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                        .fill(ModernDesign.backgroundSecondary)
                        .shadow(color: ModernDesign.shadowCard, radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                        .stroke(ModernDesign.borderLight, lineWidth: 1)
                )
            } else {
                emptyFilesState
            }
        }
    }
    
    private func metricBadge(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(ModernDesign.textTertiary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, ModernDesign.spacing1)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
    
    private var emptyFilesState: some View {
        VStack(spacing: ModernDesign.spacing3) {
            Spacer()
            
            VStack(spacing: ModernDesign.spacing2) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(ModernDesign.textTertiary)
                
                VStack(spacing: 4) {
                    Text("No Files Selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ModernDesign.textSecondary)
                    
                    Text("Choose files from the explorer to include in your AI prompt")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(ModernDesign.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                .fill(ModernDesign.backgroundTertiary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.radiusMedium)
                .stroke(ModernDesign.borderLight, lineWidth: 1)
                .opacity(0.5)
        )
    }
    
    private func fileChip(filePath: String) -> some View {
        let fileTokens = viewModel.getFileTokenCount(for: filePath)
        
        return HStack(spacing: ModernDesign.spacing2) {
            Image(systemName: FileIconProvider.icon(for: filePath))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(FileIconProvider.color(for: filePath))
                .frame(width: 14)
            
            Text(viewModel.getRelativePath(for: filePath))
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundColor(ModernDesign.textPrimary)
            
            Spacer(minLength: 0)
            
            // Token count badge
            Text("\(formatTokenCount(fileTokens))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(ModernDesign.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(ModernDesign.backgroundTertiary)
                )
                .monospacedDigit()
            
            Button {
                viewModel.selectedFiles.remove(filePath)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(ModernDesign.textTertiary)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ModernDesign.spacing2)
        .padding(.vertical, ModernDesign.spacing1)
        .background(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .fill(ModernDesign.backgroundTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.radiusSmall)
                .stroke(ModernDesign.borderLight, lineWidth: 0.5)
        )
    }
    
    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}