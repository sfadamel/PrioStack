$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot
$distDir = Join-Path $repoDir "dist\damel-it"
$targetFolder = Join-Path $distDir "priostack"
$zipPath = Join-Path $distDir "priostack_damel_it.zip"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Compilation et Packaging PrioStack pour www.damel-it.com" -ForegroundColor Cyan
Write-Host " Sous-dossier cible : https://www.damel-it.com/priostack/" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Compilation Flutter Web avec base-href /priostack/
Write-Host "`n1. Compilation Flutter Web (base-href: /priostack/)..." -ForegroundColor Yellow
flutter build web --release --base-href "/priostack/"

$webBuildDir = Join-Path $repoDir "build\web"

# 2. Préparation du dossier de distribution
Write-Host "`n2. Préparation du dossier dist\damel-it\priostack..." -ForegroundColor Yellow
if (Test-Path $targetFolder) {
    Remove-Item -Recurse -Force $targetFolder
}
New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null

Copy-Item -Path "$webBuildDir\*" -Destination $targetFolder -Recurse -Force

# 3. Création du fichier .htaccess pour Apache / Plesk
Write-Host "`n3. Génération du fichier .htaccess pour le routage SPA sur Plesk..." -ForegroundColor Yellow
$htaccessContent = @"
# ----------------------------------------------------------------------
# Configuration PrioStack Flutter Web sur Plesk / Apache
# Sous-dossier : /priostack/
# ----------------------------------------------------------------------

<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /priostack/
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /priostack/index.html [L]
</IfModule>

<IfModule mod_mime.c>
  AddType application/javascript .js
  AddType application/wasm .wasm
  AddType application/json .json
</IfModule>

<IfModule mod_headers.c>
  Header set X-Content-Type-Options "nosniff"
</IfModule>
"@

$htaccessPath = Join-Path $targetFolder ".htaccess"
[System.IO.File]::WriteAllText($htaccessPath, $htaccessContent, [System.Text.Encoding]::UTF8)

# 4. Création de l'archive ZIP prête à être téléversée sur Plesk
Write-Host "`n4. Compression en archive ZIP : $zipPath..." -ForegroundColor Yellow
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path "$targetFolder\*" -DestinationPath $zipPath -CompressionLevel Optimal

# 5. Recompilation pour l'environnement de dev local (base-href /)
Write-Host "`n5. Recompilation du build web local de dev (base-href: /)..." -ForegroundColor Yellow
flutter build web --release

$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "✅ SUCCÈS : Package prêt pour www.damel-it.com !" -ForegroundColor Green
Write-Host "Dossier prêt : $targetFolder" -ForegroundColor Green
Write-Host ("Archive ZIP  : {0} ({1:N2} Mo)" -f $zipPath, $zipSize) -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
