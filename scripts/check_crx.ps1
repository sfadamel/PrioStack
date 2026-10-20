$folder = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications\_crx_nahgkohigcehdflgljhlfbnnkcdijmed"
if (Test-Path $folder) {
    Get-ChildItem -Path $folder -Recurse | ForEach-Object {
        Write-Host "$($_.FullName) (Length: $($_.Length), LastWrite: $($_.LastWriteTime))"
    }
}
