#!/usr/bin/env bash
# Compila la versión web de la app del repartidor para Render (sitio
# estático). Ver docs/DESPLIEGUE_RENDER.md del repositorio venexpress.
#
#   API_BASE_URL     obligatoria, p. ej. https://venexpress.onrender.com/api
#   FLUTTER_VERSION  opcional (por defecto la usada en desarrollo)
set -euo pipefail

: "${API_BASE_URL:?Define API_BASE_URL con la URL de la API, p. ej. https://venexpress.onrender.com/api}"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.6}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter-$FLUTTER_VERSION}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --disable-analytics > /dev/null 2>&1 || true
flutter pub get
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL="$API_BASE_URL"
