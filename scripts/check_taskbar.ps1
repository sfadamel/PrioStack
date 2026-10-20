$taskbarDir = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
if (Test-Path $taskbarDir) {
    Write-Host "Taskbar directory exists."
    Get-ChildItem -Path $taskbarDir | ForEach-Object {
        Write-Host "Pinned: $($_.Name)"
    }
}
