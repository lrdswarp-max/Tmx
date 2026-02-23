#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$ROOT_DIR/.simulation"
BIN_DIR="$SIM_DIR/bin"
HOME_DIR="$SIM_DIR/home"
TRANSCRIPT="$ROOT_DIR/simulation-transcript.txt"

rm -rf "$SIM_DIR"
mkdir -p "$BIN_DIR" "$HOME_DIR"

cat > "$BIN_DIR/pkg" <<'SH'
#!/usr/bin/env bash
echo "[mock pkg] $*"
exit 0
SH

cat > "$BIN_DIR/docker-compose" <<'SH'
#!/usr/bin/env bash
echo "[mock docker-compose] $*"
exit 0
SH

cat > "$BIN_DIR/docker" <<'SH'
#!/usr/bin/env bash
echo "[mock docker] $*"
exit 0
SH

cat > "$BIN_DIR/npm" <<'SH'
#!/usr/bin/env bash
echo "[mock npm] $*"
exit 0
SH

cat > "$BIN_DIR/rsync" <<'SH'
#!/usr/bin/env bash
echo "[mock rsync] $*"
exit 0
SH

cat > "$BIN_DIR/curl" <<'SH'
#!/usr/bin/env bash
echo "[mock curl] $*"
exit 0
SH

chmod +x "$BIN_DIR"/*

export PATH="$BIN_DIR:$PATH"
export HOME="$HOME_DIR"
export PAUSE_BETWEEN_STEPS=0
export ASSUME_YES=1

{
  printf '1\n8\n9\n0\n' | bash "$ROOT_DIR/install-reviewed.sh"
} | tee "$TRANSCRIPT"

echo "Transcript: $TRANSCRIPT"
