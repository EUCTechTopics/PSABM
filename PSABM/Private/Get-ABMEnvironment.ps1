function Get-ABMEnvironment {
    [CmdletBinding(
        SupportsShouldProcess = $False,
        ConfirmImpact = "None",
        SupportsPaging = $False,
        PositionalBinding = $True)
    ]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Business Manager", "School Manager")]
        [String]
        $Environment,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $KeyPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1")]
        [String]
        $APIVersion = "v1"
    )

    switch ($Environment) {
        "Business Manager" {
            $Instance = "ABM"
            $Scope = "business.api"
            $BaseUrl = "https://api-business.apple.com"
        }
        "School Manager" {
            $Instance = "ASM"
            $Scope = "school.api"
            $BaseUrl = "https://api-school.apple.com"
        }
    }

    # Set client_id, key_id needed to get JWT
    $client_id = Get-ABMSecret -Name "$($Instance)-CLIENT-ID" -AsPlainText
    $key_id = Get-ABMSecret -Name "$($Instance)-KEY-ID" -AsPlainText

    # Get JWT
    $client_assertion = Get-ABMJWT -ClientId $client_id -KeyId $key_id -KeyPath $KeyPath

    $sessiontokendata = @{
        tokenUrl        = "https://account.apple.com/auth/oauth2/token"
        clientId         = $client_id
        jwt              = $client_assertion
        scope            = $Scope
    }

    $SessionToken = Get-ABMSessionToken @sessiontokendata

    $output = [PSCustomObject]@{
        Instance            = $Instance
        ClientId            = $client_id
        KeyId               = $key_id
        BaseUrl             = $BaseUrl
        BaseAPIUrl          = ('{0}/{1}' -f $BaseUrl, $APIVersion)
        SessionToken        = $SessionToken.access_token
        ExpiryDateTime     = (Get-Date).AddSeconds($SessionToken.expires_in)
        APIVersion          = $APIVersion
    }

    return $output
}