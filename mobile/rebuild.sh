#!/bin/bash
# Full clean rebuild — run this when hot restart doesn't pick up changes
cd "$(dirname "$0")"
echo "🧹 Cleaning..."
flutter clean
echo "📦 Getting packages..."
flutter pub get
echo "🚀 Running app..."
flutter run
