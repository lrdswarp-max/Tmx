# Rebuild completo do instalador (AI Hub centralizado)

## O que foi refeito do zero

O script `install-reviewed.sh` foi reescrito para implementar um instalador de **AI Hub centralizado e compartilhado** em `~/.aihub`, com:

- Menu interativo sem recursão infinita.
- Controle de pausa (`PAUSE_BETWEEN_STEPS`).
- Estado idempotente por etapa (`~/.aihub-install.state`).
- Estrutura de pastas compartilhada (`config`, `data`, `logs`, `scripts`, etc.).
- Geração automática dos arquivos principais:
  - `config/config.json`
  - `config/users.json`
  - `config/prompts.json`
  - `config/mcp-config.json`
  - `.env.shared`
  - `docker-compose.yml`
  - scripts utilitários (`start.sh`, `sync-config.sh`, `backup.sh`, `health-check.sh`)
- Fluxo para modo `docker` e `native`.

## Sobre o link do artefato Claude

Foi tentado acesso automatizado ao link público indicado, porém houve bloqueio por challenge do Cloudflare no `curl` e falha do browser headless no ambiente atual. Mesmo assim, o script foi refeito com base nos requisitos funcionais detalhados na solicitação (AI Hub centralizado, compartilhamento máximo e automação completa).

## Simulação

`simulate-menu.sh` roda um fluxo completo não destrutivo com mocks (`pkg`, `docker`, `docker-compose`, `npm`, `curl`, `rsync`) e gera `simulation-transcript.txt`.


## Atualização: projeto recuperado do Google Drive

O arquivo remoto foi recuperado com sucesso pelo endpoint direto do Drive:

- URL de origem: `https://drive.google.com/file/d/1uXh9Z4Y2-qkRn0cpq0auwsLjjNuAYLgE/view?usp=drivesdk`
- Método usado: `https://drive.google.com/uc?export=download&id=1uXh9Z4Y2-qkRn0cpq0auwsLjjNuAYLgE`
- Cópia local versionada: `docs/termux-dev-stack/TERMUX-DEV-STACK-COMPLETO-2.md`

Assim, o projeto/documentação final indicado no link agora está salvo no repositório para revisão e uso offline.
