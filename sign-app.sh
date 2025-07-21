#!/bin/bash

# Sign the app with ad-hoc signature (no Developer ID required)
# This helps with some quarantine issues but not all

echo "🔐 Signing AskRepo.app..."

# Ad-hoc sign (free, no Developer ID needed)
codesign --force --deep --sign - "build/AskRepo.app"

# Verify the signature
codesign --verify --verbose "build/AskRepo.app"

echo "✅ App signed successfully"