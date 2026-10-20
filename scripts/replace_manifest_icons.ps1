Add-Type -AssemblyName System.Drawing

$srcPath = "D:\Workspace\DamelIT\Antigravity\PrioStack\web\icons\Icon-512.png"
$srcImg = [System.Drawing.Image]::FromFile($srcPath)

$targetDir = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications\Manifest Resources\nahgkohigcehdflgljhlfbnnkcdijmed"

function Resize-And-Save($destPath, $size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($srcImg, 0, 0, $size, $size)
    $g.Dispose()
    
    $parent = Split-Path $destPath
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    
    # Save to temp and move to overwrite safely
    $tempPath = "$destPath.tmp.png"
    $bmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    
    Move-Item -Path $tempPath -Destination $destPath -Force
    Write-Host "Updated ($size x $size): $destPath"
}

# Find all existing png files in the targetDir
Get-ChildItem -Path $targetDir -Filter "*.png" -Recurse | ForEach-Object {
    $name = $_.BaseName
    if ($name -match '^\d+$') {
        $size = [int]$name
        Resize-And-Save $_.FullName $size
    } else {
        Resize-And-Save $_.FullName 512
    }
}

$srcImg.Dispose()
Write-Host "Manifest Resources successfully refreshed with new PrioStack logo!"
