function Disconnect-ABM {

    if (-not $script:ABMEnv) {
        throw "Not connected to ABM."
    } else {
        Write-Output ('Disconnecting from ABM') | Out-Null
        $script:ABMEnv = $null
    }

}