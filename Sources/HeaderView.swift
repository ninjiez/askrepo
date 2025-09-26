
import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: ContentViewViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 24) {
            // App branding
            HStack(spacing: 12) {
                if let appIconImage = NSImage(named: "AppIcon") ?? loadAppIcon() {
                    Image(nsImage: appIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Fallback to the original gradient design
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [ColorScheme.Dynamic.accentPrimary(colorScheme), ColorScheme.Dynamic.accentSecondary(colorScheme)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                            .frame(width: 48, height: 48)
                    
                    Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AskRepo")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                    
                    Text("AI Code Assistant")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ColorScheme.Dynamic.textSecondary(colorScheme))
                }
            }
            
            Spacer()
            
            // Quick stats
            HStack(spacing: 18) {
                modernStatCard(
                    icon: "folder.fill",
                    value: "\(viewModel.selectedDirectories.count)",
                    label: "Folders",
                    color: ColorScheme.Dynamic.accentPrimary(colorScheme)
                )
                
                modernStatCard(
                    icon: "doc.text.fill",
                    value: "\(viewModel.selectedFiles.count)",
                    label: "Files",
                    color: ColorScheme.Dynamic.accentSuccess
                )
                
                modernStatCard(
                    icon: "textformat.abc",
                    value: "\(viewModel.formatTokenCount(viewModel.totalTokenCount))",
                    label: "Tokens",
                    color: ColorScheme.Dynamic.accentWarning
                )
                
                // Settings button
                Button {
                    viewModel.showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorScheme.Dynamic.accentPrimary(colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(ColorScheme.Dynamic.accentPrimary(colorScheme).opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(
            ColorScheme.Dynamic.backgroundGlass(colorScheme)
                .background(.ultraThinMaterial)
        )
    }

    private func modernStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(ColorScheme.Dynamic.textPrimary(colorScheme))
                    .monospacedDigit()
                
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(ColorScheme.Dynamic.textTertiary(colorScheme))
                    .textCase(.uppercase)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
    }

    private func loadAppIcon() -> NSImage? {
        // Try to load from bundle resources
        if let resourcePath = Bundle.main.path(forResource: "AppIcon", ofType: "icns", inDirectory: "Resources") {
            return NSImage(contentsOfFile: resourcePath)
        }
        
        // Try alternative paths
        if let resourcePath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            return NSImage(contentsOfFile: resourcePath)
        }
        
        // Try loading from Resources directory relative to bundle
        if let bundlePath = Bundle.main.resourcePath {
            let iconPath = "\(bundlePath)/Resources/AppIcon.icns"
            if FileManager.default.fileExists(atPath: iconPath) {
                return NSImage(contentsOfFile: iconPath)
            }
        }
        
        return nil
    }
}
