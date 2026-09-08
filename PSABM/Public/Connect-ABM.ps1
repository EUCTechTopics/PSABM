function Connect-ABM {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
    [CmdletBinding(
        SupportsShouldProcess = $False,
        ConfirmImpact = "None",
        SupportsPaging = $False,
        PositionalBinding = $True)
    ]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Business Manager", "School Manager")]
        [String] $Environment = "Business Manager",

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [String] $KeyPath,

        [Parameter(Mandatory = $true)]
        [String] $ClientId,

        [Parameter(Mandatory = $true)]
        [String] $KeyId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1")]
        [String] $APIVersion = 'v1'
    )

    $Parameters = @{
        Environment         = $Environment
        KeyPath             = $KeyPath
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