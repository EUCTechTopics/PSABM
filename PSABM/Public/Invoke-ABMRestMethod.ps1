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
        [Int] $MaxRetries = 4,

        [Parameter(Mandatory = $false)]
        [Int] $PauseDuration = 2,

        [Parameter(Mandatory = $false)]
        [Int] $ThrottleDelayMs = 250
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

        # Retry Loop for Current Page
        while (-not $PageSuccess) {
            try {
                $Splat = @{
                    Uri             = $CurrentUrl
                    Headers         = $Headers
                    Method          = $Method
                    ContentType     = $ContentType
                }
                if ($Body) { $Splat.Add('Body', $Body) }

                Write-Verbose ("API Call [{0}]: {1}" -f $Method, $CurrentUrl)
                $Results = Invoke-RestMethod @Splat -Verbose:$false -Debug:$false

                # Stream results to pipeline immediately
                if ($null -ne $Results.data) {
                    $Results.data
                } else {
                    $Results
                }

                # Evaluate pagination
                if ($Method -eq "GET" -and $Results.links -and $Results.links.next) {
                    $NextLink = $Results.links.next
                    $CurrentUrl = if ($NextLink -like "http*") { $NextLink } else { "{0}{1}" -f $script:ABMEnv.BaseAPIUrl, $NextLink }

                    if ($ThrottleDelayMs -gt 0) {
                        Write-Verbose ("Pacing pagination: Waiting {0} ms..." -f $ThrottleDelayMs)
                        Start-Sleep -Milliseconds $ThrottleDelayMs
                    }
                } else {
                    $CurrentUrl = $null
                }

                $PageSuccess = $true
            }
            catch {

                $StatusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }

                # Retry on HTTP 429 (Rate Limit) or 5xx (Server Errors)
                if (($StatusCode -eq 429 -or ($StatusCode -ge 500 -and $StatusCode -le 599)) -and $RetryCount -lt $MaxRetries) {
                    $RetryCount++
                    $WaitSeconds = [math]::Pow(2, $RetryCount) * $PauseDuration
                    
                    # Increase throttle delay for subsequent retries if rate limited
                    if ($StatusCode -eq 429 -and $ThrottleDelayMs -lt 5000) {
                        $ThrottleDelayMs += 250
                    }

                    Write-Verbose ("HTTP {0} encountered. Retrying in {1}s (Attempt {2}/{3})..." -f $StatusCode, $WaitSeconds, $RetryCount, $MaxRetries)
                    Start-Sleep -Seconds $WaitSeconds
                }
                else {
                    # Extract error details from API response body if available
                    $message = try {
                        $errObj = $_.ErrorDetails | ConvertFrom-Json
                        if ($errObj.errors[0].detail) {
                            $errObj.errors[0].detail
                        } elseif ($errObj.messages[0].text) {
                            $errObj.messages[0].text
                        } elseif ($errObj.error) {
                            $errObj.error
                        } else {
                            $_.Exception.Message
                        }
                    } catch {
                        $_.Exception.Message
                    }

                    Write-Error ("HTTP {0}: {1}" -f $StatusCode, $message)
                    Remove-Variable -Name Headers -Force -ErrorAction SilentlyContinue
                    throw "Request failed with HTTP $StatusCode after $RetryCount retry attempt(s)."
                }
            }
        }
    }

    Remove-Variable -Name Headers -Force -ErrorAction SilentlyContinue
}