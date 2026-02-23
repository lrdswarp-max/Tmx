#!/bin/bash

# Script de Configuração Interativa Dev Stack - Samsung S24 Ultra
# Criado por Manus AI para o repositório Tmx

clear
echo "===================================================="
echo "🚀 SETUP DEV STACK - SAMSUNG S24 ULTRA (TERMUX)"
echo "===================================================="
echo "Este script irá configurar seu ambiente de desenvolvimento."
echo ""

# 1. Update e Upgrade
echo "🔄 [1/4] Atualizando pacotes do sistema..."
pkg update && pkg upgrade -y

# 2. Instalação de Dependências
echo "📦 [2/4] Instalando ferramentas essenciais (Git, Node, Python, Build Tools)..."
pkg install git nodejs-lts npm python3 build-essential clang make -y

# 3. Configuração do Gemini CLI (Workaround --ignore-scripts)
echo "🤖 [3/4] Deseja instalar o Gemini CLI? (s/n)"
read -r install_gemini
if [[ $install_gemini =~ ^[Ss]$ ]]; then
    echo "Instalando Gemini CLI com workaround para S24 Ultra..."
    npm install -g @google/gemini-cli --ignore-scripts
    echo "✅ Gemini CLI instalado (Use 'gemini' para iniciar)."
fi

# 4. Finalização e Comandos Automáticos
echo "⚙️ [4/4] Finalizando configurações..."
termux-setup-storage

echo ""
echo "===================================================="
echo "✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
echo "===================================================="
echo "Sugestões para o S24 Ultra:"
echo "1. Desative a otimização de bateria para o Termux."
echo "2. Use Samsung DeX para uma experiência desktop."
echo "3. O relatório completo está no seu repositório Tmx."
echo ""
echo "Deseja rodar o script de validação agora? (s/n)"
read -r run_val
if [[ $run_val =~ ^[Ss]$ ]]; then
    curl -sL https://raw.githubusercontent.com/lrdswarp-max/Tmx/main/docs/s24-ultra/test_config.sh | bash
fi

echo "Setup finalizado. Boa codificação!"
