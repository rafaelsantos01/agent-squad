# Instala os agentes do agent-squad em um projeto (.claude\agents) ou globalmente (~\.claude\agents).
#
# Uso:
#   .\install.ps1                # instala no projeto atual
#   .\install.ps1 -Global        # instala em ~\.claude\agents
#   irm https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main/install.ps1 | iex
# Tambem copia o .mcp.json (MCP do Jira via OAuth) para a raiz do projeto. -Force substitui o .mcp.json inteiro.
param(
    [switch]$Global,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRaw = if ($env:AGENT_SQUAD_RAW) { $env:AGENT_SQUAD_RAW } else { 'https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main' }
$Agents = @('orchestrator', 'explorer', 'planner', 'analyst', 'builder', 'documenter', 'explainer')

if ($Global) { $Base = Join-Path $HOME '.claude' } else { $Base = Join-Path (Get-Location) '.claude' }
$Dest = Join-Path $Base 'agents'
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# Se rodando de um clone local, copia; senão baixa do GitHub.
$RootDir = $null
$SrcDir = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot '.claude/agents/orchestrator.md'))) {
    $RootDir = $PSScriptRoot
    $SrcDir = Join-Path $RootDir '.claude/agents'
}

foreach ($name in $Agents) {
    $target = Join-Path $Dest "$name.md"
    if ((Test-Path $target) -and -not $Force) {
        Write-Host "  = $name.md ja existe (use -Force para sobrescrever)"
        continue
    }
    if ($SrcDir) {
        Copy-Item (Join-Path $SrcDir "$name.md") $target -Force
    } else {
        Invoke-WebRequest -UseBasicParsing "$RepoRaw/.claude/agents/$name.md" -OutFile $target
    }
    Write-Host "  + $name.md"
}

# Faz o orquestrador ser o agente principal da sessao no projeto.
if (-not $Global) {
    $Settings = Join-Path $Base 'settings.json'
    if (-not (Test-Path $Settings)) {
        [System.IO.File]::WriteAllText($Settings, "{`n  `"agent`": `"orchestrator`"`n}`n")
        Write-Host '  + settings.json (agent: orchestrator)'
    } elseif (-not (Select-String -Path $Settings -Pattern '"agent"' -Quiet)) {
        Write-Host "  ! $Settings ja existe: adicione `"agent`": `"orchestrator`" manualmente"
    }
}

# Conecta o MCP do Jira (Atlassian, OAuth) no projeto.
if ($Global) {
    Write-Host '  i modo global: o .mcp.json nao e copiado. Para usar o Jira em todos os projetos:'
    Write-Host '    claude mcp add --scope user --transport http atlassian https://mcp.atlassian.com/v2/mcp'
} else {
    $McpTarget = Join-Path (Get-Location) '.mcp.json'
    if ((Test-Path $McpTarget) -and -not $Force) {
        Write-Host '  ! .mcp.json ja existe: mescle manualmente o servidor atlassian'
        Write-Host '    (dentro de "mcpServers")'
        Write-Host @'
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v2/mcp"
    }
'@
    } else {
        if ($RootDir) {
            Copy-Item (Join-Path $RootDir '.mcp.json') $McpTarget -Force
        } else {
            Invoke-WebRequest -UseBasicParsing "$RepoRaw/.mcp.json" -OutFile $McpTarget
        }
        Write-Host '  + .mcp.json (MCP atlassian; autentique com /mcp)'
    }
}

Write-Host "Agentes instalados em $Dest"
Write-Host 'Inicie com: claude   (ou: claude --agent orchestrator)'
