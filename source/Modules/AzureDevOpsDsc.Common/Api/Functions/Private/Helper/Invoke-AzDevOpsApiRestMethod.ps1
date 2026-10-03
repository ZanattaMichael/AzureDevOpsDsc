<#
    .SYNOPSIS
        This is a light, generic, wrapper around 'Invoke-RestMethod' to handle
        multiple retries and error/exception handling.

        This function makes no assumptions around the versions of the API used, the resource
        being operated/actioned upon, the operation/method being performed, nor the content
        of the HTTP headers and body.

    .PARAMETER ApiUri
        The URI of the Azure DevOps API to be connected to. For example:

          https://dev.azure.com/someOrganizationName/_apis/

    .PARAMETER HttpMethod
        The HTTP method being used in the HTTP/REST request sent to the Azure DevOps API.

    .PARAMETER HttpHeaders
        The headers for the HTTP/REST request sent to the Azure DevOps API.

    .PARAMETER HttpBody
        The body for the HTTP/REST request sent to the Azure DevOps API. If performing a 'Post',
        'Put' or 'Patch' method/request, this will typically contain the JSON document of the resource.

    .PARAMETER RetryAttempts
        The number of times the method/request will attempt to be resent/retried if unsuccessful on the
        initial attempt.

        If any attempt is successful, the remaining attempts are ignored.

    .PARAMETER RetryIntervalMs
        The interval (in Milliseconds) between retry attempts.

    .EXAMPLE
        Invoke-AzDevOpsApiRestMethod -ApiUri 'YourApiUriHere' -HttpMethod 'Get' -HttpHeaders $YouHttpHeadersHashtableHere

        Submits a 'Get' request to the Azure DevOps API (relying on the 'ApiUri' value to determine what is being retrieved).

    .EXAMPLE
        Invoke-AzDevOpsApiRestMethod -ApiUri 'YourApiUriHere' -HttpMethod 'Patch' -HttpHeaders $YourHttpHeadersHashtableHere `
                                     -HttpBody $YourHttpBodyHere -RetryAttempts 3

        Submits a 'Patch' request to the Azure DevOps API with the supplied 'HttpBody' and will attempt to retry 3 times (4 in
        total, including the intitial attempt) if unsuccessful.
#>
function Invoke-AzDevOpsApiRestMethod
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('Uri')]
        [System.String]
        $ApiUri,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Get','Post','Patch','Put','Delete')]
        [System.String]
        [Alias('Method')]
        $HttpMethod,

        [Parameter()]
        [ValidateScript( { Test-AzDevOpsApiHttpRequestHeader -HttpRequestHeader $_ -IsValid })]
        [Hashtable]
        [Alias('Headers','HttpRequestHeader')]
        $HttpHeaders=@{},

        # Deliberately untyped. It was [System.String], which silently broke any endpoint
        # taking a non-text body: a [byte[]] cannot be transformed to a string, so the call
        # failed at parameter binding. Callers passing a JSON string are unaffected, and
        # Invoke-RestMethod accepts a byte array directly.
        [Parameter()]
        [Alias('Body')]
        $HttpBody,

        # 'application/octet-stream' is needed by the endpoints that take raw bytes rather
        # than JSON - uploading a secure file is one. Restricting this set to the two JSON
        # types made those endpoints unreachable through this wrapper, which is the only
        # place that applies authentication, retry and rate-limit handling.
        [Parameter()]
        [System.String]
        [Alias('ContentType')]
        [ValidateSet('application/json','application/json-patch+json','application/octet-stream')]
        $HttpContentType = 'application/json',

        [Parameter()]
        [ValidateRange(0,5)]
        [Int32]
        $RetryAttempts = 5,

        [Parameter()]
        [ValidateRange(250,10000)]
        [Int32]
        $RetryIntervalMs = 250,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default),

        [Parameter()]
        [Switch]
        $NoAuthentication,

        [Parameter()]
        [Switch]
        $AzureArcAuthentication,

        # Some callers need to read a response header (the Wiki Pages API's ETag, used as the
        # If-Match value on a later update) that the response body never carries. Without this
        # switch the function behaves exactly as before - the response body only - so every
        # existing caller and its unit tests are unaffected.
        [Parameter()]
        [Switch]
        $IncludeResponseHeaders,

        # Non-authentication headers a specific call needs (for example 'If-Match' on a Wiki
        # Pages update). Kept separate from 'HttpHeaders', whose ValidateScript only accepts an
        # Authorization header, so a caller adding one custom header does not have to also fake a
        # valid-looking Authorization value just to pass that check.
        [Parameter()]
        [Hashtable]
        $AdditionalHeaders = @{}

    )

    $invokeRestMethodParameters = @{
        Uri                         = $ApiUri
        Method                      = $HttpMethod
        Headers                     = $HttpHeaders
        Body                        = $HttpBody
        ContentType                 = $HttpContentType
        ResponseHeadersVariable     = 'responseHeaders'
    }

    foreach ($additionalHeaderName in $AdditionalHeaders.Keys)
    {
        $invokeRestMethodParameters.Headers[$additionalHeaderName] = $AdditionalHeaders[$additionalHeaderName]
    }

    Write-Verbose -Message ('[Invoke-AzDevOpsApiRestMethod] Invoking the Azure DevOps API REST method {0}' -f $HttpMethod)
    Write-Verbose -Message ('[Invoke-AzDevOpsApiRestMethod] API URI: {0}' -f $ApiUri)

    # Remove the 'Body' and 'ContentType' if not relevant to request
    if ($HttpMethod -in $('Get','Delete'))
    {
        $invokeRestMethodParameters.Remove('Body')
        $invokeRestMethodParameters.Remove('ContentType')
    }

    # Reads one header from any of the shapes a response can carry: the dictionary from
    # -ResponseHeadersVariable, HttpResponseHeaders on a PowerShell 7 error response, or
    # WebHeaderCollection on a Windows PowerShell one. A lookup by indexer works on only the first.
    function Get-ResponseHeaderValue
    {
        param ($Headers, [String]$Name)

        if ($null -eq $Headers) { return $null }

        $value = $null
        if ($Headers -is [System.Collections.IDictionary])
        {
            # -eq on strings is case-insensitive, as header names are.
            foreach ($key in $Headers.Keys) { if ($key -eq $Name) { $value = $Headers[$key]; break } }
        }
        elseif ($Headers -is [System.Net.Http.Headers.HttpHeaders])
        {
            $values = $null
            if ($Headers.TryGetValues($Name, [ref]$values)) { $value = $values }
        }
        elseif ($Headers -is [System.Collections.Specialized.NameValueCollection])
        {
            $value = $Headers[$Name]
        }

        if ($null -eq $value) { return $null }
        return [String](@($value)[0])
    }

    # Retry-After is either a number of seconds or an HTTP date.
    function ConvertTo-RetryAfterSeconds
    {
        param ([String]$Value)

        if ([String]::IsNullOrWhiteSpace($Value)) { return 0 }

        $seconds = 0.0
        if ([Double]::TryParse($Value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$seconds))
        {
            return [Int][Math]::Max([Math]::Ceiling($seconds), 0)
        }

        $date = [DateTimeOffset]::MinValue
        if ([DateTimeOffset]::TryParse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal, [ref]$date))
        {
            return [Int][Math]::Max([Math]::Ceiling(($date - [DateTimeOffset]::UtcNow).TotalSeconds), 0)
        }

        return 0
    }

    # Builds the rate-limit state from a response's headers, or $null when it reported none.
    # Azure DevOps sends X-RateLimit-* while a caller is close to being throttled and Retry-After
    # when it is delaying requests, on successful responses as well as on a 429.
    function Get-APIRateLimitFromHeaders
    {
        param ($Headers)

        $retryAfter = ConvertTo-RetryAfterSeconds (Get-ResponseHeaderValue -Headers $Headers -Name 'Retry-After')
        $remaining  = Get-ResponseHeaderValue -Headers $Headers -Name 'X-RateLimit-Remaining'

        if (($retryAfter -le 0) -and [String]::IsNullOrEmpty($remaining)) { return $null }

        $rateLimit = [APIRateLimit]::New($retryAfter)

        $parsed = 0
        if ([Int]::TryParse($remaining, [ref]$parsed)) { $rateLimit.xRateLimitRemaining = $parsed }
        if ([Int]::TryParse((Get-ResponseHeaderValue -Headers $Headers -Name 'X-RateLimit-Reset'), [ref]$parsed)) { $rateLimit.xRateLimitReset = $parsed }

        return $rateLimit
    }

    # Intially set this value to -1, as the first attempt does not want to be classed as a "RetryAttempt"
    $CurrentNoOfRetryAttempts = -1
    # Set the Continuation Token to be False
    $isContinuationToken = $false
    $results = [System.Collections.ArrayList]::new()

    while ($CurrentNoOfRetryAttempts -lt $RetryAttempts)
    {
        # Set by the catch block. Initialized here so a caller's variable of the same name is never read.
        $statusCode = $null
        $isTransient = $true

        <#
            Slow down if the last response asked for it. The state is left by the previous
            response, which may have been from an earlier call.
        #>

        $rateLimit = $Global:DSCAZDO_APIRateLimit

        if ($null -ne $rateLimit)
        {
            if ($rateLimit.retryAfter -gt 0)
            {
                Write-Verbose -Message ('[Invoke-AzDevOpsApiRestMethod] Waiting for {0} seconds before sending the request (Retry-After).' -f $rateLimit.retryAfter)
                Start-Sleep -Seconds $rateLimit.retryAfter
                # Honoured once. Without this every later request would wait again until a response cleared it.
                $rateLimit.retryAfter = 0
            }
            # xRateLimitRemaining is -1 when the response did not report it.
            elseif (($rateLimit.xRateLimitRemaining -ge 0) -and ($rateLimit.xRateLimitRemaining -lt 5))
            {
                $waitMs = $RetryIntervalMs
                if ($rateLimit.xRateLimitReset -gt 0)
                {
                    $untilResetMs = ([DateTimeOffset]::FromUnixTimeSeconds($rateLimit.xRateLimitReset) - [DateTimeOffset]::UtcNow).TotalMilliseconds
                    # Capped so a far-off or skewed reset time cannot stall a DSC run.
                    $waitMs = [Int][Math]::Min([Math]::Max($untilResetMs, $RetryIntervalMs), 60000)
                }
                Write-Verbose -Message ('[Invoke-AzDevOpsApiRestMethod] Resource is overwhelmed. Waiting for {0} milliseconds for the rate limit to reset.' -f $waitMs)
                Start-Sleep -Milliseconds $waitMs
            }
            elseif (($rateLimit.xRateLimitRemaining -ge 5) -and ($rateLimit.xRateLimitRemaining -le 50))
            {
                Write-Verbose -Message ('[Invoke-AzDevOpsApiRestMethod] Resource is close to being overwhelmed. Waiting for {0} milliseconds before sending the request.' -f $RetryIntervalMs)
                Start-Sleep -Milliseconds $RetryIntervalMs
            }
        }

        #
        # Invoke the REST method. Loop until the Continuation Token is False.

        Do
        {
            #
            # Add the Authentication Header

            # A fresh header for every request: a token can be refreshed between pages or retries,
            # and the header is cleared again after each request. With -NoAuthentication the
            # caller's own headers (if any) are sent as given and never touched.
            if (-not $NoAuthentication.IsPresent)
            {
                $invokeRestMethodParameters.Headers.Authorization = Add-AuthenticationHTTPHeader
            }

            #
            # Invoke the REST method

            try
            {
                # Invoke the REST method. If the 'Verbose' switch is present, set it to $false.
                # This is to prevent the output from being displayed in the console.
                $response = Invoke-RestMethod @invokeRestMethodParameters -Verbose:$false

                # Zero out the 'Authorization' header this function added
                if (-not $NoAuthentication.IsPresent) { $invokeRestMethodParameters.Headers.Authorization = $null }
                # Add the response to the results array
                $null = $results.Add($response)

                # Keep whatever rate-limit state this response reported for the next request
                $Global:DSCAZDO_APIRateLimit = Get-APIRateLimitFromHeaders -Headers $responseHeaders

                #
                # Test to see if there is no continuation token

                if ([String]::IsNullOrEmpty($responseHeaders.'x-ms-continuationtoken'))
                {
                    # If not, set the continuation token to False
                    $isContinuationToken = $false

                    Write-Verbose "[Invoke-AzDevOpsApiRestMethod] No continuation token found. Breaking loop."

                    if ($IncludeResponseHeaders)
                    {
                        # Wrap the body and headers together rather than changing what a plain
                        # call returns - existing callers keep getting the response body as-is.
                        return [PSCustomObject]@{
                            Value   = $response
                            Headers = $responseHeaders
                        }
                    }

                    return $results

                }

                #
                # A continuation token is present.

                # If so, set the continuation token to True
                $isContinuationToken = $true
                # Response headers are returned as string arrays; take the first value so the token
                # is not stringified as 'System.String[]'.
                $continuationToken = @($responseHeaders.'x-ms-continuationtoken')[0]
                # Update the URI to include the continuation token. $ApiUri already carries the
                # correct 'api-version' query parameter, so only the continuation token is appended.
                # (Previously a bare '&7.1' was appended, producing a malformed query and, for the
                # preview-only graph endpoints, a 'version 7.1 is under preview' 400 error.)
                $invokeRestMethodParameters.Uri = '{0}&continuationToken={1}' -f $ApiUri, $continuationToken
                # Reset the RetryAttempts counter
                $CurrentNoOfRetryAttempts = -1

            }
            catch
            {

                # If AzureArcAuthentication is present, then we need to handle the error differently.
                # Stop and Pass the error back to the caller. The caller will handle the error.
                if ($AzureArcAuthentication.IsPresent)
                {
                    throw $_
                }

                # Zero out the 'Authorization' header this function added
                if (-not $NoAuthentication.IsPresent) { $invokeRestMethodParameters.Headers.Authorization = $null }

                # No status code means the request never got a response (DNS, connection reset,
                # timeout), which is worth retrying.
                $errorResponse = $_.Exception.Response
                $statusCode = $null
                if (($null -ne $errorResponse) -and ($null -ne $errorResponse.StatusCode))
                {
                    $statusCode = [Int]$errorResponse.StatusCode
                }

                # Obtain any exception message
                $responseBody = $null
                try { $responseBody = $_.ErrorDetails.Message } catch {}
                if (-not $responseBody)
                {
                    try { $responseBody = $_.Exception.Response.Content.ReadAsStringAsync().Result } catch {}
                }
                if (-not $responseBody)
                {
                    try {
                        $stream = $_.Exception.Response.GetResponseStream()
                        $responseBody = [System.IO.StreamReader]::new($stream).ReadToEnd()
                    } catch {}
                }
                $restMethodExceptionMessage = if ($responseBody) { "$($_.Exception.Message) | ResponseBody: $responseBody" } else { $_.Exception.Message }

                # Only a timeout, throttling or a server error can succeed on a second try. Any
                # other 4xx (bad request, unauthorized, forbidden, not found, conflict) gives the
                # same answer every time, so retrying it only adds delay before the same error.
                $isTransient = ($null -eq $statusCode) -or ($statusCode -in @(408, 429)) -or ($statusCode -ge 500)
                if (-not $isTransient)
                {
                    $CurrentNoOfRetryAttempts++
                    break
                }

                # Increment the number of retries attempted
                $CurrentNoOfRetryAttempts++

                # The last attempt failed: nothing follows it, so there is nothing to wait for.
                if ($CurrentNoOfRetryAttempts -ge $RetryAttempts)
                {
                    break
                }

                # Check to see if it is an HTTP 429 (Too Many Requests) error
                if ($statusCode -eq 429)
                {
                    $retryAfter = ConvertTo-RetryAfterSeconds (Get-ResponseHeaderValue -Headers $errorResponse.Headers -Name 'Retry-After')

                    if ($retryAfter -gt 0)
                    {
                        # The wait itself happens at the top of the retry loop.
                        Write-Verbose -Message "Received a 'Too Many Requests' response from the Azure DevOps API. Waiting for $retryAfter seconds before retrying."
                        $Global:DSCAZDO_APIRateLimit = [APIRateLimit]::New($retryAfter)
                        break
                    }

                    # No Retry-After: back off exponentially from RetryIntervalMs instead.
                    $backoffMs = [Int][Math]::Min($RetryIntervalMs * [Math]::Pow(2, $CurrentNoOfRetryAttempts), 30000)
                    Write-Verbose -Message "Received a 'Too Many Requests' response from the Azure DevOps API. Waiting for $backoffMs milliseconds before retrying."
                    Start-Sleep -Milliseconds $backoffMs
                    break
                }

                # Wait before the next attempt/retry
                Start-Sleep -Milliseconds $RetryIntervalMs

                # Break the continuation token loop so that the next attempt can be made
                break;
            }

        } Until (-not $isContinuationToken)

        # A non-transient error ends the retries straight away.
        if (-not $isTransient)
        {
            break
        }

    }

    # The request failed: either a non-transient error or every retry attempt failed. Report the
    # retries actually made, which is fewer than $RetryAttempts when the error was not retried.
    $localizedMsg = $script:localizedData.AzDevOpsApiRestMethodException
    if ([String]::IsNullOrEmpty($localizedMsg))
    {
        $localizedMsg = "The '{0}' function returned an error after {1} retry attempts: ""{2}"""
    }
    $errorMessage = $localizedMsg -f $MyInvocation.MyCommand, [Math]::Max($CurrentNoOfRetryAttempts, 0), $restMethodExceptionMessage
    throw "[Invoke-AzDevOpsApiRestMethod] $errorMessage"

}
