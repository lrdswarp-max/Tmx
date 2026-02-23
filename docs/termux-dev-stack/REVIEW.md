# Revisão do `install.sh` (termux-dev-stack)

Fonte analisada via curl:
`https://raw.githubusercontent.com/lucasrdsved/termux-dev-stack/master/install.sh`

## Problemas encontrados no menu interativo

1. **Pausa obrigatória após toda ação**
   - O script sempre executa:
     ```bash
     echo "\nPressione Enter para continuar..."
     read -r
     ```
   - Isso força dois `Enter` por ciclo (um para escolher opção e outro para “continuar”), o que parece “loop infinito” no uso manual.

2. **Recursão sem limite em `run_step`**
   - Em falha de etapa, se usuário responder `s`, a função chama ela mesma (`run_step "$func_name"`) indefinidamente.
   - Em ambiente onde o erro é permanente (ex: `pkg` quebrado), isso vira loop de reexecução.

3. **Remoção de estado usa nome errado**
   - O arquivo de estado salva `step_name` (ex: `base_packages`) mas no retry remove `func_name` (ex: `install_base_packages`).
   - Resultado: o estado pode ficar inconsistente e o retry não limpar corretamente a etapa.

4. **Uso de `echo "\n..."`**
   - Em vários shells imprime `\n` literal, deixando UI confusa.

## O que foi ajustado na versão revisada

Arquivo: `install-reviewed.sh`

- Adicionado `PAUSE_BETWEEN_STEPS=0|1` para desativar pausa obrigatória.
- `run_step` refeito para loop iterativo com `max_retries=2` (evita recursão infinita).
- Retry agora remove o **step_name correto** do estado.
- Trocado `echo "\n..."` por `printf`.

## Simulação completa

Arquivo: `simulate-menu.sh`

- Cria ambiente isolado em `docs/termux-dev-stack/.simulation`.
- Moca comandos (`pkg`, `git`, `sqlite3`, `curl`, etc.) para não alterar o sistema.
- Executa fluxo passando por opções `1..7` e saída `0`.
- Gera transcript em `simulation-transcript.txt`.

> Observação: durante a simulação aparecem algumas mensagens “Opção inválida” por causa de `\n` extras no input automatizado; isso é esperado do roteiro de teste e não trava o menu.
