# Task List

This file tracks the progress of implementing the suggested improvements.

### High Priority / Core Functionality
- [x] **[Feature] More Accurate Token Counting:** The current `TokenCounter` is a rough approximation.
    - [x] To provide users with accurate cost estimates, you should investigate and integrate a proper BPE (Byte Pair Encoding) tokenizer library for Swift that matches the tokenization used by models like GPT-4 or Claude.
    - [ ] **Note:** The `Tiktoken` library is currently pinned to the `main` branch because there are no tagged versions. This should be revisited later to use a stable version.
- [x] **[Performance] Asynchronous File Loading:** The file system is scanned on the main thread, which can freeze the UI when adding large directories.
    - [x] Refactor `FileSystemHelper.loadDirectory` to run on a background thread.
    - [x] Update the UI asynchronously as files and folders are discovered. Consider showing a loading indicator in the file explorer while scanning.

### Refactoring & Code Quality
- [ ] **[Refactor] Decompose `ContentView`:** This view is very large and handles too many responsibilities (UI, state, business logic).
    - [x] Create a `ContentViewViewModel` to move logic like token counting, output generation, and file management out of the view.
    - [ ] Break down the UI into smaller, more focused subviews (e.g., `FileExplorerView`, `InstructionsView`, `HeaderView`).
- [ ] **[Refactor] Centralize Design System:** The `ModernDesign` struct is defined in `ContentView` and partially repeated in other files.
    - [ ] Move `ModernDesign` and related style enums to a separate file to create a single source of truth for styling.
- [ ] **[Refactor] Use Dependency Injection:** Static helpers like `FileSystemHelper` can make testing and mocking difficult.
    - [ ] Consider converting `FileSystemHelper` into a class/service that can be instantiated and injected where needed.

### Robustness & User Experience
- [ ] **[UX] Improve Error Handling:** `print("Error...")` statements are not user-friendly.
    - [ ] Implement a system to display user-facing alerts for errors, such as failing to read a directory or save a file.
- [ ] **[Robustness] Improve Ignore Pattern Matching:** The custom `.gitignore` and system ignore matching logic might not cover all edge cases.
    - [ ] Research and test the implementation with a wider variety of complex `gitignore` rules to ensure it's robust.
- [ ] **[UX] Add App Icon to Build Target:** The code tries to load `AppIcon.icns` manually.
    - [ ] You should add the app icon to the project's asset catalog (`Assets.xcassets`) so it's automatically included in the app bundle. This will make the manual loading code in `ContentView` unnecessary.
- [ ] **[UX] Dynamic App Version:** The app version is currently hardcoded.
    - [ ] Read the app version and build number from the project's `Info.plist` to display in the UI, ensuring it's always in sync with the build.

### Minor Improvements & Features
- [ ] **[Feature] Remember Expanded Folders:** The expanded/collapsed state of folders is not saved across sessions.
    - [ ] Persist the expanded state of directories to improve user experience on relaunch.
- [ ] **[Feature] "Select All" / "Deselect All" buttons:** Add buttons for quick selection changes, either globally or within a specific directory.
- [ ] **[Code] Clean up Window Configuration:** The window setup in `AskRepoApp.swift` is done in an `.onAppear` block. This could be encapsulated in a custom `Window` style or a helper for better organization.
