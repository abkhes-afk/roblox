# Script pour lancer le serveur + tunnel automatiquement
# Usage: .> start-tunnel.ps1

Write-Host "=== Lancement du serveur de trade ===" -ForegroundColor Cyan

# 1. Tuer les anciens processus node
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 1

# 2. Lancer le serveur Node.js
$server = Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru
Write-Host "[OK] Serveur local demarre sur le port 3000" -ForegroundColor Green

Start-Sleep 3

# 3. Lancer tunnelmole et capturer l'URL
Write-Host "[...] Creation du tunnel public via tunnelmole..." -ForegroundColor Yellow
$tunnelLog = Join-Path $PSScriptRoot "tunnel_log.txt"
$tunnelErr = Join-Path $PSScriptRoot "tunnel_err.txt"
$tunnel = Start-Process -FilePath "npx" -ArgumentList "tunnelmole", "3000" -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -RedirectStandardOutput $tunnelLog -RedirectStandardError $tunnelErr -PassThru

# Attendre que tunnelmole genere l'URL
Start-Sleep 8

# Lire l'URL du log
$url = $null
$maxWait = 20
$waited = 0
while (-not $url -and $waited -lt $maxWait) {
    if (Test-Path $tunnelLog) {
        $content = Get-Content $tunnelLog -Raw -ErrorAction SilentlyContinue
        if ($content -match "(http://[\w\-\.]+\.tunnelmole\.net)") {
            $url = $matches[1]
        }
    }
    if (-not $url) {
        Start-Sleep 1
        $waited++
    }
}

if (-not $url) {
    Write-Host "[ERREUR] Impossible de recuperer l'URL du tunnel." -ForegroundColor Red
    Write-Host "Verifie tunnel_log.txt pour plus de details." -ForegroundColor Red
    return
}

# Convertir http:// en ws:// pour le script Lua
$wsUrl = $url -replace "^http://", "ws://"

Write-Host "[OK] Tunnel public actif: $url" -ForegroundColor Green
Write-Host "[OK] WebSocket URL: $wsUrl" -ForegroundColor Green

# 4. Mettre a jour fake_trade.lua avec la nouvelle URL
$luaFile = Join-Path $PSScriptRoot "fake_trade.lua"
if (Test-Path $luaFile) {
    $luaContent = Get-Content $luaFile -Raw
    # Remplacer l'ancienne URL tunnelmole par la nouvelle
    $luaContent = $luaContent -replace 'ws://[\w\-]+\.tunnelmole\.net', $wsUrl
    Set-Content -Path $luaFile -Value $luaContent -NoNewline
    Write-Host "[OK] fake_trade.lua mis a jour avec la nouvelle URL" -ForegroundColor Green
} else {
    Write-Host "[AVERTISSEMENT] fake_trade.lua non trouve. Mets a jour manuellement:" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== INSTRUCTIONS ===" -ForegroundColor Cyan
Write-Host "1. Copie cette URL dans ton executor Roblox:" -ForegroundColor White
Write-Host "   _G.TRADE_SERVER_URL = `"$wsUrl`"" -ForegroundColor Magenta
Write-Host ""
Write-Host "2. Execute fake_trade.lua dans Roblox" -ForegroundColor White
Write-Host "3. Ouvre le panel dans ton navigateur:" -ForegroundColor White
Write-Host "   $url" -ForegroundColor Magenta
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arreter le tunnel." -ForegroundColor Gray

# Garder le script ouvert
while ($true) {
    Start-Sleep 5
    # Verifier si le serveur tourne encore
    if ($server.HasExited) {
        Write-Host "[INFO] Le serveur local s'est arrete." -ForegroundColor Yellow
        break
    }
}
