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

  uninstall quit: "$BUNDLE_ID"

  # reset accessibility records after install/upgrade.
  postflight do
    # tccutil exits non-zero when there is no existing record yet.
    system_command "/bin/sh",
                   args: ["-c", "tccutil reset Accessibility \"\$1\" >/dev/null 2>&1 || true", "_", "$BUNDLE_ID"],
                   sudo: false
  end

  uninstall_postflight do
    system_command "/bin/sh",
                   args: ["-c", "tccutil reset Accessibility \"\$1\" >/dev/null 2>&1 || true", "_", "$BUNDLE_ID"],
                   sudo: false
  end
end
EOF
