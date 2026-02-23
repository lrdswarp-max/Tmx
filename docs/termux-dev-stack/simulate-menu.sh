#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$ROOT_DIR/.simulation"
MOCK_BIN="$WORK_DIR/mock-bin"
HOME_DIR="$WORK_DIR/home"
TRANSCRIPT="$ROOT_DIR/simulation-transcript.txt"

rm -rf "$WORK_DIR"
mkdir -p "$MOCK_BIN" "$HOME_DIR"

mock_cmd() {
  local name="$1"
  cat > "$MOCK_BIN/$name" <<'MEOF'
#!/usr/bin/env bash
echo "[MOCK] $0 $*"
exit 0
MEOF
  chmod +x "$MOCK_BIN/$name"
}

for c in pkg git sqlite3 npm npx code-server curl sh; do
  mock_cmd "$c"
done

# curl precisa imprimir algo quando usado em command substitution
cat > "$MOCK_BIN/curl" <<'MEOF'
#!/usr/bin/env bash
if [[ "$*" == *"ohmyzsh"* ]]; then
  echo "echo '[MOCK] install oh-my-zsh'"
  exit 0
fi
echo "[MOCK] curl $*"
exit 0
MEOF
chmod +x "$MOCK_BIN/curl"

INPUT_SEQUENCE=$'1\nn\n\n2\n\n3\n\n4\n\n5\n\n6\n\n7\nn\n\n0\n'

PATH="$MOCK_BIN:$PATH" HOME="$HOME_DIR" PAUSE_BETWEEN_STEPS=0 \
  bash "$ROOT_DIR/install-reviewed.sh" <<< "$INPUT_SEQUENCE" > "$TRANSCRIPT" 2>&1 || true

echo "Transcript gerado em: $TRANSCRIPT"
