#!/bin/sh
set -e

KEYSTORE_DIR="$(dirname "$0")/../flutter_app/android"
KEYSTORE_FILE="$KEYSTORE_DIR/upload-keystore.jks"

if [ -f "$KEYSTORE_FILE" ]; then
  echo "Keystore already exists at $KEYSTORE_FILE"
  echo "To regenerate, delete it first: rm $KEYSTORE_FILE"
  exit 0
fi

echo "Generating Android release keystore..."
echo ""
echo "You will be prompted for passwords. Remember these — they go in key.properties"
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_FILE" \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storetype jks

echo ""
echo "Keystore generated at: $KEYSTORE_FILE"
echo ""
echo "Now create flutter_app/android/key.properties with:"
echo "  storeFile=../upload-keystore.jks"
echo "  storePassword=YOUR_STORE_PASSWORD"
echo "  keyAlias=upload"
echo "  keyPassword=YOUR_KEY_PASSWORD"