<#
.SYNOPSIS
    Invokes a REST API request against the Apple Business Manager (ABM) or Apple School Manager (ASM) API.

.DESCRIPTION
    Executes HTTP requests against Apple API endpoints using an active connection. Handles automatic
    cursor-based pagination for multi-page responses, streaming parsed JSON objects directly to the
    PowerShell pipeline.

    Includes built-in resilience features:
    - Proactive request pacing between pages to prevent rate limits.
    - Automatic exponential backoff retries for HTTP 429 (Too Many Requests) and HTTP 5xx (Server Errors).
    - Automatic Content-Type adjustment for PATCH operations.

.PARAMETER Url
    The relative API endpoint path to call (e.g., '/orgDevices'). This is appended to the base API URL
    configured during session connection.

.PARAMETER Method
    The HTTP method to execute. Valid values are 'GET', 'PATCH', 'POST', 'PUT', and 'DELETE'.
    Default is 'GET'.

.PARAMETER Body
    The HTTP request body payload as a formatted string (typically JSON) for POST, PUT, or PATCH operations.

.PARAMETER ContentType
    The Content-Type header of the request. Defaults to 'application/json'.
    Note: The function automatically overrides this to 'application/json-patch+json' when Method is 'PATCH'.

.PARAMETER MaxRetries
    The maximum number of retry attempts to perform when encountering transient errors (HTTP 429 or HTTP 5xx).
    Default is 4.

.PARAMETER PauseDuration
    The base multiplier in seconds used for exponential backoff calculations during retries.
    Default is 2.

.PARAMETER ThrottleDelayMs
    The pause duration in milliseconds injected between sequential pagination requests to proactively prevent hitting API rate limits.
    Default is 250.

.EXAMPLE
    Invoke-ABMRestMethod -Url '/orgDevices?limit=1000'

    Executes a GET request to retrieve organization devices, automatically paging through all available results
    and outputting each device object to the pipeline.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Streams parsed JSON response data objects directly to the PowerShell pipeline.
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