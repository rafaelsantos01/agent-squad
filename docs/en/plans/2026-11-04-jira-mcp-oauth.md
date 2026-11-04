# Connect the Atlassian (Jira) MCP server via OAuth

- Date: 2026-11-04
- Jira: (filled in by analyst)
- Repos: agent-squad

## Context
The `analyst` agent must create and update Jira tasks, which requires a Jira MCP server in the Claude Code session. `agent-squad` is a public GitHub repo (rafaelsantos01/agent-squad) that distributes agents, so no credential can ever be committed. Atlassian's official remote MCP server authenticates with OAuth: the repo only declares the server URL, and each user logs in through `/mcp`, with tokens stored in the user's own keychain/credential store, never in the repo.

## Goal
- The repo ships a secret-free `.mcp.json` declaring the `atlassian` server at `https://mcp.atlassian.com/v2/mcp`.
- Both installers (`install.sh`, `install.ps1`) put that `.mcp.json` in the root of the target project, never overwrite an existing one unless `--force`/`-Force`, and in global mode only print the `claude mcp add --scope user` hint.
- The README explains how to approve, authenticate, revoke and keep secrets out of the repo.
- `.gitignore` (already present but untracked) is committed.

## Scope
### In
- New file `.mcp.json` at the repo root.
- Commit `.gitignore` (content unchanged, trailing newline added).
- `install.sh` and `install.ps1`: copy/download `.mcp.json` to the target project root, with no-overwrite, `--force` and `--global` behavior; update `--help` in `install.sh`.
- `README.md`: new section "## MCP do Jira (Atlassian)", plus updates to "Pre-requisitos no projeto", Option 1, the "O instalador:" list and the `--global` line.
- Worktree + branch `feat/jira-mcp-oauth`, push, PR on GitHub via `gh`.

### Out
- Atlassian API tokens of any kind.
- The local `mcp-atlassian` server.
- Any change to `.claude/agents/*.md`.
- Any change to `.claude/settings.json` (do NOT add `enableAllProjectMcpServers`).
- Jira task (no MCP connected yet; Jira phase skipped).
- CI or automated tests (none exist).

## Acceptance criteria
- [ ] (a) `.mcp.json` is valid JSON, contains no secret, and `/mcp` in Claude Code lists the `atlassian` server asking for authentication.
- [ ] (b) Both installers copy `.mcp.json` to the target project root; they do not overwrite an existing `.mcp.json` (printing the merge message and JSON snippet) unless `--force`/`-Force` is passed; in `--global`/`-Global` mode they do not copy it and only print the `claude mcp add --scope user ...` hint.
- [ ] (c) README explains the configuration (approval, `/mcp`, logout, reset, global usage, secret rules) and the related sections point to it.
- [ ] (d) No token or secret value appears in the diff.

## Affected areas
| Repo | File | Change |
|---|---|---|
| agent-squad | `.mcp.json` | New: `atlassian` HTTP server, OAuth, no headers |
| agent-squad | `.gitignore` | Add trailing newline only; first commit of the file |
| agent-squad | `install.sh` | Add `ROOT_DIR`; new `.mcp.json` block after the settings block; update `--help` |
| agent-squad | `install.ps1` | Add `$RootDir`; new `.mcp.json` block after the settings block (ASCII-only strings); update header comment |
| agent-squad | `README.md` | New "MCP do Jira (Atlassian)" section; update lines 22, 29-41, 64-70 |
| agent-squad | `docs/en/plans/2026-11-04-jira-mcp-oauth.md` | This plan, committed with the change |

## Steps
1. **[agent-squad] Create worktree and branch**
   - Files: none (git only)
   - Do: from `D:\Projetos\agent-squad` run `git worktree add ../agent-squad-jira-mcp-oauth -b feat/jira-mcp-oauth main`. All following steps run inside `D:\Projetos\agent-squad-jira-mcp-oauth`. Note: `.gitignore` and this plan are untracked in the main checkout, so they do NOT exist in the worktree yet; steps 3 and 7 create them there.
   - Follow pattern: delivery rule from the interview (worktree + branch `feat/jira-mcp-oauth`).
   - Done when: `git -C D:\Projetos\agent-squad-jira-mcp-oauth branch --show-current` prints `feat/jira-mcp-oauth`.

2. **[agent-squad] Add `.mcp.json`**
   - Files: `.mcp.json` (repo root)
   - Do: create the file with exactly this content (2-space indent, LF line endings, trailing newline):
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
   - Follow pattern: 2-space JSON with trailing newline as written by `install.sh:61`.
   - Done when: the file parses as JSON (for example `python -c "import json;json.load(open('.mcp.json'))"` or `Get-Content .mcp.json -Raw | ConvertFrom-Json`) and contains no `headers` or `env` keys.

3. **[agent-squad] Add `.gitignore` to the worktree**
   - Files: `.gitignore`
   - Do: create `.gitignore` in the worktree with the same three lines as the untracked file in the main checkout (`D:\Projetos\agent-squad\.gitignore`): `.env`, `.env.*`, `.claude/settings.local.json`, LF line endings, plus a trailing newline after the last line. No other change.
   - Follow pattern: `D:\Projetos\agent-squad\.gitignore:1-3`.
   - Done when: the file has exactly 3 lines and ends with `\n`; `git check-ignore -v .env .claude/settings.local.json` matches both.

4. **[agent-squad] `install.sh`: root variable, `.mcp.json` block, help text**
   - Files: `install.sh`
   - Do:
     - Line 23: replace the `--force` help line with `echo "  --force   sobrescreve agentes e o .mcp.json que já existem (substitui o .mcp.json inteiro)"`.
     - Lines 37-41: introduce `ROOT_DIR=""` alongside `SRC_DIR=""`; inside the existing `if`, set `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and then `SRC_DIR="$ROOT_DIR/.claude/agents"`. Keep the detection condition unchanged.
     - After the settings block (after line 66) and before the final `echo` lines (68-69), add a block with a comment `# Conecta o MCP do Jira (Atlassian, OAuth) no projeto.`:
       - If `GLOBAL` is 1: print `  i modo global: o .mcp.json não é copiado. Para usar o Jira em todos os projetos:` and then `    claude mcp add --scope user --transport http atlassian https://mcp.atlassian.com/v2/mcp`.
       - Else set `MCP_TARGET="$(pwd)/.mcp.json"`.
         - If the file exists and `FORCE` is 0: print `  ! .mcp.json ja existe: mescle manualmente o servidor atlassian` followed by the snippet below, printed with `cat <<'EOF'` (quoted heredoc, no expansion):
           ```
               "atlassian": {
                 "type": "http",
                 "url": "https://mcp.atlassian.com/v2/mcp"
               }
           ```
           and a line `    (dentro de "mcpServers")` before the snippet.
         - Otherwise: if `ROOT_DIR` is non-empty, `cp "$ROOT_DIR/.mcp.json" "$MCP_TARGET"`; else `curl -fsSL "$REPO_RAW/.mcp.json" -o "$MCP_TARGET"`. Then print `  + .mcp.json (MCP atlassian; autentique com /mcp)`.
     - Optionally extend the header comment (lines 2-8) with one line: `# Também copia o .mcp.json (MCP do Jira via OAuth) para a raiz do projeto.`
   - Follow pattern: `install.sh:43-55` (exists/force check, cp vs curl, `  + X` / `  ! X` messages) and `install.sh:57-66` (project-only block keyed on `GLOBAL`).
   - Done when: `bash -n install.sh` passes and the block sits between the settings block and `echo "Agentes instalados em $DEST"`.

5. **[agent-squad] `install.ps1`: root variable, `.mcp.json` block**
   - Files: `install.ps1`
   - Do (every new string ASCII-only, no accents; file stays UTF-8 without BOM):
     - Lines 20-24: add `$RootDir = $null` next to `$SrcDir = $null`; inside the existing `if`, set `$RootDir = $PSScriptRoot` and `$SrcDir = Join-Path $RootDir '.claude/agents'`. Keep the condition unchanged.
     - After the settings block (after line 49) and before the final `Write-Host` lines (51-52), add a block with comment `# Conecta o MCP do Jira (Atlassian, OAuth) no projeto.`:
       - If `$Global`: `Write-Host '  i modo global: o .mcp.json nao e copiado. Para usar o Jira em todos os projetos:'` and `Write-Host '    claude mcp add --scope user --transport http atlassian https://mcp.atlassian.com/v2/mcp'`.
       - Else `$McpTarget = Join-Path (Get-Location) '.mcp.json'`.
         - If `(Test-Path $McpTarget) -and -not $Force`: `Write-Host '  ! .mcp.json ja existe: mescle manualmente o servidor atlassian'`, `Write-Host '    (dentro de "mcpServers")'`, then the same snippet as step 4 printed via a single-quoted here-string (`@'` ... `'@`) passed to `Write-Host`.
         - Otherwise: if `$RootDir`, `Copy-Item (Join-Path $RootDir '.mcp.json') $McpTarget -Force`; else `Invoke-WebRequest -UseBasicParsing "$RepoRaw/.mcp.json" -OutFile $McpTarget`. Then `Write-Host '  + .mcp.json (MCP atlassian; autentique com /mcp)'`.
     - Header comment (lines 1-6): add `# Tambem copia o .mcp.json (MCP do Jira via OAuth) para a raiz do projeto. -Force substitui o .mcp.json inteiro.`
   - Follow pattern: `install.ps1:26-38` (Test-Path/-Force, Copy-Item vs Invoke-WebRequest) and `install.ps1:40-49` (project-only block keyed on `$Global`).
   - Done when: `$e=$null; [System.Management.Automation.Language.Parser]::ParseFile('install.ps1',[ref]$null,[ref]$e) | Out-Null; $e.Count` prints `0`, and a non-ASCII check on the file shows only the bytes that were already there before (for example compare `git diff install.ps1` added lines against `[^\x00-\x7F]`: zero matches).

6. **[agent-squad] README: new section and pointers**
   - Files: `README.md`
   - Do (README stays in Portuguese):
     - Line 22: replace with `- **Jira:** o MCP oficial da Atlassian, já declarado no \`.mcp.json\` (OAuth, sem token). Veja [MCP do Jira (Atlassian)](#mcp-do-jira-atlassian). O \`analyst\` herda as ferramentas MCP da sessão. Sem MCP, ele devolve o texto pronto para colar.`
     - Line 29: replace with `O repo já traz a pasta \`.claude\` pronta (agentes + \`settings.json\` que inicia no orquestrador) e, na raiz, o \`.mcp.json\` do Jira. Copie os dois:`
     - Bash block (lines 31-34): after the `cp -r` line add `cp ~/agent-squad/.mcp.json ./meu-projeto/`.
     - PowerShell block (lines 36-39): after the `Copy-Item -Recurse` line add `Copy-Item $HOME\agent-squad\.mcp.json .\meu-projeto\`.
     - Line 41: replace with `> Se o projeto já tem \`.claude/settings.json\` ou \`.mcp.json\`, copiar sobrescreve esses arquivos. Nesse caso use a opção 2.`
     - "O instalador:" list (lines 66-68): after the settings bullet add `- copia o \`.mcp.json\` (servidor \`atlassian\`, OAuth) para a raiz do projeto; se já existir um, não sobrescreve e mostra o trecho para mesclar;` and change the last bullet to `- não sobrescreve agentes nem o \`.mcp.json\` existentes, a menos que você passe \`--force\` (\`-Force\` no PowerShell). Com \`--force\`, o \`.mcp.json\` é substituído inteiro.`
     - Line 70: replace with `Para instalar para todos os projetos: \`--global\` (\`-Global\`), que usa \`~/.claude/agents/\`. Nesse modo, inicie com \`claude --agent orchestrator\`. O \`.mcp.json\` não é copiado; o instalador mostra o comando para registrar o MCP do Jira no escopo do usuário.`
     - Insert between the end of "## Instalação" (after line 70) and "## Uso" (line 72) this section:
       ```markdown
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
       ```
       (The outer fence above is only for this plan; in the README the section is plain Markdown with one inner ```json block.)
   - Follow pattern: existing heading levels and code-block style in `README.md:25-70`.
   - Done when: the section order is "## Instalação", "## MCP do Jira (Atlassian)", "## Uso", "## Customizando", and the anchor `#mcp-do-jira-atlassian` resolves on GitHub preview.

7. **[agent-squad] Add this plan to the worktree**
   - Files: `docs/en/plans/2026-11-04-jira-mcp-oauth.md`
   - Do: copy `D:\Projetos\agent-squad\docs\en\plans\2026-11-04-jira-mcp-oauth.md` to the same path inside the worktree.
   - Follow pattern: planner output location `docs/en/plans/`.
   - Done when: the file exists in the worktree.

8. **[agent-squad] Verify locally**
   - Files: none (temporary directories in the scratchpad)
   - Do: run every check in the Verification section; fix any failure in the step that owns the file before continuing.
   - Follow pattern: Verification section of this plan.
   - Done when: all checks pass.

9. **[agent-squad] Commit, push, open PR**
   - Files: `.mcp.json`, `.gitignore`, `install.sh`, `install.ps1`, `README.md`, `docs/en/plans/2026-11-04-jira-mcp-oauth.md`
   - Do: `git add` exactly these files; commit `feat: conecta o MCP do Jira (Atlassian) via OAuth`; `git push -u origin feat/jira-mcp-oauth`; `gh pr create --base main --head feat/jira-mcp-oauth` with a body summarizing the acceptance criteria and noting no token is included. Before merging, run the remote-install check with `AGENT_SQUAD_RAW=https://raw.githubusercontent.com/rafaelsantos01/agent-squad/feat/jira-mcp-oauth`.
   - Follow pattern: commit style `15a0177 feat: add agentes`.
   - Done when: `gh pr view` shows the PR open against `main`.

## Risks
| Risk | Mitigation |
|---|---|
| Untracked `.gitignore` (and this plan) in the main checkout block `git pull` after merge ("untracked working tree files would be overwritten") | After the PR merges, delete `D:\Projetos\agent-squad\.gitignore` and `D:\Projetos\agent-squad\docs\en\plans\2026-11-04-jira-mcp-oauth.md` from the main checkout (identical content is in the commit), then `git pull`. |
| Remote install cannot be tested before merge (files only on the branch) | Test with `AGENT_SQUAD_RAW=https://raw.githubusercontent.com/rafaelsantos01/agent-squad/feat/jira-mcp-oauth` (bash) or `$env:AGENT_SQUAD_RAW` (PowerShell). |
| `-Force`/`-Global` cannot be passed through `irm ... \| iex` | Already a pre-existing limitation; not changed. README keeps the clone-based example for flags. |
| Accented characters break `install.ps1` on Windows PowerShell 5.1 (UTF-8 without BOM) | All new `install.ps1` strings are ASCII-only; step 5 checks added lines for non-ASCII bytes. |
| `--force` replaces a user's existing `.mcp.json` with other servers | Documented in `--help`, the `install.ps1` header and README ("substituído inteiro"). |
| Project-scoped MCP servers require interactive approval; users may decline and see no Jira tools | README explains the approval prompt and `claude mcp reset-project-choices`. `enableAllProjectMcpServers` is intentionally not set. |
| v2 endpoint may expose meta tools (discover/execute) instead of direct Jira tools | `analyst.md` does not reference `mcp__` tool names, so it keeps working; no agent change needed. |
| A secret slips into the diff | Verification greps the diff for token patterns before push. |

## Rollback
1. Before merge: close the PR (`gh pr close feat/jira-mcp-oauth --delete-branch`), then `git worktree remove ../agent-squad-jira-mcp-oauth` and `git branch -D feat/jira-mcp-oauth` from `D:\Projetos\agent-squad`.
2. After merge: on `main`, `git revert` the merge commit (`git revert -m 1` with the merge commit SHA shown by `gh pr view feat/jira-mcp-oauth --json mergeCommit`), push, which removes `.mcp.json`, the installer blocks, and the README section together. If `.gitignore` should stay, restore it right after the revert with `git checkout` of the merge commit for `.gitignore` only and commit.
3. User side (no repo data or migrations involved): users who already logged in run `claude mcp logout atlassian`; projects that received `.mcp.json` from the installer can delete that file (or remove the `atlassian` entry if they merged it); users who added the global server run `claude mcp remove --scope user atlassian`.

## Verification
- Build/lint commands (agent-squad, run in the worktree):
  - JSON: `python -c "import json;json.load(open('.mcp.json'))"` (or `Get-Content .mcp.json -Raw | ConvertFrom-Json`).
  - Bash syntax: `bash -n install.sh`.
  - PowerShell parse: `$e=$null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path install.ps1),[ref]$null,[ref]$e) | Out-Null; $e.Count` must print `0`.
  - ASCII check for PowerShell: `git diff main -- install.ps1 | Select-String '^\+.*[^\x00-\x7F]'` must return nothing.
- Criterion (a): JSON check above passes; open `claude` in the worktree, approve `atlassian` when prompted, run `/mcp` and confirm `atlassian` is listed as needing authentication.
- Criterion (b), for both `bash D:/Projetos/agent-squad-jira-mcp-oauth/install.sh` and `powershell -NoProfile -File D:\Projetos\agent-squad-jira-mcp-oauth\install.ps1`, each in fresh temp directories under the scratchpad:
  1. New project: run in an empty dir; `.mcp.json` exists at the dir root (not in `.claude/`) and is byte-identical to the repo's (`git diff --no-index`/`fc.exe`); output contains `  + .mcp.json`.
  2. Existing `.mcp.json`: create one with `{"mcpServers":{}}`, run again; file is unchanged and output contains `  ! .mcp.json ja existe: mescle manualmente o servidor atlassian` plus the snippet.
  3. Force: same dir, run with `--force` / `-Force`; file now equals the repo's `.mcp.json`.
  4. Global: bash with `HOME` set to a temp dir (`HOME=$tmp/home bash .../install.sh --global`); PowerShell in a child process with `$env:USERPROFILE` set to a temp dir (`powershell -NoProfile -Command "$env:USERPROFILE='...'; & '...\install.ps1' -Global"`), confirming the final "Agentes instalados em" line points to the temp dir. In both: no `.mcp.json` created in the cwd or the temp home, and the output shows the `claude mcp add --scope user --transport http atlassian https://mcp.atlassian.com/v2/mcp` hint.
  5. Remote (after push, before merge): in a new temp dir run `AGENT_SQUAD_RAW=https://raw.githubusercontent.com/rafaelsantos01/agent-squad/feat/jira-mcp-oauth bash -c "curl -fsSL \$AGENT_SQUAD_RAW/install.sh | bash"` and the PowerShell equivalent with `$env:AGENT_SQUAD_RAW` and `irm "$env:AGENT_SQUAD_RAW/install.ps1" | iex`; `.mcp.json` is downloaded to the dir root.
- Criterion (c): read the rendered README on the PR; check the new section sits between "Instalação" and "Uso", the Jira prerequisite link jumps to it, Option 1 copies `.mcp.json`, and the installer list and `--global` line mention `.mcp.json`.
- Criterion (d): `git diff main --cached` (or `git diff main...HEAD`) piped to `grep -nEi 'ATATT|Bearer [A-Za-z0-9]|api[_-]?token"?\s*[:=]|secret"?\s*[:=]|password"?\s*[:=]'` returns nothing; `.mcp.json` has no `headers`/`env` keys.
