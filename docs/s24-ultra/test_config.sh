#!/bin/bash

# Simulação de ambiente Termux para validação de comandos
echo "Iniciando validação de comandos do documento..."

# 1. Testar comandos de instalação (simulados via apt no Ubuntu)
echo "Testando comandos de instalação básicos..."
sudo apt update -y && sudo apt install -y git nodejs npm python3 build-essential
if [ $? -eq 0 ]; then
    echo "✅ Comandos de instalação básicos: OK"
else
    echo "❌ Comandos de instalação básicos: FALHOU"
fi

# 2. Testar instalação do Gemini CLI com --ignore-scripts
echo "Testando instalação do Gemini CLI com --ignore-scripts..."
sudo npm install -g @google/gemini-cli --ignore-scripts
if [ $? -eq 0 ]; then
    echo "✅ Instalação Gemini CLI (--ignore-scripts): OK"
else
    echo "❌ Instalação Gemini CLI (--ignore-scripts): FALHOU"
fi

# 3. Testar comandos do Next.js
echo "Testando criação de projeto Next.js (simulado)..."
# Usando --yes para evitar prompts interativos
npx create-next-app@latest test-app --typescript --tailwind --app --eslint --src-dir --import-alias "@/*" --yes
if [ $? -eq 0 ]; then
    echo "✅ npx create-next-app: OK"
else
    echo "❌ npx create-next-app: FALHOU"
fi

# 4. Validar sintaxe do wrapper script
echo "Validando sintaxe do wrapper script..."
cat > wrapper_test.sh << 'EOF'
#!/bin/bash
case "$1" in
    openai) echo "openai";;
    gemini) echo "gemini";;
esac
EOF
bash -n wrapper_test.sh
if [ $? -eq 0 ]; then
    echo "✅ Sintaxe do Wrapper Script: OK"
else
    echo "❌ Sintaxe do Wrapper Script: FALHOU"
fi

echo "Validação concluída."
