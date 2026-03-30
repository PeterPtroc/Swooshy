#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <version> <url> <sha256> <output-path>" >&2
  exit 1
fi

VERSION="$1"
URL="$2"
SHA256="$3"
OUTPUT_PATH="$4"
BUNDLE_ID="${BUNDLE_ID:-com.xiamiyu123.swooshy}"

mkdir -p "$(dirname "$OUTPUT_PATH")"

cat > "$OUTPUT_PATH" <<EOF
cask "swooshy" do
  version "$VERSION"
  sha256 "$SHA256"

  url "$URL",
      verified: "github.com/xiamiyu123/Swooshy/"
  name "Swooshy"
  desc "Open-source macOS touchpad-first window utility"
  homepage "https://github.com/xiamiyu123/Swooshy"

  depends_on macos: ">= :sonoma"

  app "Swooshy.app"

  # Reset stale Accessibility TCC records after install/upgrade.
  postflight do
    system_command "tccutil",
                   args: ["reset", "Accessibility", "$BUNDLE_ID"],
                   sudo: false
  end

  # Remove records after uninstall.
  uninstall_postflight do
    system_command "tccutil",
                   args: ["reset", "Accessibility", "$BUNDLE_ID"],
                   sudo: false
  end
end
EOF
