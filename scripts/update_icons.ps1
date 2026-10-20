$icoSource = "D:\Workspace\DamelIT\Antigravity\PrioStack\installer\app_icon.ico"
Write-Host "Source: $icoSource"

# 1. Update ICO files in Google Chrome App directories
$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
if (Test-Path $chromePath) {
    Get-ChildItem -Path $chromePath -Filter "*Prio*.ico" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Updating Chrome icon: $($_.FullName)"
        Copy-Item $icoSource $_.FullName -Force
    }
}

# 2. Update ICO files in Edge
$edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
if (Test-Path $edgePath) {
    Get-ChildItem -Path $edgePath -Filter "*Prio*.ico" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Updating Edge icon: $($_.FullName)"
        Copy-Item $icoSource $_.FullName -Force
    }
}

# 3. Update all PrioStack .lnk shortcuts (Desktop, OneDrive Desktop, Start Menu)
$searchDirs = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\OneDrive\Desktop",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
)

$wscript = New-Object -ComObject WScript.Shell
foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Filter "*Prio*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Found shortcut: $($_.FullName)"
            try {
                $sc = $wscript.CreateShortcut($_.FullName)
                $sc.IconLocation = "$icoSource,0"
                $sc.Save()
                Write-Host "Updated shortcut IconLocation -> $icoSource"
            } catch {
                Write-Host "Error updating shortcut: $_"
            }
        }
    }
}

# 4. Refresh icon cache
try {
    Write-Host "Refreshing Shell..."
    & ie4uinit.exe -show
} catch {}

Write-Host "Done!"
