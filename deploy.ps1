# kVAI Deploy Script — auto bump cache version and push to GitHub Pages

$swFile = "$PSScriptRoot\sw.js"

# Read current version number
$swContent = Get-Content $swFile -Raw
if ($swContent -match "elec-guide-v(\d+)") {
    $currentVer = [int]$Matches[1]
    $newVer = $currentVer + 1
} else {
    Write-Host "ERROR: Cannot find version in sw.js" -ForegroundColor Red
    exit 1
}

# Bump version in sw.js
$swContent = $swContent -replace "elec-guide-v$currentVer", "elec-guide-v$newVer"
Set-Content $swFile $swContent -Encoding UTF8 -NoNewline

Write-Host "Cache version: v$currentVer -> v$newVer" -ForegroundColor Cyan

# Git add, commit, push
Set-Location $PSScriptRoot
git add index.html sw.js manifest.json das-logo.jpg icon-192.png icon-512.png

$msg = Read-Host "Commit message (or press Enter for default)"
if ([string]::IsNullOrWhiteSpace($msg)) {
    $msg = "update app v$newVer"
}

git commit -m $msg
git push

Write-Host ""
Write-Host "Done! Live at: https://mateesafe.github.io/kvai/" -ForegroundColor Green
Write-Host "GitHub Pages updates in ~2 minutes." -ForegroundColor Yellow
