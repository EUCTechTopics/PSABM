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
        [String]
        $Url,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "PATCH", "POST", "PUT", "DELETE")]
        [String]
        $Method = "GET",

        [Parameter(Mandatory = $false)]
        [String]
        $Body,

        [Parameter(Mandatory = $false)]
        [String]
        $ContentType = "application/json",

        [Parameter(Mandatory = $false)]
        [Int]
        $MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [Int]
        $PauseDuration = 2
    )

    # Check if connected to ABM
    Test-ABMConnection

    # Form complete URL
    $Url = ("{0}{1}" -f $($script:ABMEnv.BaseAPIUrl), $Url)

    # Create authorization header
    $Token = ConvertFrom-SecureString $script:ABMEnv.SessionToken -AsPlainText
    $Headers = @{
        Authorization = "Bearer $Token"
    }
    Remove-Variable -Name Token -Force

    # Add application/json-patch+json content-type for PATCH requests
    if ($Method -eq "PATCH") {
        $ContentType = "application/json-patch+json"
    }

    # Set initial variables
    $SendCall = $true
    $RetryCount = 0
    $AllResults = @()

    # Try to fetch the page
    while ($SendCall) {
        try {
            $Splat = @{
                Uri             = $Url
                UseBasicParsing = $true
                Headers         = $Headers
                Method          = $Method
                ContentType     = $ContentType
            }
            if($Body) { $Splat.Add('Body', $Body) }
            $response = Invoke-WebRequest @Splat -Verbose:$false -Debug:$false
            Write-Verbose $response

            # Parse and collect results
            $Results = $Response.Content | ConvertFrom-Json
            $AllResults += $Results.Data

            $SendCall = $false
        }
        catch {
            # Get the error message
            try {
                # Try retrieving .messages[0].text
                $errorDetails = $_.ErrorDetails | ConvertFrom-Json
                if ($errorDetails.messages -and $errorDetails.messages[0].text) {
                    $message = $errorDetails.messages[0].text
                }
                elseif ($errorDetails.error) {
                    # Fallback to .error if .messages[0].text is not available
                    $message = $errorDetails.error
                }
                else {
                    # Fallback message if neither is available
                    $message = "Unknown error occurred"
                }
            }
            catch {
                # In case of failure in parsing JSON or accessing properties
                $message = "Error processing error details"
            }

            # Log the error message
            Write-Error ("HTTP {0} {1}: {2}" -f ($_.Exception.Response.StatusCode.value__), ($_.Exception.Response.StatusCode.ToString()), $message)
            if ($_.Exception.Response.StatusCode.value__ -match '^5\d{2}$' -and $RetryCount -lt $MaxRetries) {
                $RetryCount += 1
                Write-Verbose "Retry attempt $RetryCount after a $PauseDuration second pause..."
                Start-Sleep -Seconds $PauseDuration
            }
            else {
                $SendCall = $false
                Remove-Variable -Name Headers -Force
                throw "Failed to retrieve data after $RetryCount attempts."
            }
        }
    }
    # Return all results
    Remove-Variable -Name Headers -Force
    Write-Output $AllResults
}