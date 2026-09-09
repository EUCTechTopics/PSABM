function Connect-ABM {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
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