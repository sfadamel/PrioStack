$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $rootDir "dist\windows"
$portableDir = Join-Path $distDir "PrioStack_Portable"
$appDir = Join-Path $portableDir "app"
$webBuildDir = Join-Path $rootDir "build\web"
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

Write-Host "1. Preparation du dossier de distribution Windows : $distDir"
if (Test-Path $distDir) {
    Remove-Item -Recurse -Force $distDir
}
New-Item -ItemType Directory -Force -Path $appDir | Out-Null

Write-Host "2. Copie du bundle de production PrioStack dans $appDir"
Copy-Item -Path "$webBuildDir\*" -Destination $appDir -Recurse -Force

Write-Host "3. Compilation de l'executable Windows PrioStack.exe"
$launcherExe = Join-Path $portableDir "PrioStack.exe"
$launcherCs = Join-Path $PSScriptRoot "PrioStackLauncher.cs"
& $csc /target:winexe /out:$launcherExe /r:System.Windows.Forms.dll /r:System.Drawing.dll $launcherCs
if ($LASTEXITCODE -ne 0) {
    throw "Echec de la compilation de PrioStack.exe"
}

Write-Host "4. Creation de l'archive payload.zip pour l'installateur"
$payloadZip = Join-Path $distDir "payload.zip"
Compress-Archive -Path "$portableDir\*" -DestinationPath $payloadZip -Force

Write-Host "5. Compilation de l'installateur autonome PrioStack_Setup_v1.2.exe"
$setupExe = Join-Path $distDir "PrioStack_Setup_v1.2.exe"
$installerCs = Join-Path $PSScriptRoot "PrioStackInstaller.cs"
& $csc /target:winexe /out:$setupExe /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /resource:"$payloadZip,payload.zip" $installerCs
if ($LASTEXITCODE -ne 0) {
    throw "Echec de la compilation de PrioStack_Setup_v1.2.exe"
}

Remove-Item -Force $payloadZip

Write-Host "=== Generation terminee avec succes ! ==="
Get-ChildItem $distDir -Recurse -Filter "*.exe" | Select-Object FullName, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}
