# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AskRepo is a native macOS application built with Swift and SwiftUI that helps developers prepare their codebase for AI assistants. It allows users to select files from their projects, respects .gitignore patterns, counts tokens, and generates formatted output with custom prompts.

## Development Commands

### Build Commands
```bash
# Clean and build release version
./build.sh

# Build development version
swift build

# Run the app in development
swift run

# Create distributable DMG
./build-dmg.sh

# Open in Xcode
open Package.swift
```

### Clean Build
```bash
swift package clean
rm -rf .build build Package.resolved .swiftpm
```

## Architecture & Key Components

The app follows a standard SwiftUI architecture with these core responsibilities:

- **AskRepoApp.swift**: Main app entry point, configures window size and title
- **ContentView.swift**: Primary UI containing file tree, token counter, and prompt input
- **FileNode.swift**: Tree data structure representing the file system hierarchy
- **FileSystemHelper.swift**: Handles directory scanning and file reading operations
- **GitIgnoreParser.swift**: Implements .gitignore pattern matching logic
- **TokenCounter.swift**: Calculates token counts for AI context estimation
- **Settings.swift**: Manages persistent user preferences using @AppStorage

## Important Development Notes

1. **Platform**: This is a macOS-only application targeting macOS 13.0+
2. **Dependencies**: Zero external dependencies - uses only Apple frameworks
3. **Build System**: Swift Package Manager with resources bundled from Resources/
4. **UI Framework**: SwiftUI with AppKit integration where needed
5. **Version**: Currently at v0.8, actively developed on `dev` branch

## Key Implementation Details

- The app uses SwiftUI's `FileDocument` or similar patterns for file handling
- Token counting is implemented to match OpenAI's tokenization (approximate)
- GitIgnore parsing supports standard glob patterns
- File selection state is maintained in a tree structure with parent-child relationships
- The output format combines user prompts with selected file contents in markdown

## Testing & Quality

Currently, there are no automated tests. When implementing new features:
- Test .gitignore pattern matching thoroughly
- Verify token counting accuracy
- Ensure file tree selection logic handles edge cases
- Test with large repositories for performance

## Distribution

The app is distributed as a DMG file with a drag-to-install interface. The build scripts handle:
- Creating the .app bundle with proper Info.plist
- Including the app icon (Resources/AppIcon.icns)
- Building a customized DMG with installation instructions