function Get-ABMObject {
    [CmdletBinding(
        SupportsShouldProcess = $False,
        ConfirmImpact = "None",
        SupportsPaging = $False,
        PositionalBinding = $True)
    ]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'byId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'all')]
        # [ValidateSet("orgDevices")]
        [String]
        $ObjectType,

        [Parameter(Mandatory = $true, ParameterSetName = 'byId')]
        [String]
        $Id
    )

    # Initialize empty hashtable
    $Splat = @{}

    # Configure the Url
    $url = "/$ObjectType"

    switch ($PSCmdlet.ParameterSetName) {
        'byId' {
            # Add the ID to the URL
            $url = "$url/$Id"
        }
    }

    # Invoke the API
    $Splat.Add('Url', $url)
    if ($UrlParams) { $Splat.Add('UrlParams', $UrlParams) }
    $response = Invoke-ABMRestMethod @Splat

    # Return the object
    return $response
}