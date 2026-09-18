<#
    Render a built deck back to PNGs, one per slide, for the review loop.

        scripts\render.ps1 build\deck.pptx -Out work\review [-Width 1536]

    PowerPoint via COM is preferred: it is the renderer the file will actually be
    opened in, and a successful Open also proves the package is valid (a deck
    PowerPoint would offer to "repair" fails here instead of silently looking
    fine). LibreOffice is the fallback where PowerPoint is not installed; it is
    close enough for geometry, less exact on text.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Deck,
    [string]$Out = "work/review",
    [int]$Width = 1536,
    [switch]$NoPowerPoint
)

$ErrorActionPreference = 'Stop'
$deckPath = (Resolve-Path $Deck).Path
$outDir = (New-Item -ItemType Directory -Force -Path $Out).FullName

function Get-SlideSize($path) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
    try {
        $entry = $zip.GetEntry('ppt/presentation.xml')
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $xml = $reader.ReadToEnd()
        $reader.Close()
    }
    finally { $zip.Dispose() }
    if ($xml -match 'sldSz[^/]*cx="(\d+)"[^/]*cy="(\d+)"') {
        return @([int]$Matches[1], [int]$Matches[2])
    }
    return @(12192000, 6858000)
}

$size = Get-SlideSize $deckPath
$height = [int][math]::Round($Width * $size[1] / $size[0])

$ppt = $null
if (-not $NoPowerPoint) {
    try { $ppt = New-Object -ComObject PowerPoint.Application } catch { $ppt = $null }
}

if ($ppt) {
    try {
        # ReadOnly, Untitled, WithWindow
        $pres = $ppt.Presentations.Open($deckPath, -1, 0, 0)
        try {
            for ($i = 1; $i -le $pres.Slides.Count; $i++) {
                $target = Join-Path $outDir ("slide-{0:d2}.png" -f $i)
                if (Test-Path $target) { Remove-Item $target -Force }
                $pres.Slides.Item($i).Export($target, "PNG", $Width, $height)
                Write-Host "rendered $target ($Width x $height)"
            }
        }
        finally { $pres.Close() }
    }
    finally {
        $ppt.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null
    }
    exit 0
}

$soffice = Get-Command soffice -ErrorAction SilentlyContinue
if (-not $soffice) {
    throw ("Neither PowerPoint nor LibreOffice is available to render the deck. " +
           "Install LibreOffice, or open $Deck by hand to check it.")
}
Write-Host "PowerPoint not available; rendering with LibreOffice (less exact on text)."
& $soffice.Source --headless --convert-to pdf --outdir $outDir $deckPath | Out-Null
$pdf = Join-Path $outDir ([IO.Path]::GetFileNameWithoutExtension($deckPath) + ".pdf")
if (-not (Test-Path $pdf)) { throw "LibreOffice produced no PDF" }
Write-Host "wrote $pdf -- rasterise it with: run.ps1 <work> ingest.py $pdf --out $Out"
