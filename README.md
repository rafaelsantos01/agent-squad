# agent-squad

Meus agentes do Claude Code, prontos para levar para qualquer projeto. Um **orquestrador** conduz o trabalho em fases fixas e delega cada fase a um especialista.

| Agente | Função | Saída |
|---|---|---|
| `orchestrator` | Conduz as fases na ordem: entrevista (uma pergunta por vez, sempre com resposta recomendada), exploração, plano, Jira, convenções, build, documentação e verificação. Não pula etapas. | Marcadores de fase |
| `explorer` | Só lê. Lê os docs e depois o código para mapear repos afetados, padrões existentes (`arquivo:linha`), integrações e riscos. | Exploration Report |
| `planner` | Escreve o plano em `docs/en/plans/` com template fixo, sem placeholders, passos em ordem de dependência e rollback. | Caminho do plano + passos |
| `analyst` | Cuida do Jira: tarefa em linguagem de negócio com o porquê, comenta o plano de execução com os links dos MRs e move os status. | Jira Report |
| `builder` | Lê o `CONVENTIONS.md`, implementa o plano numa worktree com branch nova, roda build e lint, faz push e abre o MR. | Build Report |
| `documenter` | Cria o `CONVENTIONS.md` a partir do código e atualiza o INDEX do repo, a doc de rotas e a doc de arquitetura. | Documentation Report |
| `explainer` | Só lê. Responde "como funciona X?" com referências. | Resposta + arquivos |

```
1 ENTREVISTA → 2 EXPLORAÇÃO → 3 PLANO → 4 JIRA → 5 CONVENÇÕES → 6 BUILD → 7 DOCUMENTAÇÃO → 8 VERIFICAÇÃO
   (você)        explorer      planner   analyst   documenter     builder    documenter     orchestrator + analyst
```

### Pré-requisitos no projeto

- **Jira:** um MCP do Jira/Atlassian configurado. O `analyst` herda as ferramentas MCP da sessão. Sem MCP, ele devolve o texto pronto para colar.
- **GitLab:** `glab` autenticado para o `builder` abrir os MRs. Sem `glab`, ele usa o link de criação de MR que aparece no push.

## Instalação

### Opção 1: copiar a pasta `.claude` (projeto sem `.claude`)

O repo já é uma pasta `.claude` pronta (agentes + `settings.json` que inicia no orquestrador):

```bash
git clone https://github.com/rafaelsantos01/agent-squad.git ~/agent-squad
cp -r ~/agent-squad/.claude ./meu-projeto/
```

```powershell
git clone https://github.com/rafaelsantos01/agent-squad.git $HOME\agent-squad
Copy-Item -Recurse $HOME\agent-squad\.claude .\meu-projeto\
```

> Se o projeto já tem `.claude/settings.json`, copiar a pasta inteira sobrescreve esse arquivo. Nesse caso use a opção 2.

### Opção 2: instalador (mescla com um `.claude` existente)

No diretório do projeto:

```bash
# Linux / macOS / Git Bash
curl -fsSL https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main/install.ps1 | iex
```

Ou clonando:

```bash
git clone https://github.com/rafaelsantos01/agent-squad.git ~/agent-squad
cd meu-projeto && ~/agent-squad/install.sh
```

O instalador:

- copia os agentes para `.claude/agents/` do projeto;
- cria `.claude/settings.json` com `"agent": "orchestrator"` (se ainda não existir), para a sessão já começar no orquestrador;
- não sobrescreve agentes existentes, a menos que você passe `--force` (`-Force` no PowerShell).

Para instalar para todos os projetos: `--global` (`-Global`), que usa `~/.claude/agents/`. Nesse modo, inicie com `claude --agent orchestrator`.

## Uso

```bash
claude
> corrige o bug de login que retorna 500 quando o email tem maiúscula
```

O orquestrador abre a entrevista e segue as 8 fases. Perguntas como `como funciona a validação do token?` vão direto para o `explainer`, sem abrir o fluxo.

## Customizando

Cada agente é um `.md` com frontmatter:

```yaml
---
name: builder
description: quando o orquestrador deve usar este agente
tools: Read, Write, Edit, Glob, Grep, Bash   # omita para herdar todas (inclusive MCP)
model: inherit   # ou sonnet, opus, haiku
---
```

Para adicionar um agente novo: crie `.claude/agents/<nome>.md`, adicione o nome na lista `AGENTS` dos dois instaladores e na tabela do `orchestrator.md`.
