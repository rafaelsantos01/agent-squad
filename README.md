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

- **Jira:** o MCP oficial da Atlassian, já declarado no `.mcp.json` (OAuth, sem token). Veja [MCP do Jira (Atlassian)](#mcp-do-jira-atlassian). O `analyst` herda as ferramentas MCP da sessão. Sem MCP, ele devolve o texto pronto para colar.
- **GitLab:** `glab` autenticado para o `builder` abrir os MRs. Sem `glab`, ele usa o link de criação de MR que aparece no push.

## Instalação

### Opção 1: copiar a pasta `.claude` (projeto sem `.claude`)

O repo já traz a pasta `.claude` pronta (agentes + `settings.json` que inicia no orquestrador) e, na raiz, o `.mcp.json` do Jira. Copie os dois:

```bash
git clone https://github.com/rafaelsantos01/agent-squad.git ~/agent-squad
cp -r ~/agent-squad/.claude ./meu-projeto/
cp ~/agent-squad/.mcp.json ./meu-projeto/
```

```powershell
git clone https://github.com/rafaelsantos01/agent-squad.git $HOME\agent-squad
Copy-Item -Recurse $HOME\agent-squad\.claude .\meu-projeto\
Copy-Item $HOME\agent-squad\.mcp.json .\meu-projeto\
```

> Se o projeto já tem `.claude/settings.json` ou `.mcp.json`, copiar sobrescreve esses arquivos. Nesse caso use a opção 2.

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
- copia o `.mcp.json` (servidor `atlassian`, OAuth) para a raiz do projeto; se já existir um, não sobrescreve e mostra o trecho para mesclar;
- não sobrescreve agentes nem o `.mcp.json` existentes, a menos que você passe `--force` (`-Force` no PowerShell). Com `--force`, o `.mcp.json` é substituído inteiro.

Para instalar para todos os projetos: `--global` (`-Global`), que usa `~/.claude/agents/`. Nesse modo, inicie com `claude --agent orchestrator`. O `.mcp.json` não é copiado; o instalador mostra o comando para registrar o MCP do Jira no escopo do usuário.

## MCP do Jira (Atlassian)

O `.mcp.json` na raiz do projeto declara o servidor MCP remoto oficial da Atlassian:

```json
{
  "mcpServers": {
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v2/mcp"
    }
  }
}
```

Ele usa OAuth: o arquivo não tem token nenhum. O login fica nas credenciais do seu usuário (keychain do sistema), nunca no repo.

1. Abra o `claude` no projeto. Na primeira vez ele pergunta se você aprova os servidores MCP do `.mcp.json`: aprove o `atlassian`.
2. Rode `/mcp`, escolha `atlassian` e autentique no navegador com sua conta Atlassian.
3. Pronto: o `analyst` passa a usar as ferramentas do Jira.

- Revogar o login: `claude mcp logout atlassian`.
- Refazer a escolha de aprovar/recusar os servidores do projeto: `claude mcp reset-project-choices`.
- Usar em todos os projetos sem o `.mcp.json`: `claude mcp add --scope user --transport http atlassian https://mcp.atlassian.com/v2/mcp`.

### Segredos

- Nunca commite token, senha ou chave de API. Este repo é público.
- Se um dia precisar de token, use `${NOME_DA_VARIAVEL}` no `.mcp.json` e defina o valor numa variável de ambiente, fora do repo.
- `.env`, `.env.*` e `.claude/settings.local.json` estão no `.gitignore`.

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
