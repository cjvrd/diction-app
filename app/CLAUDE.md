# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

Build via Xcode (Cmd+B) or from the command line (run from `app/`):

```bash
# Build
xcodebuild build -scheme "diction-macos-app" -configuration Debug

# Run unit tests
xcodebuild test -scheme "diction-macos-app" -only-testing:diction-macos-appTests

# Run UI tests
xcodebuild test -scheme "diction-macos-app" -only-testing:diction-macos-appUITests

# Run a single test (replace TestClassName/testMethodName)
xcodebuild test -scheme "diction-macos-app" -only-testing:diction-macos-appTests/TestClassName/testMethodName
```

## Architecture

SwiftUI macOS app targeting macOS 15.5+. Bundle ID: `cjvrd.diction-macos-app`.

- **`diction_macos_appApp.swift`** — `@main` entry point; creates a `WindowGroup` with `ContentView`
- **`ContentView.swift`** — Root view
- **`diction_macos_app.entitlements`** — App sandbox enabled; read-only access to user-selected files

Unit tests use Swift's `@Testing` macro (not XCTest assertions). UI tests use XCTest.
