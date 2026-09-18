<#
    Runs a source-to-pptx script in whichever environment is available.

    Resolution order:
      1. Docker image source-to-pptx:latest (built from assets/docker on first use)
      2. .venv in the work directory
      3. host python that can already import the dependencies

    Usage:
        scripts\run.ps1 <work-dir> <script.py> [args...]
        scripts\run.ps1 -Probe <work-dir>        # report what is available, run nothing

    Exit code 3 means Docker is installed but its daemon is not responding: ask the
    user whether to start Docker Desktop or continue with a local Python instead of
    silently picking one, then re-run with -NoDocker if they choose local.
#>
param(
    [switch]$Probe,
    [switch]$NoDocker,
    [Parameter(Position = 0)][string]$WorkDir,
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = 'Stop'
$skill = Split-Path -Parent $PSScriptRoot
$image = 'source-to-pptx:latest'

function Test-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return 'absent' }
    docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -eq 0) { return 'running' }
    return 'stopped'
}

function Get-HostPython {
    foreach ($cand in @('python', 'python3', 'py')) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        # the Windows Store stub resolves but cannot run anything
        & $cand -c "import sys" *> $null
        if ($LASTEXITCODE -eq 0) { return $cmd.Source }
    }
    return $null
}

$docker = if ($NoDocker) { 'skipped' } else { Test-Docker }

if ($Probe) {
    [pscustomobject]@{
        docker     = $docker
        venv       = if ($WorkDir -and (Test-Path (Join-Path $WorkDir '.venv/Scripts/python.exe'))) { 'present' } else { 'absent' }
        hostPython = if (Get-HostPython) { 'present' } else { 'absent' }
        skill      = $skill
    } | ConvertTo-Json -Compress
    exit 0
}

if (-not $WorkDir) { throw "usage: run.ps1 <work-dir> <script.py> [args...]" }
if (-not $Rest)    { throw "no script given" }
$WorkDir = (Resolve-Path $WorkDir).Path

if ($docker -eq 'stopped') {
    Write-Host "Docker is installed but the daemon is not responding." -ForegroundColor Yellow
    Write-Host "Start Docker Desktop, or re-run with -NoDocker to use a local Python environment."
    exit 3
}

if ($docker -eq 'running') {
    if (-not (docker images -q $image)) {
        Write-Host "Building $image (first use) ..." -ForegroundColor Cyan
        docker build -t $image (Join-Path $skill 'assets/docker')
        if ($LASTEXITCODE -ne 0) { throw "docker build failed" }
    }
    # NB: do not call this $args -- that is an automatic variable in PowerShell
    # and assigning to it silently mangles the splat.
    $script = $Rest[0]
    $scriptArgs = @(if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() })
    docker run --rm `
        -v "$($WorkDir):/work" `
        -v "$($skill):/skill:ro" `
        -v "C:\Windows\Fonts:/winfonts:ro" `
        -e PAGE2PPTX_SKILL=/skill `
        $image python "/skill/scripts/$script" @scriptArgs
    exit $LASTEXITCODE
}

# --- local python -----------------------------------------------------------
$venv = Join-Path $WorkDir '.venv/Scripts/python.exe'
if (-not (Test-Path $venv)) {
    $py = Get-HostPython
    if (-not $py) {
        throw "No Docker and no usable Python found. Install Python 3.11+ or start Docker Desktop."
    }
    Write-Host "Creating $venv ..." -ForegroundColor Cyan
    & $py -m venv (Join-Path $WorkDir '.venv')
    & $venv -m pip install --quiet --upgrade pip
    & $venv -m pip install --quiet -r (Join-Path $skill 'assets/docker/requirements.txt')
    Write-Host "Note: potrace is not installed locally; tracing needs Docker or a potrace binary on PATH." -ForegroundColor Yellow
}
$env:PAGE2PPTX_SKILL = $skill
$scriptArgs = @(if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() })
& $venv (Join-Path $skill "scripts/$($Rest[0])") @scriptArgs
exit $LASTEXITCODE
