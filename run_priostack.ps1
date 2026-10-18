$ErrorActionPreference = "Continue"
$LogDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
$LogFile = Join-Path $LogDir "flutter_debug.log"

Write-Host "=== Lancement de PrioStack avec journalisation automatique dans $LogFile ===" -ForegroundColor Cyan
"=== Session PrioStack démarrée le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $LogFile -Encoding utf8

# Lancement via web-server en mode release sur le port 8090 (rapide, multi-onglets et sans blocage DWDS)
flutter run -d web-server --release --web-port 8090 2>&1 | Tee-Object -FilePath $LogFile -Append
