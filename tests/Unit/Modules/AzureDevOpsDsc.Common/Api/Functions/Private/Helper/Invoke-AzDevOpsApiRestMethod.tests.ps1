$currentFile = $MyInvocation.MyCommand.Path

Describe 'Invoke-AzDevOpsApiRestMethod' -Tag "Unit", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-AzDevOpsApiRestMethod.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Get 007.APIRateLimit.ps1
        . (Get-ClassFilePath '007.APIRateLimit')

        $defaultParameters = @{
            ApiUri = 'https://dev.azure.com/someOrganizationName/_apis/'
            HttpMethod = 'Get'
            HttpHeaders = @{}
            RetryAttempts = 1
            RetryIntervalMs = 250
        }

        Mock -CommandName Test-AzDevOpsApiHttpRequestHeader -MockWith { return $true }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '6.0-preview.1' }
        Mock -CommandName Add-AuthenticationHTTPHeader -MockWith { return $null }

        # Define a custom exception class
        class CustomException : System.Exception {

            [System.Net.WebExceptionStatus]$Status
            [HashTable]$Response

            CustomException([string]$message, [System.Net.WebExceptionStatus]$status,
                            [HashTable]$httpWebResponse, [System.Net.HttpStatusCode]$statusCode) : base($message) {
                $this.Status = $status
                $this.Response = @{
                    StatusCode = $statusCode
                    Headers = $httpWebResponse
                }
            }
        }

    }

    Context 'Basic functionality' {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith {
                param (
                    [string]$Uri,
                    [string]$Method,
                    [hashtable]$Headers
                )
                # Default mock behavior can be defined here if needed.
            }
        }

        It 'should call Invoke-RestMethod with correct parameters' {
            Invoke-AzDevOpsApiRestMethod @defaultParameters
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 1
        }

        It 'should not include response headers unless requested' {
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ success = $true } }
            $result = Invoke-AzDevOpsApiRestMethod @defaultParameters
            $result | Should -BeOfType [System.Collections.Hashtable]
            $result.success | Should -Be $true
        }

        It 'should merge AdditionalHeaders into the request without needing an Authorization value' {
            $seenHeaders = $null
            Mock -CommandName Invoke-RestMethod -MockWith {
                param ($Uri, $Method, $Headers)
                $script:seenHeaders = $Headers
                return @{ success = $true }
            }
            Invoke-AzDevOpsApiRestMethod @defaultParameters -AdditionalHeaders @{ 'If-Match' = '"3"' }
            $script:seenHeaders.'If-Match' | Should -Be '"3"'
        }

        It 'should return the response body and headers when IncludeResponseHeaders is set' {
            Mock -CommandName Invoke-RestMethod -MockWith {
                Set-Variable responseHeaders -Value @{ ETag = @('"3"') } -Scope Global
                return @{ success = $true }
            }
            $result = Invoke-AzDevOpsApiRestMethod @defaultParameters -IncludeResponseHeaders
            $result.Value.success | Should -Be $true
            $result.Headers.ETag | Should -Be @('"3"')
        }

        It 'should return results from Invoke-RestMethod' {
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ success = $true } }
            $result = Invoke-AzDevOpsApiRestMethod @defaultParameters
            $result | Should -BeOfType [System.Collections.Hashtable]
            $result.success | Should -Be $true
        }
    }

    Context 'Retry mechanism' {
        It 'should retry if Invoke-RestMethod throws' {
            Mock -CommandName Start-Sleep
            Mock -CommandName Invoke-RestMethod -MockWith { throw "Error" }
            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 2

            { Invoke-AzDevOpsApiRestMethod @parameters } | Should -Throw
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 3
        }

        It 'should wait between retries, but not after the last attempt' {
            Mock -CommandName Start-Sleep -Verifiable
            Mock -CommandName Invoke-RestMethod -MockWith { throw "Error" }
            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 2

            { Invoke-AzDevOpsApiRestMethod @parameters } | Should -Throw
            # Three attempts, two gaps between them.
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 2
        }

        It 'should not retry a non-transient HTTP <StatusCode> error' -TestCases @(
            @{ StatusCode = [System.Net.HttpStatusCode]::BadRequest }
            @{ StatusCode = [System.Net.HttpStatusCode]::Unauthorized }
            @{ StatusCode = [System.Net.HttpStatusCode]::Forbidden }
            @{ StatusCode = [System.Net.HttpStatusCode]::NotFound }
            @{ StatusCode = [System.Net.HttpStatusCode]::Conflict }
        ) {
            param ($StatusCode)

            Mock -CommandName Start-Sleep
            # The mock body runs in its own scope and does not see the test case parameter.
            $script:mockStatusCode = $StatusCode
            Mock -CommandName Invoke-RestMethod -MockWith {
                throw [CustomException]::New('Client error', [System.Net.WebExceptionStatus]::ProtocolError, @{}, $script:mockStatusCode)
            }
            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 5

            { Invoke-AzDevOpsApiRestMethod @parameters } | Should -Throw '*after 0*Client error*'
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0
        }

        It 'should retry a transient HTTP <StatusCode> error' -TestCases @(
            @{ StatusCode = [System.Net.HttpStatusCode]::RequestTimeout }
            @{ StatusCode = [System.Net.HttpStatusCode]::InternalServerError }
            @{ StatusCode = [System.Net.HttpStatusCode]::BadGateway }
            @{ StatusCode = [System.Net.HttpStatusCode]::ServiceUnavailable }
            @{ StatusCode = [System.Net.HttpStatusCode]::GatewayTimeout }
        ) {
            param ($StatusCode)

            Mock -CommandName Start-Sleep
            # The mock body runs in its own scope and does not see the test case parameter.
            $script:mockStatusCode = $StatusCode
            Mock -CommandName Invoke-RestMethod -MockWith {
                throw [CustomException]::New('Server error', [System.Net.WebExceptionStatus]::ProtocolError, @{}, $script:mockStatusCode)
            }
            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 2

            { Invoke-AzDevOpsApiRestMethod @parameters } | Should -Throw '*after 2*Server error*'
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 3
        }
    }

    Context 'Azure Arc authentication' {

        BeforeAll {
            $arcParameters = @{
                ApiUri                 = 'http://localhost:40342/metadata/identity/oauth2/token'
                HttpMethod             = 'Get'
                HttpHeaders            = @{ Metadata = 'true' }
                NoAuthentication       = $true
                AzureArcAuthentication = $true
                RetryAttempts          = 2
                RetryIntervalMs        = 250
            }
        }

        It 'should hand the Arc 401 challenge back to the caller unchanged and not retry it' {
            Mock -CommandName Start-Sleep
            Mock -CommandName Invoke-RestMethod -MockWith {
                throw [CustomException]::New('Arc challenge', [System.Net.WebExceptionStatus]::ProtocolError, @{}, [System.Net.HttpStatusCode]::Unauthorized)
            }

            $thrown = $null
            try { Invoke-AzDevOpsApiRestMethod @arcParameters } catch { $thrown = $_ }

            # The caller reads the WWW-Authenticate header from this exception's response.
            $thrown.Exception.Message | Should -Be 'Arc challenge'
            $thrown.Exception.Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::Unauthorized)
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 1
        }

        It 'should retry a throttled Arc token request rather than failing on the first 429' {
            Mock -CommandName Start-Sleep
            $script:arcCalls = 0
            Mock -CommandName Invoke-RestMethod -MockWith {
                $script:arcCalls++
                if ($script:arcCalls -eq 1)
                {
                    throw [CustomException]::New('Too Many Requests', [System.Net.WebExceptionStatus]::ProtocolError, @{}, [System.Net.HttpStatusCode]::TooManyRequests)
                }
                return [PSCustomObject]@{ access_token = 'token' }
            }

            $result = Invoke-AzDevOpsApiRestMethod @arcParameters

            $result.access_token | Should -Be 'token'
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 2
        }
    }

    Context 'Authentication header' {

        It 'should add a fresh Authorization header to every request' {
            Mock -CommandName Start-Sleep
            Mock -CommandName Add-AuthenticationHTTPHeader -MockWith { return 'Bearer token' }
            $script:seenAuthorization = @()
            Mock -CommandName Invoke-RestMethod -MockWith {
                param ($Uri, $Method, $Headers)
                $script:seenAuthorization += $Headers.Authorization
                throw "Error"
            }
            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 1

            { Invoke-AzDevOpsApiRestMethod @parameters } | Should -Throw
            $script:seenAuthorization | Should -Be @('Bearer token', 'Bearer token')
        }

        It 'should keep the caller''s Authorization header on retries when NoAuthentication is set' {
            Mock -CommandName Start-Sleep
            Mock -CommandName Add-AuthenticationHTTPHeader -MockWith { return 'Bearer module-token' }
            $script:seenAuthorization = @()
            Mock -CommandName Invoke-RestMethod -MockWith {
                param ($Uri, $Method, $Headers)
                $script:seenAuthorization += $Headers.Authorization
                throw "Error"
            }
            $parameters = $defaultParameters.Clone()
            $parameters.HttpHeaders = @{ Authorization = 'Bearer caller-token' }
            $parameters.RetryAttempts = 1

            { Invoke-AzDevOpsApiRestMethod @parameters -NoAuthentication } | Should -Throw
            $script:seenAuthorization | Should -Be @('Bearer caller-token', 'Bearer caller-token')
            Assert-MockCalled -CommandName Add-AuthenticationHTTPHeader -Exactly -Times 0
        }
    }

    Context 'Continuation token handling' {

        AfterAll {
            Remove-Variable -Name ResponseHeaders -Scope Global -ErrorAction SilentlyContinue
        }

        It 'should handle continuation tokens and loop until no token is found' {

            # First call
            Mock -CommandName Invoke-RestMethod -ParameterFilter { $Uri -notlike '*continuationToken*' } -MockWith {
                Set-Variable responseHeaders -Value @{ 'x-ms-continuationtoken' = 'token' } -Scope Global
                return @{ success = $true }
            } -Verifiable

            # Second call
            Mock -CommandName Invoke-RestMethod -ParameterFilter { $Uri -like '*continuationToken*' } -MockWith {
                Remove-Variable -Name ResponseHeaders -Scope Global -ErrorAction SilentlyContinue
                return @{ success = $true }
            } -Verifiable

            $parameters = $defaultParameters.Clone()
            $result = Invoke-AzDevOpsApiRestMethod @parameters

            Assert-MockCalled -CommandName Invoke-RestMethod -Times 2
            $result | Should -BeOfType [System.Collections.Hashtable]
            $result.Count | Should -Be 2
        }
    }

    Context 'HTTP 429 Handling' {

        AfterAll {
            Remove-Variable -Name TooManyRequestsFlag -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name DSCAZDO_APIRateLimit -Scope Global -ErrorAction SilentlyContinue
        }

        It 'should handle HTTP 429 and retry with appropriate delay' {

            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Warning

            Mock -CommandName Invoke-RestMethod -MockWith {
                Set-Variable TooManyRequestsFlag -Value $true -Scope Global

                Throw [CustomException]::New(
                    "Too Many Requests",
                    [System.Net.WebExceptionStatus]::ProtocolError,
                    @{ "Retry-After" = 1 },
                    [System.Net.HttpStatusCode]::TooManyRequests
                )

            } -ParameterFilter {
                $null -eq $Global:TooManyRequestsFlag
            }

            Mock -CommandName Invoke-RestMethod -MockWith {
                Remove-Variable -Name TooManyRequestsFlag -Scope Global
                return @{ success = $true }
            } -ParameterFilter {
                $Global:TooManyRequestsFlag -eq $true
            }

            Mock -CommandName Start-Sleep -Verifiable

            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 2

            $result = Invoke-AzDevOpsApiRestMethod @parameters

            $result | Should -BeOfType [System.Collections.Hashtable]
            Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                $Message -like '*Too Many Requests*'
            }
            Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                $Message -like '*seconds before retrying*'
            }
            Assert-MockCalled -CommandName Start-Sleep -Times 1

        }
    }

    Context 'Rate limiting' {

        BeforeEach {
            Remove-Variable -Name DSCAZDO_APIRateLimit -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name responseHeaders -Scope Global -ErrorAction SilentlyContinue
            Mock -CommandName Start-Sleep
        }

        AfterAll {
            Remove-Variable -Name DSCAZDO_APIRateLimit -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name responseHeaders -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name TooManyRequestsFlag -Scope Global -ErrorAction SilentlyContinue
        }

        It 'should back off in milliseconds when a 429 has no Retry-After header' {
            Mock -CommandName Invoke-RestMethod -MockWith {
                Set-Variable TooManyRequestsFlag -Value $true -Scope Global
                throw [CustomException]::New('Too Many Requests', [System.Net.WebExceptionStatus]::ProtocolError, @{}, [System.Net.HttpStatusCode]::TooManyRequests)
            } -ParameterFilter { $null -eq $Global:TooManyRequestsFlag }
            Mock -CommandName Invoke-RestMethod -MockWith {
                Remove-Variable -Name TooManyRequestsFlag -Scope Global
                return @{ success = $true }
            } -ParameterFilter { $Global:TooManyRequestsFlag -eq $true }

            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 2

            $result = Invoke-AzDevOpsApiRestMethod @parameters

            $result.success | Should -Be $true
            # RetryIntervalMs (250) for the first retry, doubling after that. Never a Seconds wait:
            # the interval used to be stored as seconds and became a 250 second sleep.
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1 -ParameterFilter { $Milliseconds -eq 250 }
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0 -ParameterFilter { $Seconds -gt 0 }
        }

        It 'should not wait after a successful response that reported no rate limit' {
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ success = $true } }

            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters
            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters

            $Global:DSCAZDO_APIRateLimit | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0
        }

        It 'should read X-RateLimit headers from a successful response and slow the next request' {
            Mock -CommandName Invoke-RestMethod -MockWith {
                Set-Variable responseHeaders -Scope Global -Value @{
                    'X-RateLimit-Remaining' = @('20')
                    'X-RateLimit-Reset'     = @('1700000000')
                }
                return @{ success = $true }
            }

            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters

            $Global:DSCAZDO_APIRateLimit.xRateLimitRemaining | Should -Be 20
            $Global:DSCAZDO_APIRateLimit.xRateLimitReset | Should -Be 1700000000
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0

            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters

            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1 -ParameterFilter { $Milliseconds -eq 250 }
        }

        It 'should honour a Retry-After from a successful response once' {
            Mock -CommandName Invoke-RestMethod -MockWith {
                Set-Variable responseHeaders -Scope Global -Value @{ 'Retry-After' = @('3') }
                return @{ success = $true }
            } -ParameterFilter { $null -eq $Global:DSCAZDO_APIRateLimit }
            Mock -CommandName Invoke-RestMethod -MockWith {
                Remove-Variable -Name responseHeaders -Scope Global -ErrorAction SilentlyContinue
                return @{ success = $true }
            } -ParameterFilter { $null -ne $Global:DSCAZDO_APIRateLimit }

            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters
            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters
            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters

            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1 -ParameterFilter { $Seconds -eq 3 }
        }

        It 'should read Retry-After from a PowerShell 7 HttpResponseException' {
            # What Invoke-RestMethod really throws in PowerShell 7: Response is an
            # HttpResponseMessage, whose Headers has no string indexer - Headers['Retry-After']
            # returned nothing and the 429 fell back to the (mis-scaled) interval.
            $script:throttled = $false
            Mock -CommandName Invoke-RestMethod -MockWith {
                $script:throttled = $true
                $message = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::TooManyRequests)
                $message.Headers.RetryAfter = [System.Net.Http.Headers.RetryConditionHeaderValue]::new([TimeSpan]::FromSeconds(7))
                throw [Microsoft.PowerShell.Commands.HttpResponseException]::new('Too Many Requests', $message)
            } -ParameterFilter { -not $script:throttled }
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ success = $true } } -ParameterFilter { $script:throttled }

            $parameters = $defaultParameters.Clone()
            $parameters.RetryAttempts = 2

            $result = Invoke-AzDevOpsApiRestMethod @parameters

            $result.success | Should -Be $true
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1 -ParameterFilter { $Seconds -eq 7 }
        }

        It 'should not treat a 429 rate-limit state as an exhausted request budget' {
            # xRateLimitRemaining is not reported on a 429, and used to default to 0 - which also
            # triggered the 'overwhelmed' wait on top of the Retry-After wait.
            $Global:DSCAZDO_APIRateLimit = [APIRateLimit]::New(2)
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ success = $true } }

            $null = Invoke-AzDevOpsApiRestMethod @defaultParameters

            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1 -ParameterFilter { $Seconds -eq 2 }
        }
    }

    Context 'Binary request bodies' {

        # Regression guard. HttpBody was [System.String] and HttpContentType was restricted to
        # the two JSON types, which made every raw-byte endpoint unreachable through this
        # wrapper: the call died at parameter binding. New-DevOpsSecureFile did exactly that,
        # and because its failure surfaced as a non-terminating Write-Error the DSC Set()
        # reported no error while creating nothing. Both halves are pinned here.

        It 'accepts application/octet-stream as a content type' {
            $contentType = (Get-Command Invoke-AzDevOpsApiRestMethod).Parameters['HttpContentType']
            $validateSet = $contentType.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

            $validateSet.ValidValues | Should -Contain 'application/octet-stream'
        }

        It 'does not coerce the body to a string' {
            # A [byte[]] cannot be transformed to [System.String], so a typed parameter would
            # fail to bind rather than merely mangle the content.
            (Get-Command Invoke-AzDevOpsApiRestMethod).Parameters['HttpBody'].ParameterType |
                Should -Be ([System.Object])
        }

        It 'passes a byte array through to Invoke-RestMethod unchanged' {
            $bytes = [System.Text.Encoding]::ASCII.GetBytes('dsc integration test content')
            $script:capturedBody        = $null
            $script:capturedContentType = $null

            Mock -CommandName Invoke-RestMethod -MockWith {
                $script:capturedBody        = $Body
                $script:capturedContentType = $ContentType
                return @{ id = 1 }
            }

            $parameters = $defaultParameters.Clone()
            $parameters.HttpMethod      = 'Post'
            $parameters.HttpBody        = $bytes
            $parameters.HttpContentType = 'application/octet-stream'

            $null = Invoke-AzDevOpsApiRestMethod @parameters

            $script:capturedContentType | Should -Be 'application/octet-stream'
            $script:capturedBody        | Should -BeOfType [System.Byte]
            $script:capturedBody.Count  | Should -Be $bytes.Count
            [System.Text.Encoding]::ASCII.GetString($script:capturedBody) |
                Should -Be 'dsc integration test content'
        }
    }
}
