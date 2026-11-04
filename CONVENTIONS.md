# Convenções do agent-squad

Este arquivo descreve o que o repo faz hoje. Cada regra aponta para um exemplo real (`arquivo:linha`).

## Stack e comandos

O repo não tem código de aplicação. Ele distribui agentes do Claude Code e é composto por:

- Agentes em Markdown com frontmatter YAML: `.claude/agents/*.md` (ex.: `.claude/agents/builder.md:1-6`).
- Configuração da sessão: `.claude/settings.json` (`"agent": "orchestrator"` na linha 3, `permissions.deny` nas linhas 4-11).
- Instaladores: `install.sh` (Bash) e `install.ps1` (PowerShell, compatível com Windows PowerShell 5.1).
- Documentação de uso: `README.md`, em português.

Não há build, lint, testes automatizados nem CI. A verificação é manual:

```bash
# sintaxe do instalador Bash
bash -n install.sh
```

```powershell
# parse do instalador PowerShell (deve retornar 0 erros)
$e = $null
[void][System.Management.Automation.Language.Parser]::ParseFile("$PWD\install.ps1", [ref]$null, [ref]$e)
$e.Count
```

```bash
# instalar num diretório temporário a partir do clone local
tmp=$(mktemp -d) && (cd "$tmp" && /caminho/do/agent-squad/install.sh) && ls "$tmp/.claude/agents"
```

Também é preciso validar todo JSON alterado (por exemplo `.claude/settings.json`) com um parser, como `ConvertFrom-Json` ou `python -m json.tool`.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `.claude/agents/` | Um arquivo `<nome>.md` por agente (7 hoje: `orchestrator`, `explorer`, `planner`, `analyst`, `builder`, `documenter`, `explainer`). |
| `.claude/settings.json` | Define o orquestrador como agente principal e bloqueia a leitura de segredos. |
| `install.sh`, `install.ps1` | Instaladores equivalentes: um para Bash e outro para PowerShell. |
| `README.md` | Visão geral, instalação, uso e customização, em português. |
| `docs/en/plans/` | Planos de implementação em inglês, um arquivo por plano (ex.: `docs/en/plans/2026-11-04-jira-mcp-oauth.md`). |
| `.gitignore` | Ignora `.env`, `.env.*` e `.claude/settings.local.json` (linhas 1-3). |

## Nomes

- **Agentes:** nome em minúsculas, em inglês e sem separador. O nome do arquivo é igual ao campo `name` (ex.: `.claude/agents/planner.md:2` contém `name: planner`).
- **Planos:** `docs/en/plans/AAAA-MM-DD-<slug-em-kebab-case>.md` (ex.: `2026-11-04-jira-mcp-oauth.md`).
- **Relatórios dos agentes:** `<Nome> Report` (Exploration, Jira, Build, Documentation), conforme a tabela em `.claude/agents/orchestrator.md:12-19`.
- **Variáveis no Bash:** `MAIÚSCULAS_COM_UNDERSCORE` para globais (`REPO_RAW`, `AGENTS`, `SRC_DIR`, `install.sh:11-12,38`) e minúsculas para variáveis de laço (`name`, `target`, `install.sh:43-44`).
- **Variáveis no PowerShell:** PascalCase (`$RepoRaw`, `$Agents`, `$SrcDir`, `install.ps1:13-14,21`) e minúsculas no laço (`$name`, `$target`, `install.ps1:26-27`).
- **Variável de ambiente:** prefixo `AGENT_SQUAD_` (`AGENT_SQUAD_RAW`, `install.sh:11`, `install.ps1:13`).

## Padrões por camada

### Agentes (`.claude/agents/*.md`)

- O frontmatter tem `name`, `description`, `tools` (opcional) e `model`, nessa ordem (`.claude/agents/builder.md:1-6`).
- Omitir `tools` faz o agente herdar todas as ferramentas, inclusive as de MCP. É o caso do `analyst`, que precisa das ferramentas do Jira (`.claude/agents/analyst.md:1-5`; explicado em `README.md:89`).
- Todos os agentes usam `model: inherit` (ex.: `.claude/agents/orchestrator.md:5`).
- A `description` diz quando usar o agente e o que ele devolve (ex.: "Devolve um Build Report.", `.claude/agents/builder.md:3`).
- O corpo começa com `Você é o **<nome>**.` (ex.: `.claude/agents/documenter.md:8`).
- Agentes somente leitura dizem isso explicitamente e limitam o Bash a comandos de leitura (`.claude/agents/explorer.md:8`, `.claude/agents/explainer.md:8`).

### Instaladores (`install.sh` / `install.ps1`)

Os dois scripts têm o mesmo comportamento e precisam mudar juntos.

| Regra | install.sh | install.ps1 |
|---|---|---|
| Falhar no primeiro erro | `set -euo pipefail` (linha 9) | `$ErrorActionPreference = 'Stop'` (linha 12) |
| Flags | `--global`/`-g` e `--force`/`-f` em `case` (linhas 16-27) | `[switch]$Global`, `[switch]$Force` (linhas 7-10) |
| Ajuda e opção inválida | `-h`/`--help`; opção desconhecida vai para stderr com `exit 1` (linhas 20-25) | não tem (usa a validação do `param`) |
| Origem remota | `REPO_RAW="${AGENT_SQUAD_RAW:-...}"` (linha 11) | `$RepoRaw = if ($env:AGENT_SQUAD_RAW) ...` (linha 13) |
| Lista de agentes | `AGENTS=(...)` (linha 12) | `$Agents = @(...)` (linha 14) |
| Usar o clone local se existir | `BASH_SOURCE[0]` + teste de `orchestrator.md` (linhas 38-41) | `$PSScriptRoot` + `Test-Path` (linhas 21-24) |
| Copiar ou baixar | `cp` ou `curl -fsSL` (linhas 49-53) | `Copy-Item` ou `Invoke-WebRequest -UseBasicParsing` (linhas 32-36) |
| Não sobrescrever sem force | `[ -f "$target" ] && [ "$FORCE" -eq 0 ]` (linha 45) | `(Test-Path $target) -and -not $Force` (linha 28) |
| `settings.json` só no modo projeto | linhas 58-66 | linhas 41-49 |
| Escrever arquivo sem BOM | `printf ... >` (linha 61) | `[System.IO.File]::WriteAllText` (linha 44) |

Prefixos das mensagens de saída (dois espaços + símbolo + espaço):

- `  + ` arquivo criado ou copiado (`install.sh:54`, `install.ps1:37`);
- `  = ` arquivo já existe e foi pulado (`install.sh:46`, `install.ps1:29`);
- `  ! ` o usuário precisa agir manualmente (`install.sh:64`, `install.ps1:47`).

Os scripts terminam com duas linhas: onde os agentes foram instalados e como iniciar (`install.sh:68-69`, `install.ps1:51-52`).

Os dois scripts começam com um bloco de comentário `# Uso:` com os exemplos de invocação (`install.sh:2-8`, `install.ps1:1-6`). Os comentários internos explicam o porquê de cada bloco (ex.: `install.sh:37`, `install.sh:57`).

### Configuração (`.claude/settings.json`)

- O arquivo declara `$schema` (linha 2) e `"agent": "orchestrator"` (linha 3).
- `permissions.deny` bloqueia `curl` e a leitura de `.env`, `.env.*` e `secrets/**` (linhas 5-10).
- A indentação do bloco `permissions` está irregular (linhas 4-12). Ao editar o arquivo, use 2 espaços.

### Tratamento de erros

- Bash: `set -euo pipefail` aborta no primeiro erro (`install.sh:9`) e o `curl -f` falha em HTTP de erro (`install.sh:52`). Erros de uso vão para stderr com `exit 1` (`install.sh:25`).
- PowerShell: `$ErrorActionPreference = 'Stop'` transforma qualquer erro em exceção que encerra o script (`install.ps1:12`).
- Situações que não são erro, como arquivo já existente, geram aviso (`  = `/`  ! `) e o script continua.

## Encoding, idioma e fim de linha

- Todos os arquivos são UTF-8 sem BOM e usam LF. Não há `.gitattributes`. Em clones Windows com `core.autocrlf=true`, confira se o arquivo commitado continua com LF.
- `install.ps1` não tem BOM, então o PowerShell 5.1 o lê como ANSI. Por isso **as strings dele são só ASCII, sem acentos** (`"ja existe"` em `install.ps1:29`, `"sessao"` em `install.ps1:40`). Um comentário ainda tem acento (`senão`, `install.ps1:20`). Comentários não quebram a execução, mas não adicione acentos novos.
- `install.sh`, `README.md` e os agentes usam português com acentos (`install.sh:23`, `README.md:3`).
- Mensagens dos instaladores, README e prompts dos agentes ficam em português. Os planos em `docs/en/` ficam em inglês (`docs/en/plans/2026-11-04-jira-mcp-oauth.md:1`).

## Segredos (repo público)

- Nunca faça commit de credenciais. `.env`, `.env.*` e `.claude/settings.local.json` estão no `.gitignore` (linhas 1-3), e o `settings.json` bloqueia a leitura deles (`.claude/settings.json:7-9`).
- Servidores MCP declarados no repo usam OAuth ou referências `${VAR}`, nunca tokens literais. Essa regra vem do plano `docs/en/plans/2026-11-04-jira-mcp-oauth.md` (Context e Out). O `.mcp.json` ainda não existe no repo.

## Adicionar um agente

1. Crie `.claude/agents/<nome>.md` com o frontmatter acima.
2. Adicione o nome em `AGENTS` no `install.sh:12` e em `$Agents` no `install.ps1:14`.
3. Adicione uma linha na tabela do `.claude/agents/orchestrator.md:12-19`.
4. Adicione uma linha na tabela do `README.md:5-13`.

O `README.md:94` cita apenas os passos 1 a 3. O passo 4 segue o fato de que a tabela do README lista todos os agentes.

## Testes

Não há framework de testes, fixtures nem mocks. A verificação é a da seção "Stack e comandos": `bash -n`, o parse do PowerShell, a validação de JSON e a execução dos dois instaladores num diretório temporário, nos modos padrão, `--force` e reexecução (deve imprimir `  = `).

## Git

- Branch principal: `main` (`origin/HEAD -> origin/main`).
- Branches: `feat/<slug>` (ex.: `feat/jira-mcp-oauth` no plano `docs/en/plans/2026-11-04-jira-mcp-oauth.md`). Quando houver tarefa no Jira, use `<tipo>/<CHAVE>-<slug>` (`.claude/agents/builder.md:16`).
- Commits: Conventional Commits, `<tipo>: <descrição curta>`. O único commit até agora é `feat: add agentes` (15a0177).
- Entrega por Pull Request no GitHub (`rafaelsantos01/agent-squad`) com `gh pr create`. O `.claude/agents/builder.md:23` e o `README.md:23` falam em `glab`/MR porque descrevem os projetos de destino dos agentes, não este repo.
- Trabalhe numa worktree com branch nova e nunca direto na `main` (`.claude/agents/builder.md:13-18`).
