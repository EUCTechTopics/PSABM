function ConvertTo-Base64 {
    param([byte[]]$bytes)
    return [Convert]::ToBase64String($bytes).TrimEnd('=') -replace '\+', '-' -replace '/', '_'
}