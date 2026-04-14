#!/usr/bin/env sh
# CoveSync installer
# Usage: curl -fsSL https://raw.githubusercontent.com/bazzaztech/CoveSync/main/install.sh | sh
set -e

REPO="bazzaztech/covesync-releases"
INSTALL_DIR="$HOME/.local/bin"
SERVICE_DIR="$HOME/.config/systemd/user"
BINARY="covesync"

# ── detect architecture ───────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)           ARCH_SUFFIX="amd64" ;;
  aarch64|arm64)    ARCH_SUFFIX="arm64" ;;
  armv7l)           ARCH_SUFFIX="arm"   ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [ "$OS" != "linux" ]; then
  echo "Unsupported OS: $OS (Linux only)"
  exit 1
fi

ASSET="${BINARY}-linux-${ARCH_SUFFIX}"

# ── resolve latest version ────────────────────────────────────────────────────
if [ -z "$VERSION" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
fi

if [ -z "$VERSION" ]; then
  echo "Could not determine latest release version."
  exit 1
fi

echo "Installing CoveSync ${VERSION} (linux/${ARCH_SUFFIX})..."

# ── download binary ───────────────────────────────────────────────────────────
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"
mkdir -p "$INSTALL_DIR"
TMP="$(mktemp)"
curl -fsSL "$DOWNLOAD_URL" -o "$TMP"
chmod +x "$TMP"
mv "$TMP" "$INSTALL_DIR/$BINARY"

echo "Binary installed to $INSTALL_DIR/$BINARY"

# ── ensure install dir is on PATH ─────────────────────────────────────────────
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo ""
    echo "NOTE: $INSTALL_DIR is not in your PATH."
    echo "Add this to ~/.bashrc or ~/.profile:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

# ── install systemd user service (optional) ───────────────────────────────────
if command -v systemctl >/dev/null 2>&1 && systemctl --user status >/dev/null 2>&1; then
  mkdir -p "$SERVICE_DIR"
  SERVICE_URL="https://raw.githubusercontent.com/${REPO}/main/dist/covesync.service"
  curl -fsSL "$SERVICE_URL" -o "$SERVICE_DIR/covesync.service"

  systemctl --user daemon-reload
  systemctl --user enable covesync
  systemctl --user start covesync

  echo "Systemd user service installed and started."
  echo "  Status : systemctl --user status covesync"
  echo "  Logs   : journalctl --user -u covesync -f"
  echo "  Stop   : systemctl --user stop covesync"
else
  echo ""
  echo "Systemd not available. Run manually:"
  echo "  $INSTALL_DIR/$BINARY"
fi

echo ""
echo "CoveSync is running at https://localhost:8485"
