#!/usr/bin/env bash
# ============================================================
#  build_dmg.sh — Create a distributable DMG for MacAssist
# ============================================================
#  Usage:
#    chmod +x build_dmg.sh
#    ./build_dmg.sh
#
#  This script:
#    1. Copies MacAssist.app into a temporary staging folder
#    2. Adds an /Applications symlink for drag-to-install UX
#    3. Packs everything into a compressed DMG using hdiutil
# ============================================================

set -e

APP_NAME="MacAssist"
APP_BUNDLE="MacAssist.app"
VERSION="1.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING_DIR="$(mktemp -d)/dmg_staging"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${SCRIPT_DIR}/${APP_BUNDLE}"
OUTPUT_DMG="${SCRIPT_DIR}/${DMG_NAME}"

echo "🔨 Building DMG for ${APP_NAME} v${VERSION}..."

# ── Validate app exists ─────────────────────────────────────
if [ ! -d "${APP_PATH}" ]; then
  echo "❌  Error: ${APP_BUNDLE} not found at ${APP_PATH}"
  echo "   Build the app in Xcode first (Product › Archive or Build)."
  exit 1
fi

# ── Prepare staging directory ───────────────────────────────
mkdir -p "${STAGING_DIR}"
echo "📁 Staging directory: ${STAGING_DIR}"

# Copy app bundle into staging
cp -a "${APP_PATH}" "${STAGING_DIR}/"

# Add /Applications symlink so users can drag-and-drop to install
ln -s /Applications "${STAGING_DIR}/Applications"

# ── Remove any existing DMG ─────────────────────────────────
if [ -f "${OUTPUT_DMG}" ]; then
  echo "♻️  Removing existing DMG: ${DMG_NAME}"
  rm -f "${OUTPUT_DMG}"
fi

# ── Create compressed DMG ───────────────────────────────────
echo "📦 Creating DMG..."
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "${OUTPUT_DMG}"

# ── Cleanup ─────────────────────────────────────────────────
rm -rf "$(dirname "${STAGING_DIR}")"

# ── Done ────────────────────────────────────────────────────
echo ""
echo "✅  DMG created successfully:"
echo "   ${OUTPUT_DMG}"
echo ""
echo "📋 Distribution note:"
echo "   This app is NOT signed with an Apple Developer certificate."
echo "   Users must run the following command after installation to"
echo "   bypass Gatekeeper:"
echo ""
echo "   xattr -rd com.apple.quarantine /Applications/${APP_BUNDLE}"
echo ""
