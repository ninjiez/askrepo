
import SwiftUI

struct InstructionsView: View {
    @ObservedObject var viewModel: ContentViewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack(spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.34, green: 0.34, blue: 0.84))
                    
                    Text("AI Instructions")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    modernPromptsDropdown
                    modernSaveButton
                    modernCopyButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            
            Divider()
                .background(Color(red: 0.90, green: 0.90, blue: 0.92))
            
            // Instructions content
            VStack(spacing: 24) {
                modernPromptSection
                modernSelectedFilesSection
            }
            .padding(24)
        }
        .frame(minWidth: 450, idealWidth: 550)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.99, green: 0.99, blue: 1.0))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 1)
        )
    }

    private var modernCopyButton: some View {
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
            HStack(spacing: 6) {
                Image(systemName: viewModel.copyFeedbackShown ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text(viewModel.copyFeedbackShown ? "Copied!" : "Copy")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Capsule()
                    .fill(
                        viewModel.copyFeedbackShown
                        ? Color(red: 0.20, green: 0.78, blue: 0.35)
                        : (viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty
                            ? Color(red: 0.68, green: 0.68, blue: 0.70)
                            : Color(red: 0.0, green: 0.48, blue: 1.0))
                    )
            )
        }
        .disabled(viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.copyFeedbackShown)
    }
    
    private var modernPromptsDropdown: some View {
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
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Prompts")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }
    
    private var modernSaveButton: some View {
        Button {
            viewModel.saveToFile()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.saveFeedbackShown ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    .font(.system(size: 10, weight: .semibold))
                
                Text(viewModel.saveFeedbackShown ? "Saved!" : "Save")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Capsule()
                    .fill(
                        viewModel.saveFeedbackShown
                        ? Color(red: 0.20, green: 0.78, blue: 0.35)
                        : (viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty
                            ? Color(red: 0.68, green: 0.68, blue: 0.70)
                            : Color(red: 0.0, green: 0.48, blue: 1.0))
                    )
            )
        }
        .disabled(viewModel.selectedFiles.isEmpty && viewModel.promptText.isEmpty)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.saveFeedbackShown)
    }

    private var modernPromptSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label {
                    Text("Prompt")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                } icon: {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.34, green: 0.34, blue: 0.84))
                }
                
                Spacer()
                
                Text("\(viewModel.promptTokenCount) tokens")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                    )
                    .monospacedDigit()
            }
            
            ZStack {
                // Background and border
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                //isPromptFocused
                                false
                                ? Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.8)
                                : Color(red: 0.90, green: 0.90, blue: 0.92),
                                lineWidth: //isPromptFocused
                                false ? 2 : 1
                            )
                    )
                
                // TextEditor
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.promptText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .scrollContentBackground(.hidden)
                        //.focused($isPromptFocused)
                        .padding(.top, 6)
                        .onTapGesture {
                            //isPromptFocused = true
                        }
                    
                    if viewModel.promptText.isEmpty //&& !isPromptFocused 
                    {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Describe what you want the AI to do with your selected files...")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .allowsHitTesting(false)
                        .padding(18)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(minHeight: 120, maxHeight: 180)
        }
    }
    
    private var modernSelectedFilesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label {
                    Text("Selected Files")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                } icon: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.20, green: 0.78, blue: 0.35))
                }
                
                Spacer()
                
                if !viewModel.selectedFiles.isEmpty {
                    HStack(spacing: 6) {
                        // Search field
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                            
                            TextField("Search...", text: $viewModel.searchText)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                                .textFieldStyle(.plain)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 0.5)
                        )
                        
                        // Sort picker
                        Menu {
                            ForEach(InstructionsPanel.FileSortOption.allCases, id: \.self) { option in
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
                                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                                Text(viewModel.sortOption.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 0.5)
                            )
                        }
                        .menuStyle(.button)
                        .fixedSize()
                        
                        modernMetricBadge(
                            value: "\(viewModel.selectedFiles.count)",
                            label: "files",
                            color: Color(red: 0.20, green: 0.78, blue: 0.35)
                        )
                        
                        modernMetricBadge(
                            value: "\(viewModel.formatTokenCount(viewModel.totalTokenCount - viewModel.promptTokenCount))",
                            label: "tokens",
                            color: Color(red: 1.0, green: 0.58, blue: 0.0)
                        )
                    }
                } else {
                    HStack(spacing: 12) {
                        modernMetricBadge(
                            value: "\(viewModel.selectedFiles.count)",
                            label: "files",
                            color: Color(red: 0.20, green: 0.78, blue: 0.35)
                        )
                        
                        modernMetricBadge(
                            value: "\(viewModel.formatTokenCount(viewModel.totalTokenCount - viewModel.promptTokenCount))",
                            label: "tokens",
                            color: Color(red: 1.0, green: 0.58, blue: 0.0)
                        )
                    }
                }
            }
            
            if !viewModel.selectedFiles.isEmpty {
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.selectedFiles.sorted(), id: \.self) { filePath in
                            modernFileChip(filePath: filePath)
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 1)
                )
            } else {
                modernEmptyFilesState
            }
        }
    }
    
    private func modernMetricBadge(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
    
    private var modernEmptyFilesState: some View {
        VStack(spacing: 18) {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                
                VStack(spacing: 4) {
                    Text("No Files Selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.47, green: 0.47, blue: 0.49))
                    
                    Text("Choose files from the explorer to include in your AI prompt")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.96, green: 0.97, blue: 0.98).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 1)
                .opacity(0.5)
        )
    }
    
    private func modernFileChip(filePath: String) -> some View {
        let fileTokens = viewModel.getFileTokenCount(for: filePath)
        
        return HStack(spacing: 12) {
            Image(systemName: viewModel.getFileIconForPath(filePath))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(viewModel.getFileIconColorForPath(filePath))
                .frame(width: 14)
            
            Text(viewModel.getRelativePath(for: filePath))
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
            
            Spacer(minLength: 0)
            
            // Token count badge
            Text("\(viewModel.formatTokenCount(fileTokens))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                )
                .monospacedDigit()
            
            Button {
                viewModel.selectedFiles.remove(filePath)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 0.5)
        )
    }
}
