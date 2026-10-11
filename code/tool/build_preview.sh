#!/usr/bin/env bash
# Builds a self-contained web preview (no CDN requests) into build/preview,
# trimmed to the files the Claude artifact can serve.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release --no-web-resources-cdn --pwa-strategy=none
rm -rf build/preview
cp -r build/web build/preview
cd build/preview
find . -name '*.symbols' -delete
rm -rf canvaskit/skwasm* canvaskit/wimp* canvaskit/webparagraph icons
rm -f .last_build_id flutter_service_worker.js manifest.json assets/AssetManifest.bin
sed -i 's#<base href="/">##' index.html
