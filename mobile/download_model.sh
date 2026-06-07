#!/bin/bash
# Download MobileFaceNet TFLite model into Flutter assets.
# Run once from the mobile/ directory: bash download_model.sh
set -e
cd "$(dirname "$0")"

MODEL_DIR="assets/models"
MODEL_FILE="$MODEL_DIR/mobilefacenet.tflite"
MODEL_URL="https://raw.githubusercontent.com/MCarlomagno/FaceRecognitionAuth/master/assets/mobilefacenet.tflite"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_FILE" ]; then
  echo "✅  Model already present: $MODEL_FILE ($(du -h "$MODEL_FILE" | cut -f1))"
  exit 0
fi

echo "📥  Downloading MobileFaceNet TFLite model..."
curl -L "$MODEL_URL" -o "$MODEL_FILE" --progress-bar

# Verify file is large enough to be a real model (>100 KB)
SIZE=$(wc -c < "$MODEL_FILE")
if [ "$SIZE" -lt 102400 ]; then
  echo ""
  echo "⛔  Downloaded file is too small ($SIZE bytes) — likely an error page."
  echo "    Please download manually from: $MODEL_URL"
  echo "    Save as: mobile/assets/models/mobilefacenet.tflite"
  rm -f "$MODEL_FILE"
  exit 1
fi

echo "✅  Model saved: $MODEL_FILE ($(du -h "$MODEL_FILE" | cut -f1))"
echo ""
echo "Now run: flutter pub get && flutter run"
