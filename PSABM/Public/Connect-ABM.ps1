<#
.SYNOPSIS
    Connects to the Apple Business Manager or Apple School Manager API.

.DESCRIPTION
    Authenticates and initializes a session with the Apple Business Manager or Apple School Manager API using API credentials.
    The function supports supplying the private key either directly as a string or via a local file path.

.PARAMETER Environment
    Specifies the target Apple portal environment. Valid values are 'Business Manager' and 'School Manager'.
    Default is 'Business Manager'.

.PARAMETER KeyPath
    The file path to the private key file used for authentication.

.PARAMETER Key
    The raw string content of the private key used for authentication.

.PARAMETER ClientId
    The Client ID provided by Apple.

.PARAMETER KeyId
    The Key ID associated with the private key in Apple Business/School Manager.

.PARAMETER APIVersion
    The API version to target. Default is 'v1'.

.EXAMPLE
    Connect-ABM -KeyPath 'C:\Keys\AuthKey.pem' -ClientId '12345678-abcd-1234-abcd-1234567890ab' -KeyId 'ABC123XYZ'

    Connects to Apple Business Manager using a private key file.

.EXAMPLE
    Connect-ABM -Environment 'School Manager' -Key $PrivateKeyContent -ClientId '12345678-abcd-1234-abcd-1234567890ab' -KeyId 'ABC123XYZ'

    Connects to Apple School Manager using a private key string variable.
#>
function Connect-ABM {
    [CmdletBinding(
        SupportsShouldProcess = $False,
        ConfirmImpact = "None",
        SupportsPaging = $False,
        PositionalBinding = $True)
    ]
    param (
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'Key')]
        [ValidateSet("Business Manager", "School Manager")]
        [String] $Environment = "Business Manager",

        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path $_ })]
        [String] $KeyPath,

        [Parameter(Mandatory, ParameterSetName = 'Key')]
        [String] $Key,

        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [Parameter(Mandatory, ParameterSetName = 'Key')]
        [String] $ClientId,

        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [Parameter(Mandatory, ParameterSetName = 'Key')]
        [String] $KeyId,

        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'Key')]
        [ValidateSet("v1")]
        [String] $APIVersion = 'v1'
    )

    if($PSCmdlet.ParameterSetName -eq 'Path') {
        $Key = Get-Content -Raw -Path $KeyPath
    }

    $Parameters = @{
        Environment         = $Environment
        Key                 = $Key
        APIVersion          = $APIVersion
        KeyId               = $KeyId
        ClientId            = $ClientId
    }

    $script:ABMEnv = Get-ABMEnvironment @Parameters

    # Concatenate full version string with prerelease label if present
    if ($MyInvocation.MyCommand.Module -and
        $MyInvocation.MyCommand.Module.PrivateData -and
        $MyInvocation.MyCommand.Module.PrivateData.PSData) {
        $PrereleaseLabel = $MyInvocation.MyCommand.Module.PrivateData.PSData['Prerelease']
    }
    else {
        $PrereleaseLabel = $null
    }
    $ModuleVersion = $MyInvocation.MyCommand.Module.Version
    if (-not [string]::isNullOrEmpty($PrereleaseLabel)) {
        $VersionString = ("{0}-{1}" -f $ModuleVersion, $PrereleaseLabel)
    }
    else {
        $VersionString = $ModuleVersion
    }
    # Build formatted output using a here-string for alignment
    $ABMInfo = @"

=========================================
        Connected to Apple
=========================================

Environment:          Apple $Environment
Client ID:            $($script:ABMEnv.ClientId)
Key ID:               $($script:ABMEnv.KeyId)
Base URL:             $($script:ABMEnv.BaseURL)
API Version:          $($script:ABMEnv.APIVersion)
Token Expires:        $($script:ABMEnv.ExpiryDateTime)

"@

    # Write the formatted output
    Write-Output $ABMInfo

}