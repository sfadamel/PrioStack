$webApps = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
Get-ChildItem -Path $webApps -Recurse | ForEach-Object {
    Write-Host "$($_.FullName)"
}
