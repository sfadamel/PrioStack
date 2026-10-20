$expCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
Get-ChildItem -Path $expCache -Filter "iconcache*" | ForEach-Object {
    Write-Host "$($_.Name) - $($_.Length)"
}
