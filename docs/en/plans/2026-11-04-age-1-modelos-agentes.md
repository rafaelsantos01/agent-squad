# Pin a model per squad agent to reduce token cost

- Date: 2026-11-04
- Jira: AGE-1 — https://rafinhapsantos50.atlassian.net/browse/AGE-1
- Repos: agent-squad

## Context
Every agent in the squad declares `model: inherit`, so each one runs on the main session's model (Opus). That includes agents whose work is simple, such as writing Jira text or applying a plan that is already written. Running those agents on cheaper models lowers the token cost of every squad run. The agents that need deep reasoning (orchestrator and planner) stay on the session model, so quality holds.

## Goal
Each agent's frontmatter pins a model that matches its job: `haiku` for the analyst, `sonnet` for builder, explainer, explorer and documenter, and `inherit` for orchestrator and planner. The README agent table shows the model of each agent.

## Scope
### In
- Change the `model:` line in the frontmatter of 5 agent files:
  - `.claude/agents/analyst.md:4` `model: inherit` -> `model: haiku`
  - `.claude/agents/builder.md:5` `model: inherit` -> `model: sonnet`
  - `.claude/agents/explainer.md:5` `model: inherit` -> `model: sonnet`
  - `.claude/disabled-agents/explorer.md:5` `model: inherit` -> `model: sonnet`
  - `.claude/disabled-agents/documenter.md:5` `model: inherit` -> `model: sonnet`
- Add a "Modelo" column to the agent table in `README.md:5-13`.
- Commit this plan file together with the change.
### Out
- `.claude/agents/orchestrator.md` and `.claude/disabled-agents/planner.md` (they stay `model: inherit`).
- The body/instructions of any agent.
- `~/.claude/agents/` (global install).
- Moving agents out of `.claude/disabled-agents/`.
- `CONVENTIONS.md` (the user is removing it on purpose; the PR does not touch it).
- `install.sh` and `install.ps1`, including the known breakage described under Risks.
- The "Customizando" example in `README.md:117-126`.

## Acceptance criteria
- [ ] `grep -n "^model:" .claude/agents/*.md .claude/disabled-agents/*.md` prints exactly: analyst `haiku` (line 4), builder `sonnet`, explainer `sonnet`, orchestrator `inherit`, documenter `sonnet`, explorer `sonnet`, planner `inherit` (all at line 5).
- [ ] `git diff origin/main -- .claude/` changes only the 5 `model:` lines (5 insertions, 5 deletions), and `git ls-files --eol .claude/` shows `i/lf` for all 7 agent files after the commit.
- [ ] The README agent table has a "Modelo" column with: orchestrator `inherit`, explorer `sonnet`, planner `inherit`, analyst `haiku`, builder `sonnet`, documenter `sonnet`, explainer `sonnet`.
- [ ] Post-merge manual check: `/agents` lists the new models, and the analyst running on haiku reads Jira issue AGE-1 through the Atlassian MCP.

## Affected areas
| Repo | File | Change |
|---|---|---|
| agent-squad | `.claude/agents/analyst.md` | Line 4: `model: inherit` -> `model: haiku` |
| agent-squad | `.claude/agents/builder.md` | Line 5: `model: inherit` -> `model: sonnet` |
| agent-squad | `.claude/agents/explainer.md` | Line 5: `model: inherit` -> `model: sonnet` |
| agent-squad | `.claude/disabled-agents/explorer.md` | Line 5: `model: inherit` -> `model: sonnet` |
| agent-squad | `.claude/disabled-agents/documenter.md` | Line 5: `model: inherit` -> `model: sonnet` |
| agent-squad | `README.md` | Lines 5-13: add "Modelo" column to the agent table |
| agent-squad | `docs/en/plans/2026-11-04-age-1-modelos-agentes.md` | New file: this plan |

## Steps
1. **[agent-squad] Prepare the worktree and copy the plan**
   - Files: `docs/en/plans/2026-11-04-age-1-modelos-agentes.md`
   - Do: Work in the existing worktree of branch `chore/AGE-1-modelos-agentes` (created from `origin/main`). Copy this plan from the main copy `D:\Projetos\agent-squad\docs\en\plans\2026-11-04-age-1-modelos-agentes.md` to the same relative path in the worktree. Do not copy or restore anything else from the main copy: its uncommitted deletions of `CONVENTIONS.md` and `docs/en/plans/2026-11-04-jira-mcp-oauth.md` must not reach the commit. Before editing, run `git ls-files --eol .claude/agents/*.md .claude/disabled-agents/*.md` in the worktree and note that all 7 files show `i/lf`.
   - Follow pattern: plan location `docs/en/plans/` as described in `README.md:9`.
   - Done when: `git status` in the worktree shows only the new plan file as untracked, and the branch is `chore/AGE-1-modelos-agentes`.

2. **[agent-squad] Pin the analyst on haiku**
   - Files: `.claude/agents/analyst.md`
   - Do: Replace line 4 `model: inherit` with `model: haiku`. Change nothing else (the analyst has no `tools:` line on purpose, so it inherits the MCP tools). Use the Edit tool on that exact line; do not rewrite the file, so LF line endings are kept.
   - Follow pattern: `.claude/agents/analyst.md:4` (frontmatter order name, description, model).
   - Done when: `grep -n "^model:" .claude/agents/analyst.md` prints `4:model: haiku`.

3. **[agent-squad] Pin builder and explainer on sonnet**
   - Files: `.claude/agents/builder.md`, `.claude/agents/explainer.md`
   - Do: In each file, replace line 5 `model: inherit` with `model: sonnet`, using Edit on that line only.
   - Follow pattern: `.claude/agents/builder.md:5`, `.claude/agents/explainer.md:5` (frontmatter order name, description, tools, model).
   - Done when: `grep -n "^model:"` prints `5:model: sonnet` for both files.

4. **[agent-squad] Pin explorer and documenter on sonnet**
   - Files: `.claude/disabled-agents/explorer.md`, `.claude/disabled-agents/documenter.md`
   - Do: In each file, replace line 5 `model: inherit` with `model: sonnet`, using Edit on that line only. Keep both files in `disabled-agents/`.
   - Follow pattern: `.claude/disabled-agents/explorer.md:5`, `.claude/disabled-agents/documenter.md:5`.
   - Done when: `grep -n "^model:"` prints `5:model: sonnet` for both files, and `.claude/agents/orchestrator.md:5` and `.claude/disabled-agents/planner.md:5` still read `model: inherit`.

5. **[agent-squad] Add the "Modelo" column to the README table**
   - Files: `README.md`
   - Do: In the table at `README.md:5-13`, add a "Modelo" column between "Função" and "Saída". The header becomes `| Agente | Função | Modelo | Saída |` and the separator `|---|---|---|---|`. For each row, insert the model cell after the Função cell: orchestrator `` `inherit` ``, explorer `` `sonnet` ``, planner `` `inherit` ``, analyst `` `haiku` ``, builder `` `sonnet` ``, documenter `` `sonnet` ``, explainer `` `sonnet` ``. Do not change any other text in the table or elsewhere in the README.
   - Follow pattern: `README.md:5-13` (backticked agent names, one row per agent).
   - Done when: every row in lines 5-13 has 4 cells, and the Modelo values match the list above.

6. **[agent-squad] Verify the diff and line endings**
   - Files: `.claude/agents/*.md`, `.claude/disabled-agents/*.md`, `README.md`
   - Do: Run `grep -n "^model:" .claude/agents/*.md .claude/disabled-agents/*.md` and compare with acceptance criterion 1. Run `git diff --stat` and `git diff -- .claude/` and confirm 5 files changed with 1 insertion and 1 deletion each, and no whole-file rewrites. Run `git diff -- README.md` and confirm only lines 5-13 changed. If `git diff` shows every line of a file as changed, line endings were converted to CRLF: restore that file with `git checkout -- <file>` and redo its edit.
   - Follow pattern: acceptance criteria above.
   - Done when: all three checks pass.

7. **[agent-squad] Commit**
   - Files: the 5 agent files, `README.md`, `docs/en/plans/2026-11-04-age-1-modelos-agentes.md`
   - Do: Stage only these 7 paths explicitly with `git add <path>` (never `git add -A` or `git add .`). Commit with `chore: AGE-1 define modelo por agente para reduzir custo de tokens`. After the commit, run `git ls-files --eol .claude/agents/*.md .claude/disabled-agents/*.md README.md docs/en/plans/2026-11-04-age-1-modelos-agentes.md` and confirm `i/lf` for all of them, and `git show --stat HEAD` lists exactly the 7 paths (no `CONVENTIONS.md`, no `2026-11-04-jira-mcp-oauth.md`).
   - Follow pattern: Conventional Commits in Portuguese, as in commit `64cc848 feat: conecta o MCP do Jira (Atlassian) via OAuth`.
   - Done when: `git show --stat HEAD` shows the 7 expected paths and the index stores LF.

8. **[agent-squad] Push and open the PR**
   - Files: none (git/GitHub only)
   - Do: `git push -u origin chore/AGE-1-modelos-agentes`, then `gh pr create --base main --head chore/AGE-1-modelos-agentes` with title `chore: AGE-1 define modelo por agente para reduzir custo de tokens`. The PR body lists the mapping, says orchestrator and planner stay `inherit`, notes that projects that already installed the squad must reinstall with `--force` to get the change, and records the known installer breakage (see Risks) as out of scope. Never push to `main`.
   - Follow pattern: PR #1 (`3ae798b Merge pull request #1 from rafaelsantos01/feat/jira-mcp-oauth`).
   - Done when: `gh pr view` shows an open PR from `chore/AGE-1-modelos-agentes` into `main`.

## Risks
| Risk | Mitigation |
|---|---|
| The analyst on haiku makes mistakes in the layered Atlassian MCP flow (discover / executeRead / executeWrite with `cloudId` as a top-level argument). | Manual post-merge test: the analyst reads AGE-1 via MCP. If it fails, roll back only `.claude/agents/analyst.md:4` to `model: inherit` (Rollback step 1). |
| Line endings get converted to CRLF because `core.autocrlf=true` is on, producing whole-file diffs. | Edit single lines with the Edit tool, check `git diff` in step 6 and `git ls-files --eol` in steps 1 and 7. |
| The uncommitted deletions in the main copy (`CONVENTIONS.md`, `docs/en/plans/2026-11-04-jira-mcp-oauth.md`) end up in the commit. | Work in the worktree, copy only the plan file, stage paths explicitly and check `git show --stat HEAD` in step 7. |
| The `model` parameter passed in an Agent call overrides the frontmatter, and `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` makes the frontmatter ignored, so the savings may not apply. | Documented behavior of Claude Code (https://code.claude.com/docs/en/sub-agents). The manual `/agents` check confirms the frontmatter values; no code change needed. |
| Projects that already installed the squad keep `inherit` until they reinstall. | Note in the PR body that they need to reinstall with `--force` (`-Force` on PowerShell). |
| Known issue, out of scope: `install.sh:13` and `install.ps1:15` list agents that commit `a6c0782` moved to `.claude/disabled-agents/`, so the installers are broken. | Record it in the PR body as a known problem to handle in a separate task. This PR does not touch the installers. |

## Rollback
No data or migrations are involved; rollback is a git-only operation.
1. Analyst only (haiku fails the MCP test): on a new branch from `main`, change `.claude/agents/analyst.md:4` back to `model: inherit` and the analyst cell in the `README.md` table back to `` `inherit` ``, commit `chore: AGE-1 volta o analyst para inherit`, and open a PR to `main`.
2. Before merge: close the PR with `gh pr close chore/AGE-1-modelos-agentes --delete-branch`, then remove the worktree with `git worktree remove <worktree path>`.
3. After merge, full rollback: on a new branch from `main`, run `git revert <merge commit of the PR>` (`-m 1` if it is a merge commit), confirm with `grep -n "^model:" .claude/agents/*.md .claude/disabled-agents/*.md` that all 7 read `model: inherit` and `git ls-files --eol` still shows `i/lf`, push and open a PR to `main`.
4. Projects that already reinstalled with `--force` get the reverted values by reinstalling with `--force` again.

## Verification
- Build/lint: the repo has no build, lint, tests or CI. Validation uses grep, git diff and a manual test.
- Criterion 1: `grep -n "^model:" .claude/agents/*.md .claude/disabled-agents/*.md` matches the mapping (analyst `haiku`; builder, explainer, explorer, documenter `sonnet`; orchestrator, planner `inherit`).
- Criterion 2: `git diff origin/main -- .claude/` shows 5 files, 5 insertions, 5 deletions, only `model:` lines; `git ls-files --eol .claude/agents/*.md .claude/disabled-agents/*.md` shows `i/lf` for all 7.
- Criterion 3: read `README.md:5-13` and check the Modelo column for each of the 7 rows.
- Criterion 4 (post-merge, manual): open `claude` in the repo, run `/agents` and check the models; ask the analyst to read AGE-1 via the Atlassian MCP and confirm it returns the issue title and description.
