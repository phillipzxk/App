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
# Bare page for the artifact: proper title, dark teal background while loading.
cat > index.html <<'HTML'
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Coach App Vorschau</title>
<style>:root{--bg:#0f3d35}html,body{margin:0;height:100%;background:var(--bg)}</style>
</head>
<body>
<script src="flutter_bootstrap.js" async></script>
</body>
</html>
HTML
