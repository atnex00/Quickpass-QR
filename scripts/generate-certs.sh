#!/usr/bin/env bash
set -euo pipefail

CERTS_DIR="$(cd "$(dirname "$0")" && pwd)/certs"
mkdir -p "$CERTS_DIR"

if [[ -f "$CERTS_DIR/server.crt" && -f "$CERTS_DIR/server.key" ]]; then
  echo "Certificates already exist at $CERTS_DIR"
  exit 0
fi

echo "Generating self-signed certificate for development..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$CERTS_DIR/server.key" \
  -out "$CERTS_DIR/server.crt" \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "Certificate generated at $CERTS_DIR"
echo "  server.crt  — certificate"
echo "  server.key  — private key"
echo ""
echo "For production, replace with Let's Encrypt or a proper CA-signed certificate."