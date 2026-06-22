# kVAI Auto-Deploy Watcher
# Run once — saves to index.html will auto-deploy after 15 seconds

$watchFiles      = @("index.html", "sw.js", "manifest.json", "das-logo.jpg")
$debounceSeconds = 15

# Record initial file timestamps
$timestamps = @{}
foreach ($f in $watchFiles) {
    $p = Join-Path $PSScriptRoot $f
    if (Test-Path $p) { $timestamps[$f] = (Get-Item $p).LastWriteTime }
}

$pendingDeploy  = $false
$lastChangeTime = $null

Write-Host ""
Write-Host "  kVAI Auto-Deploy Watcher" -ForegroundColor Cyan
Write-Host "  Watching: $($watchFiles -join ', ')" -ForegroundColor DarkGray
Write-Host "  Deploys $debounceSeconds sec after last save. Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

while ($true) {

    # ── Detect file changes ──
    foreach ($f in $watchFiles) {
        $p = Join-Path $PSScriptRoot $f
        if (-not (Test-Path $p)) { continue }
        $t = (Get-Item $p).LastWriteTime
        if ($timestamps[$f] -ne $t) {
            $timestamps[$f] = $t
            if (-not $pendingDeploy) {
                Write-Host "  [$((Get-Date).ToString('HH:mm:ss'))]  $f changed — deploying in ${debounceSeconds}s..." -ForegroundColor Yellow
            }
            $pendingDeploy  = $true
            $lastChangeTime = Get-Date
        }
    }

    # ── Deploy when debounce timer expires ──
    if ($pendingDeploy -and ((Get-Date) - $lastChangeTime).TotalSeconds -ge $debounceSeconds) {
        $pendingDeploy = $false
        Write-Host ""
        Write-Host "  [$((Get-Date).ToString('HH:mm:ss'))]  Deploying..." -ForegroundColor Cyan

        # Bump cache version in sw.js
        $swPath    = Join-Path $PSScriptRoot "sw.js"
        $swContent = Get-Content $swPath -Raw
        if ($swContent -match "elec-guide-v(\d+)") {
            $oldVer    = [int]$Matches[1]
            $newVer    = $oldVer + 1
            $swContent = $swContent -replace "elec-guide-v$oldVer", "elec-guide-v$newVer"
            Set-Content $swPath $swContent -Encoding UTF8 -NoNewline
            $timestamps["sw.js"] = (Get-Item $swPath).LastWriteTime
            Write-Host "  Cache v$oldVer -> v$newVer" -ForegroundColor DarkGray
        }

        # Git commit and push
        Set-Location $PSScriptRoot
        $msg = "auto-deploy $((Get-Date).ToString('yyyy-MM-dd HH:mm'))"
        git add index.html sw.js manifest.json das-logo.jpg icon-192.png icon-512.png 2>$null
        $result = git commit -m $msg 2>&1
        if ($LASTEXITCODE -eq 0) {
            git push 2>&1 | Out-Null
            Write-Host "  Done! Live at https://mateesafe.github.io/kvai/ (~2 min)" -ForegroundColor Green
        } else {
            Write-Host "  No changes to deploy." -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Start-Sleep -Seconds 2
}
