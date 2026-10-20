Get-Process | Where-Object { $_.MainWindowTitle -like "*PrioStack*" } | ForEach-Object {
    Write-Host "Found PrioStack window process: $($_.Id) - $($_.ProcessName) - $($_.MainWindowTitle)"
}
