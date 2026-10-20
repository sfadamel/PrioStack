$dir = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications\_crx_nahgkohigcehdflgljhlfbnnkcdijmed"
$icoItem = Get-ChildItem -Path $dir -Filter "*.ico" | Select-Object -First 1
$md5Item = Get-ChildItem -Path $dir -Filter "*.ico.md5" | Select-Object -First 1

if ($icoItem) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.IO.File]::ReadAllBytes($icoItem.FullName)
    $hashBytes = $md5.ComputeHash($bytes)
    
    if (-not $md5Item) {
        $targetMd5Path = "$($icoItem.FullName).md5"
    } else {
        $targetMd5Path = $md5Item.FullName
    }
    
    [System.IO.File]::WriteAllBytes($targetMd5Path, $hashBytes)
    Write-Host "Updated MD5 for: $($icoItem.FullName)"
}
