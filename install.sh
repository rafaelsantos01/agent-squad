#!/usr/bin/env bash
# Instala os agentes do agent-squad em um projeto (.claude/agents) ou globalmente (~/.claude/agents).
#
# Uso:
#   ./install.sh                 # instala no projeto atual
#   ./install.sh --global        # instala em ~/.claude/agents
#   curl -fsSL https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --global
set -euo pipefail

REPO_RAW="${AGENT_SQUAD_RAW:-https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main}"
AGENTS=(orchestrator explorer planner analyst builder documenter explainer)

GLOBAL=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --global|-g) GLOBAL=1 ;;
    --force|-f)  FORCE=1 ;;
    -h|--help)
      echo "Uso: install.sh [--global] [--force]"
      echo "  --global  instala em ~/.claude/agents em vez do projeto atual"
      echo "  --force   sobrescreve agentes que já existem"
      exit 0 ;;
    *) echo "Opção desconhecida: $arg" >&2; exit 1 ;;
  esac
done

if [ "$GLOBAL" -eq 1 ]; then
  BASE="$HOME/.claude"
else
  BASE="$(pwd)/.claude"
fi
DEST="$BASE/agents"
mkdir -p "$DEST"

# Se rodando de um clone local, copia os arquivos; senão baixa do GitHub.
SRC_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/.claude/agents/orchestrator.md" ]; then
  SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.claude/agents"
fi

for name in "${AGENTS[@]}"; do
  target="$DEST/$name.md"
  if [ -f "$target" ] && [ "$FORCE" -eq 0 ]; then
    echo "  = $name.md já existe (use --force para sobrescrever)"
    continue
  fi
  if [ -n "$SRC_DIR" ]; then
    cp "$SRC_DIR/$name.md" "$target"
  else
    curl -fsSL "$REPO_RAW/.claude/agents/$name.md" -o "$target"
  fi
  echo "  + $name.md"
done

# Faz o orquestrador ser o agente principal da sessão no projeto.
SETTINGS="$BASE/settings.json"
if [ "$GLOBAL" -eq 0 ]; then
  if [ ! -f "$SETTINGS" ]; then
    printf '{\n  "agent": "orchestrator"\n}\n' > "$SETTINGS"
    echo "  + settings.json (agent: orchestrator)"
  elif ! grep -q '"agent"' "$SETTINGS"; then
    echo "  ! $SETTINGS já existe: adicione \"agent\": \"orchestrator\" manualmente"
  fi
fi

echo "Agentes instalados em $DEST"
echo "Inicie com: claude   (ou: claude --agent orchestrator)"
