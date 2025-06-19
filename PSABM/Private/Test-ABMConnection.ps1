function Test-ABMConnection {

    # Check if connected to ABM
    if (-not $script:ABMEnv) {
        throw "Not connected to Apple Business Manager, please use Connect-ABM first"
    }

    # Check if token has expired
    if (-not ($script:ABMEnv.expiryDateTime -gt (Get-Date))) {
        throw "Access Token has expired, please use Connect-ABM to reconnect"
    }

}