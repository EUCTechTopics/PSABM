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
        [String] $KeyPath,

        [Parameter(Mandatory = $true)]
        [String] $ClientId,

        [Parameter(Mandatory = $true)]
        [String] $KeyId,

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

    # Get JWT
    $client_assertion = Get-ABMJWT -ClientId $ClientId -KeyId $KeyId -KeyPath $KeyPath

    $sessiontokendata = @{
        tokenUrl        = "https://account.apple.com/auth/oauth2/token"
        clientId         = $ClientId
        jwt              = $client_assertion
        scope            = $Scope
    }

    $SessionToken = Get-ABMSessionToken @sessiontokendata

    $output = [PSCustomObject]@{
        Instance            = $Instance
        ClientId            = $ClientId
        KeyId               = $KeyId
        BaseUrl             = $BaseUrl
        BaseAPIUrl          = ('{0}/{1}' -f $BaseUrl, $APIVersion)
        SessionToken        = $SessionToken.access_token
        ExpiryDateTime     = (Get-Date).AddSeconds($SessionToken.expires_in)
        APIVersion          = $APIVersion
    }

    return $output
}