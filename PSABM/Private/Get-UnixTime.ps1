function Get-UnixTime {
    param([datetime]$dt = $(Get-Date))
    return [int](($dt.ToUniversalTime() - [datetime]'1970-01-01T00:00:00Z').TotalSeconds)
}