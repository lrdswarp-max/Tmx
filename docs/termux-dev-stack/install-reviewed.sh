#!/usr/bin/env bash
set -u

# AI Hub Centralizado para Termux (refeito do zero)
# - Menu interativo sem recursão
# - Setup compartilhado em ~/.aihub
# - Suporte Docker/Native

LOG_FILE="${HOME}/aihub-install.log"
STATE_FILE="${HOME}/.aihub-install.state"
AIHUB_DIR="${AIHUB_DIR:-$HOME/.aihub}"
PAUSE_BETWEEN_STEPS="${PAUSE_BETWEEN_STEPS:-1}"
ASSUME_YES="${ASSUME_YES:-0}"
INSTALL_MODE="${INSTALL_MODE:-docker}" # docker|native

log() {
  local level="$1"; shift
  printf '[%s] %s\n' "$level" "$*" | tee -a "$LOG_FILE"
}

confirm() {
  if [ "$ASSUME_YES" = "1" ]; then
    return 0
  fi
  read -r -p "$1 [s/N]: " ans
  case "$ans" in
    [sS]|[sS][iI][mM]) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_state_file() {
  touch "$STATE_FILE"
}

mark_done() {
  grep -Fxq "$1" "$STATE_FILE" 2>/dev/null || echo "$1" >> "$STATE_FILE"
}

is_done() {
  grep -Fxq "$1" "$STATE_FILE" 2>/dev/null
}

clear_step() {
  sed -i "/^$1$/d" "$STATE_FILE" 2>/dev/null || true
}

write_env_shared() {
  local env_file="$AIHUB_DIR/.env.shared"
  if [ -f "$env_file" ]; then
    log INFO ".env.shared já existe, preservando arquivo."
    return 0
  fi
  cat > "$env_file" <<'ENV'
# Preencha com suas chaves reais e rode: set -a; source ~/.aihub/.env.shared; set +a
GOOGLE_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GROQ_API_KEY=
AIHUB_ADMIN_KEY=aihub_change_me
ENV
  chmod 600 "$env_file"
  log OK "Criado $env_file"
}

setup_directories() {
  local step="directories"
  is_done "$step" && { log INFO "Diretórios já configurados."; return 0; }

  mkdir -p "$AIHUB_DIR"/{config,data/{conversations,embeddings,cache},logs,plugins,mcp-servers,evals,scripts}
  mark_done "$step"
  log OK "Estrutura compartilhada criada em $AIHUB_DIR"
}

write_config_files() {
  local step="config_files"
  is_done "$step" && { log INFO "Configurações já geradas."; return 0; }

  cat > "$AIHUB_DIR/config/config.json" <<'JSON'
{
  "server": {"host": "0.0.0.0", "port": 5555, "api_version": "v1"},
  "providers": {
    "gemini": {"enabled": true, "priority": 1, "api_key_env": "GOOGLE_API_KEY", "models": ["gemini-2.5-pro", "gemini-2.5-flash"], "rate_limit": 100},
    "claude": {"enabled": true, "priority": 2, "api_key_env": "ANTHROPIC_API_KEY", "models": ["claude-opus-4.5", "claude-sonnet-4.5"], "rate_limit": 150},
    "openai": {"enabled": true, "priority": 3, "api_key_env": "OPENAI_API_KEY", "models": ["gpt-5.1", "gpt-4-turbo"], "rate_limit": 100},
    "groq": {"enabled": true, "priority": 4, "api_key_env": "GROQ_API_KEY", "models": ["llama-3.3-70b", "mixtral-8x7b"], "rate_limit": 300, "cost_per_1k": 0.0001},
    "ollama": {"enabled": true, "priority": 5, "base_url": "http://localhost:11434", "models": ["llama2", "mistral"], "cost_per_1k": 0.0}
  },
  "routing": {"default": "claude", "code": "groq", "research": "claude", "budget": "ollama", "fast": "groq", "creative": "claude"},
  "caching": {"enabled": true, "semantic_cache": true, "ttl_seconds": 3600},
  "governance": {"rate_limit_global": 1000, "cost_limit_daily": 50.0, "audit_logging": true}
}
JSON

  cat > "$AIHUB_DIR/config/users.json" <<'JSON'
{
  "users": [
    {
      "id": "user-001",
      "name": "admin",
      "role": "admin",
      "api_key": "aihub_change_me",
      "permissions": ["all"],
      "rate_limit": 500,
      "cost_limit": 100.0
    }
  ]
}
JSON

  cat > "$AIHUB_DIR/config/prompts.json" <<'JSON'
{
  "system_prompts": {
    "default": "Você é um assistente útil e objetivo.",
    "code": "Você é especialista em programação e depuração.",
    "research": "Você é um pesquisador detalhista.",
    "creative": "Você é um escritor criativo e claro."
  }
}
JSON

  cat > "$AIHUB_DIR/config/mcp-config.json" <<'JSON'
{
  "mcp_servers": [
    {"name": "github", "type": "stdio", "command": "node /path/to/github-mcp"},
    {"name": "filesystem", "type": "stdio", "command": "python /path/to/fs-mcp.py"}
  ]
}
JSON

  write_env_shared
  mark_done "$step"
  log OK "Arquivos de configuração gerados."
}

write_compose_file() {
  cat > "$AIHUB_DIR/docker-compose.yml" <<'YAML'
version: '3.8'
services:
  aihub:
    image: calciumion/new-api:latest
    ports:
      - "5555:8000"
    environment:
      - TZ=America/Sao_Paulo
      - SQL_DSN=sqlite:///data/aihub.db
      - GOOGLE_API_KEY=${GOOGLE_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - GROQ_API_KEY=${GROQ_API_KEY}
    volumes:
      - ${HOME}/.aihub/config:/app/config
      - ${HOME}/.aihub/data:/app/data
      - ${HOME}/.aihub/logs:/app/logs
    restart: unless-stopped
YAML
}

write_scripts() {
  local step="scripts"
  is_done "$step" && { log INFO "Scripts já gerados."; return 0; }

  cat > "$AIHUB_DIR/scripts/start.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/.aihub"
if [ -f .env.shared ]; then
  set -a
  # shellcheck disable=SC1091
  source .env.shared
  set +a
fi
if command -v docker-compose >/dev/null 2>&1; then
  docker-compose up -d
elif command -v docker >/dev/null 2>&1; then
  docker compose up -d
else
  echo "Docker não encontrado. Rode no modo native." >&2
  exit 1
fi
SH

  cat > "$AIHUB_DIR/scripts/sync-config.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
CONFIG_SOURCE="$HOME/.aihub/config"
SYNC_TARGETS=(
  "/data/data/com.termux/files/home/ubuntu/.aihub/config"
  "/root/.aihub/config"
)
for target in "${SYNC_TARGETS[@]}"; do
  if [ -d "$(dirname "$target")" ]; then
    rsync -av "$CONFIG_SOURCE/" "$target/" --exclude="*.log"
    echo "✓ Sincronizado: $target"
  fi
done
SH

  cat > "$AIHUB_DIR/scripts/backup.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/.aihub-backup-$STAMP.tar.gz"
tar -czf "$OUT" -C "$HOME" .aihub
printf 'Backup criado: %s\n' "$OUT"
SH

  cat > "$AIHUB_DIR/scripts/health-check.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if command -v curl >/dev/null 2>&1; then
  curl -fsS "http://localhost:5555/" >/dev/null && echo "AI Hub online" || echo "AI Hub offline"
else
  echo "curl não encontrado"
fi
SH

  chmod +x "$AIHUB_DIR/scripts/"*.sh
  write_compose_file
  mark_done "$step"
  log OK "Scripts utilitários e docker-compose gerados."
}

install_dependencies() {
  local step="dependencies"
  is_done "$step" && { log INFO "Dependências já marcadas como instaladas."; return 0; }

  if command -v pkg >/dev/null 2>&1; then
    pkg update -y
    pkg install -y curl jq rsync sqlite git
    if [ "$INSTALL_MODE" = "native" ]; then
      pkg install -y nodejs-lts
    else
      pkg install -y docker
    fi
  else
    log INFO "pkg não encontrado. Instalando apenas validações locais (modo não-Termux)."
  fi

  mark_done "$step"
  log OK "Etapa de dependências concluída."
}

native_bootstrap() {
  local step="native_bootstrap"
  is_done "$step" && { log INFO "Bootstrap nativo já executado."; return 0; }
  if ! command -v npm >/dev/null 2>&1; then
    log ERR "npm não encontrado para modo native."
    return 1
  fi
  npm install -g new-api
  mark_done "$step"
  log OK "New API instalada em modo nativo."
}

docker_bootstrap() {
  local step="docker_bootstrap"
  is_done "$step" && { log INFO "Bootstrap docker já executado."; return 0; }
  if command -v docker-compose >/dev/null 2>&1; then
    (cd "$AIHUB_DIR" && docker-compose config >/dev/null)
  elif command -v docker >/dev/null 2>&1; then
    (cd "$AIHUB_DIR" && docker compose config >/dev/null)
  else
    log ERR "Docker não encontrado para modo docker."
    return 1
  fi
  mark_done "$step"
  log OK "Configuração Docker validada."
}

run_step() {
  local func="$1" step="$2" retries=0 max_retries=2
  while true; do
    if "$func"; then
      return 0
    fi
    retries=$((retries + 1))
    log ERR "Falha na etapa $step (tentativa $retries/$max_retries)."
    if [ "$retries" -ge "$max_retries" ]; then
      return 1
    fi
    if confirm "Deseja tentar novamente '$step'?"; then
      clear_step "$step"
      continue
    fi
    return 1
  done
}

install_all() {
  run_step install_dependencies dependencies || return 1
  run_step setup_directories directories || return 1
  run_step write_config_files config_files || return 1
  run_step write_scripts scripts || return 1
  if [ "$INSTALL_MODE" = "native" ]; then
    run_step native_bootstrap native_bootstrap || return 1
  else
    run_step docker_bootstrap docker_bootstrap || return 1
  fi
}

show_menu() {
  printf '\n==== AI Hub Installer (Termux) ====\n'
  echo "Modo atual: $INSTALL_MODE | AIHUB_DIR: $AIHUB_DIR"
  echo "1) Definir modo Docker"
  echo "2) Definir modo Native"
  echo "3) Instalar dependências"
  echo "4) Criar estrutura compartilhada"
  echo "5) Gerar configs"
  echo "6) Gerar scripts/startup"
  echo "7) Rodar bootstrap do modo atual"
  echo "8) Instalar tudo"
  echo "9) Mostrar próximos passos"
  echo "0) Sair"
}

show_next_steps() {
  cat <<TXT

Próximos passos:
1. Edite $AIHUB_DIR/.env.shared e adicione suas chaves.
2. Rode: $AIHUB_DIR/scripts/start.sh
3. Abra: http://localhost:5555
4. Health check: $AIHUB_DIR/scripts/health-check.sh
TXT
}

main_menu() {
  ensure_state_file
  log INFO "Iniciando instalador AI Hub..."
  while true; do
    show_menu
    read -r -p "Escolha: " opt
    case "$opt" in
      1) INSTALL_MODE="docker"; log INFO "Modo alterado para docker" ;;
      2) INSTALL_MODE="native"; log INFO "Modo alterado para native" ;;
      3) run_step install_dependencies dependencies ;;
      4) run_step setup_directories directories ;;
      5) run_step write_config_files config_files ;;
      6) run_step write_scripts scripts ;;
      7)
        if [ "$INSTALL_MODE" = "native" ]; then run_step native_bootstrap native_bootstrap; else run_step docker_bootstrap docker_bootstrap; fi ;;
      8) install_all ;;
      9) show_next_steps ;;
      0) log INFO "Saindo. Até mais."; exit 0 ;;
      *) log ERR "Opção inválida." ;;
    esac

    if [ "$PAUSE_BETWEEN_STEPS" = "1" ]; then
      read -r -p "Pressione Enter para continuar..." _
    fi
  done
}

main_menu
