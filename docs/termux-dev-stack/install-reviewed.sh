#!/bin/bash

# Revisão local do instalador Termux Dev Stack
# Objetivo: evitar "loop impossível de usar" no menu interativo

LOG_FILE="${HOME}/termux_dev_stack_install.log"
INSTALL_STATE_FILE="${HOME}/.termux_dev_stack_install_state"
PAUSE_BETWEEN_STEPS="${PAUSE_BETWEEN_STEPS:-1}" # 0 desativa pausa após cada ação

log_info() { echo "[INFO] $@" | tee -a "$LOG_FILE"; }
log_success() { echo "[SUCESSO] $@" | tee -a "$LOG_FILE"; }
log_error() { echo "[ERRO] $@" | tee -a "$LOG_FILE"; }

check_command() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  read -r -p "$1 [s/N]: " response
  case "$response" in
    [sS][iI]|[sS]) return 0 ;;
    *) return 1 ;;
  esac
}

mark_as_installed() { echo "$1" >> "$INSTALL_STATE_FILE"; }
is_installed() { grep -Fxq "$1" "$INSTALL_STATE_FILE" 2>/dev/null; }

install_base_packages() {
  local step_name="base_packages"
  log_info "Iniciando: Instalação de pacotes base..."
  is_installed "$step_name" && { log_info "Pacotes base já instalados. Pulando."; return 0; }
  pkg update -y || { log_error "Falha ao atualizar pkg"; return 1; }
  pkg upgrade -y || { log_error "Falha ao fazer upgrade de pkg"; return 1; }
  pkg install -y git nodejs-lts npm python3 build-essential curl wget vim nano zsh openssh sqlite proot-distro rsync || {
    log_error "Falha ao instalar pacotes base"; return 1;
  }
  mark_as_installed "$step_name"
  log_success "Pacotes base instalados com sucesso."
}

setup_directories() {
  local step_name="directories"
  log_info "Iniciando: Configuração de diretórios..."
  is_installed "$step_name" && { log_info "Diretórios já configurados. Pulando."; return 0; }
  mkdir -p ~/.termux/scripts ~/.termux/hub/{wrappers,sync,cache,docs} ~/.config/llm/aliases ~/.aihub/{config,data,logs,scripts} ~/projects || {
    log_error "Falha ao criar estrutura de diretórios"; return 1;
  }
  mark_as_installed "$step_name"
  log_success "Diretórios configurados com sucesso."
}

setup_zsh_ohmyzsh() {
  local step_name="zsh_ohmyzsh"
  log_info "Iniciando: Configuração Zsh e Oh-My-Zsh..."
  is_installed "$step_name" && { log_info "Zsh e Oh-My-Zsh já configurados. Pulando."; return 0; }

  [ -d "$HOME/.oh-my-zsh" ] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
    log_error "Falha ao instalar Oh-My-Zsh"; return 1;
  }
  [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || return 1
  [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || return 1
  [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || return 1

  mark_as_installed "$step_name"
  log_success "Zsh e Oh-My-Zsh configurados com sucesso."
}

setup_hub_mcp() {
  local step_name="hub_mcp"
  log_info "Iniciando: Configuração do Hub MCP (SQLite)..."
  is_installed "$step_name" && { log_info "Hub MCP já configurado. Pulando."; return 0; }
  mkdir -p ~/.termux/hub/sync
  echo 'CREATE TABLE IF NOT EXISTS skills (id INTEGER PRIMARY KEY, name TEXT UNIQUE);' > ~/.termux/hub/init-db.sql
  sqlite3 ~/.termux/hub/database.db < ~/.termux/hub/init-db.sql || { log_error "Falha ao configurar database do Hub MCP"; return 1; }
  mark_as_installed "$step_name"
  log_success "Hub MCP configurado com sucesso."
}

configure_zshrc() {
  local step_name="zshrc_config"
  log_info "Iniciando: Configuração do .zshrc..."
  is_installed "$step_name" && { log_info ".zshrc já configurado. Pulando."; return 0; }
  cat > ~/.zshrc <<'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git command-not-found colored-man-pages extract zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
ZSHRC
  mark_as_installed "$step_name"
  log_success ".zshrc configurado com sucesso."
}

install_code_server() {
  local step_name="code_server"
  log_info "Iniciando: Instalação do Code-Server..."
  is_installed "$step_name" && { log_info "Code-Server já instalado. Pulando."; return 0; }
  check_command code-server || log_info "Code-Server não detectado. Instale manualmente se necessário."
  mark_as_installed "$step_name"
  log_success "Etapa de Code-Server concluída."
}

show_menu() {
  printf "\n--- Menu de Instalação Termux Dev Stack ---\n"
  echo "1. Instalar Pacotes Base"
  echo "2. Configurar Estrutura de Diretórios"
  echo "3. Configurar Zsh e Oh-My-Zsh"
  echo "4. Configurar Hub MCP"
  echo "5. Configurar .zshrc"
  echo "6. Instalar Code-Server"
  echo "7. Instalar TUDO"
  echo "0. Sair"
  echo "-------------------------------------------"
}

run_step() {
  local func_name="$1"
  local step_name="$2"
  local retries=0
  local max_retries=2

  while true; do
    log_info "Executando etapa: $func_name"
    if "$func_name"; then
      log_success "Etapa '$func_name' concluída com sucesso."
      return 0
    fi

    log_error "Etapa '$func_name' falhou."
    ((retries++))
    if (( retries > max_retries )); then
      log_error "Máximo de tentativas atingido para '$func_name'."
      return 1
    fi

    if confirm "Deseja tentar novamente esta etapa?"; then
      sed -i "/^${step_name}$/d" "$INSTALL_STATE_FILE" 2>/dev/null
      continue
    fi
    log_info "Pulando etapa '$func_name'."
    return 1
  done
}

main_menu() {
  while true; do
    show_menu
    read -r -p "Escolha uma opção: " choice
    case "$choice" in
      1) run_step install_base_packages base_packages ;;
      2) run_step setup_directories directories ;;
      3) run_step setup_zsh_ohmyzsh zsh_ohmyzsh ;;
      4) run_step setup_hub_mcp hub_mcp ;;
      5) run_step configure_zshrc zshrc_config ;;
      6) run_step install_code_server code_server ;;
      7)
        run_step install_base_packages base_packages
        run_step setup_directories directories
        run_step setup_zsh_ohmyzsh zsh_ohmyzsh
        run_step setup_hub_mcp hub_mcp
        run_step configure_zshrc zshrc_config
        run_step install_code_server code_server
        ;;
      0) log_info "Saindo do instalador. Até mais!"; exit 0 ;;
      *) log_error "Opção inválida." ;;
    esac

    if [ "$PAUSE_BETWEEN_STEPS" = "1" ]; then
      printf "\nPressione Enter para continuar..."
      read -r
    fi
  done
}

[ ! -f "$INSTALL_STATE_FILE" ] && touch "$INSTALL_STATE_FILE"
log_info "Iniciador do Termux Dev Stack iniciado."
main_menu
