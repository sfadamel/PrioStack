$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot
$repoUrl = "https://github.com/sfadamel/PrioStack.git"

Write-Host "1. Compilation de la version Web pour GitHub Pages (base-href: /PrioStack/)" -ForegroundColor Cyan
flutter build web --release --base-href "/PrioStack/"

$webDir = Join-Path $repoDir "build\web"
Copy-Item "$webDir\index.html" "$webDir\404.html" -Force
# Fichier .nojekyll pour empêcher Jekyll de bloquer les fichiers commençant par un underscore ou les polices
New-Item -ItemType File -Path "$webDir\.nojekyll" -Force | Out-Null

Write-Host "2. Publication sur la branche gh-pages" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "priostack_gh_pages"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

Copy-Item -Path "$webDir\*" -Destination $tempDir -Recurse -Force
Copy-Item -Path "$webDir\.nojekyll" -Destination $tempDir -Force

$currentDir = Get-Location
try {
    Set-Location $tempDir
    git init
    git checkout -b gh-pages
    git add .
    git commit -m "deploy: publish PrioStack Web to GitHub Pages"
    git remote add origin $repoUrl
    git push -f origin gh-pages
    Write-Host "✅ Branche gh-pages mise à jour et poussée sur GitHub !" -ForegroundColor Green
} finally {
    Set-Location $currentDir
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

Write-Host "3. Recompilation de la version Web locale (base-href: /)" -ForegroundColor Cyan
flutter build web --release
Write-Host "✅ Prêt !" -ForegroundColor Green
