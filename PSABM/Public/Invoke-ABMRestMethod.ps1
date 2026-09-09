<#
    .SYNOPSIS
        Invoke the ABM REST API.

    .DESCRIPTION
        This function is used to invoke a REST method to the ABM API. It will handle pagination and retries.

    .PARAMETER Url
        The relative URL to call.

    .PARAMETER Method
        The HTTP method to use.

    .PARAMETER Body
        The body of the request.

    .PARAMETER ContentType
        The content type of the request.

    .PARAMETER MaxRetries
        The maximum number of retries to attempt.

    .PARAMETER PauseDuration
        The duration to pause between retries.

    .EXAMPLE
        Invoke-ABMRestMethod -Url '/orgDevices' -Method 'GET'

    .INPUTS
        None

    .OUTPUTS
        System.Object[]
#>

function Invoke-ABMRestMethod {
    [CmdletBinding(
        SupportsShouldProcess = $False,
        ConfirmImpact = "None",
        SupportsPaging = $False,
        PositionalBinding = $True)
    ]
    param (
        [Parameter(Mandatory = $true)]
        [String] $Url,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "PATCH", "POST", "PUT", "DELETE")]
        [String] $Method = "GET",

        [Parameter(Mandatory = $false)]
        [String] $Body,

        [Parameter(Mandatory = $false)]
        [String] $ContentType = "application/json",

        [Parameter(Mandatory = $false)]
        [Int] $MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [Int] $PauseDuration = 2
    )

    Test-ABMConnection

    $CurrentUrl = "{0}{1}" -f $script:ABMEnv.BaseAPIUrl, $Url

    $Token = ConvertFrom-SecureString $script:ABMEnv.SessionToken -AsPlainText
    $Headers = @{
        Authorization = "Bearer $Token"
    }
    Remove-Variable -Name Token -Force

    # Add application/json-patch+json content-type for PATCH requests
    if ($Method -eq "PATCH") {
        $ContentType = "application/json-patch+json"
    }

    # Loop through pages and stream results directly to pipeline
    while ($CurrentUrl) {
        $RetryCount = 0
        $PageSuccess = $false

        while (-not $PageSuccess) {
            try {
                $Splat = @{
                    Uri             = $CurrentUrl
                    Headers         = $Headers
                    Method          = $Method
                    ContentType     = $ContentType
                }
                if ($Body) { $Splat.Add('Body', $Body) }

                # Directly returns deserialized JSON objects
                $Results = Invoke-RestMethod @Splat -Verbose:$false -Debug:$false

                # Stream results to pipeline immediately
                if ($null -ne $Results.data) {
                    $Results.data
                } else {
                    $Results
                }

                # Evaluate JSON:API pagination link
                if ($Method -eq "GET" -and $Results.links -and $Results.links.next) {
                    $NextLink = $Results.links.next
                    $CurrentUrl = if ($NextLink -like "http*") { $NextLink } else { "{0}{1}" -f $script:ABMEnv.BaseAPIUrl, $NextLink }
                } else {
                    $CurrentUrl = $null
                }

                $PageSuccess = $true
            }
            catch {
                try {
                    $errorDetails = $_.ErrorDetails | ConvertFrom-Json
                    if ($errorDetails.messages -and $errorDetails.messages[0].text) {
                        $message = $errorDetails.messages[0].text
                    }
                    elseif ($errorDetails.error) {
                        $message = $errorDetails.error
                    }
                    else {
                        $message = "Unknown error occurred"
                    }
                }
                catch {
                    $message = "Error processing error details"
                }

                $StatusCode = $_.Exception.Response.StatusCode.value__
                $StatusText = $_.Exception.Response.StatusCode.ToString()
                Write-Warning ("HTTP {0} {1}: {2}" -f $StatusCode, $StatusText, $message)

                if (
                    ($StatusCode -match '^5\d{2}$' -or $StatusCode -eq "429" )-and $RetryCount -lt $MaxRetries
                ) {
                    $RetryCount += 1
                    Write-Verbose "Retry attempt $RetryCount after a $PauseDuration second pause..."
                    Start-Sleep -Seconds $PauseDuration
                }
                else {
                    Remove-Variable -Name Headers -Force -ErrorAction SilentlyContinue
                    throw "Failed to retrieve data after $RetryCount attempts."
                }
            }
        }
    }

    Remove-Variable -Name Headers -Force -ErrorAction SilentlyContinue
}