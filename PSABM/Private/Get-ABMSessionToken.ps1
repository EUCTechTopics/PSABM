function Get-ABMSessionToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$tokenUrl,

        [Parameter(Mandatory = $true)]
        [string]$clientId,

        [Parameter(Mandatory = $true)]
        [string]$jwt,

        [Parameter(Mandatory = $true)]
        [string]$scope
    )

    $query = @{
        grant_type            = "client_credentials"
        client_id             = $clientId
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        client_assertion      = $jwt
        scope                 = $scope
    }

    try {
        Write-Verbose ('Retrieving session token from {0}' -f $tokenUrl)

        # Create an array of key=value pairs, escaped
        $queryParams = $query.GetEnumerator() | ForEach-Object {
            "$($_.Key)=$([uri]::EscapeDataString($_.Value))"
        }

        # Join array elements into query string
        $queryString = $queryParams -join "&"

        # Construct the full URI with query string
        $uri = "{0}?{1}" -f $tokenUrl, $queryString

        # Perform POST request
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }

        # Convert the token to a SecureString without -AsPlainText
        $secureToken = New-Object -TypeName System.Security.SecureString
        $response.access_token.ToCharArray() | ForEach-Object { $secureToken.AppendChar($_) }
        $secureToken.MakeReadOnly()

        # Set output object
        $secureToken = [PSCustomObject]@{
            access_token = $secureToken
            expires_in   = $response.expires_in
        }

        # Securely remove plaintext token from memory
        Remove-Variable -Name response -Force -ErrorAction SilentlyContinue
    }

    catch {
        Write-Debug ('Error retrieving session token for ABM from {0}' -f $token_url)
        throw $_
    }

    return $secureToken
}