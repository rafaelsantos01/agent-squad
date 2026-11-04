# Instala os agentes do agent-squad em um projeto (.claude\agents) ou globalmente (~\.claude\agents).
#
# Uso:
#   .\install.ps1                # instala no projeto atual
#   .\install.ps1 -Global        # instala em ~\.claude\agents
#   irm https://raw.githubusercontent.com/rafaelsantos01/agent-squad/main/install.ps1 | iex
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
$SrcDir = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot '.claude/agents/orchestrator.md'))) {
    $SrcDir = Join-Path $PSScriptRoot '.claude/agents'
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

Write-Host "Agentes instalados em $Dest"
Write-Host 'Inicie com: claude   (ou: claude --agent orchestrator)'
