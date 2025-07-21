# Changelog

All notable changes to AskRepo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2025-07-21

### Added
- MVVM architecture implementation for better separation of concerns
- Comprehensive security enhancements including input validation and secure file operations
- Async file operations to prevent UI blocking during large directory scans
- Modular component structure with dedicated panels and views
- File icon provider for better visual file type identification
- Array extensions for improved collection handling
- Dedicated error handling system with FileSystemError
- File path validation utilities
- Header view component for improved UI organization
- Instructions panel (renamed from InstructionsView) with enhanced functionality
- Developer documentation (CLAUDE.md) for AI assistant integration
- Implementation tasks documentation (tasks.md)

### Changed
- Complete refactoring from monolithic ContentView to modular architecture
- Migrated file explorer to dedicated FileExplorerPanel and FileExplorerView components
- Enhanced FileRowView with improved selection handling and visual feedback
- Improved FileSystemHelper with async operations and better error handling
- Updated TokenCounter with more accurate counting and better performance
- Enhanced Settings with improved persistence and type safety
- Updated build scripts with better error handling and optimizations
- Improved DMG creation process with enhanced visual customization

### Fixed
- Security vulnerabilities in file handling operations
- UI blocking issues during large directory operations
- Memory leaks in file tree traversal
- Token counting accuracy issues
- File selection state management bugs

### Security
- Added comprehensive input validation for all file operations
- Implemented secure file reading with proper error boundaries
- Enhanced path traversal protection
- Added validation for file size limits
- Improved error message sanitization

## [0.8.0] - 2025-05-31

### Added
- Context length filtering functionality
- Full button clickable areas for better UX
- Initial release with core functionality
- File tree explorer with .gitignore support
- Token counting for AI context estimation
- Custom prompt templates
- Output generation with markdown formatting
- macOS native app with SwiftUI interface