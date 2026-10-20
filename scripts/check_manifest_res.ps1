$folder = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications\Manifest Resources\nahgkohigcehdflgljhlfbnnkcdijmed"
Get-ChildItem -Path $folder -Recurse | ForEach-Object {
    Write-Host "$($_.FullName)"
}
