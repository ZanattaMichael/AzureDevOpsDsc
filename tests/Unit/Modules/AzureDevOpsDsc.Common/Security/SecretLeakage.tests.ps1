<#
    Leak detection for the whole module, rather than for one function.

    'Source code' scans the files: it fails when a change introduces a pattern that leaks, or can
    leak, a credential - a secret-bearing variable in a log line, a raw web request that bypasses
    the one audited request path, a secret DSC property that export would not redact, or a
    credential pasted into a file.

    'Behaviour' plants a canary credential and drives the real code paths with it - a failing API
    call that echoes the request, a failing token request, the log files, the cache files, the
    token object itself - then searches everything that came out for the canary.

    When a test here fails, fix the leak. Only extend an allow-list when the flagged value is
    provably not a secret, and say why next to the entry.
#>

BeforeDiscovery {
    $repositoryRoot = $Global:RepositoryRoot
    if ([String]::IsNullOrEmpty($repositoryRoot)) {
        $repositoryRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '../../../../..')).Path
    }

    $sourceRoot = Join-Path -Path $repositoryRoot -ChildPath 'source'

    $sourceFileCases = @(
        Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Include '*.ps1', '*.psm1' |
            Where-Object { $_.FullName -notmatch '[\\/]Examples[\\/]' } |
            ForEach-Object { @{ Name = $_.FullName.Substring($repositoryRoot.Length + 1); Path = $_.FullName } }
    )

    $classFileCases = @(
        Get-ChildItem -LiteralPath (Join-Path -Path $sourceRoot -ChildPath 'Classes') -File -Filter '*.ps1' |
            ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
    )

    $literalFileCases = @(
        Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1', '*.json', '*.yml', '*.yaml', '*.md', '*.clixml', '*.xml', '*.txt' |
            Where-Object { $_.FullName -notmatch '[\\/](\.git|output|node_modules)[\\/]' } |
            ForEach-Object { @{ Name = $_.FullName.Substring($repositoryRoot.Length + 1); Path = $_.FullName } }
    )
}

Describe 'Secret leakage: source code' -Tag 'Unit', 'Security' {

    BeforeAll {
        # Commands that put text somewhere a person or a log collector can read it.
        $script:sinkCommands = @(
            'Write-Verbose', 'Write-Warning', 'Write-Error', 'Write-Host', 'Write-Debug', 'Write-Information',
            'Write-Log', 'Out-File', 'Add-Content', 'Set-Content', 'Write-Output'
        )

        # Variables that hold a credential in plain text wherever they appear in the module.
        $script:secretVariables = @(
            'PersonalAccessToken', 'ClientSecret', 'plainToken', 'plainFederatedToken', 'FederatedToken',
            'requestToken', 'CertificatePassword', 'plainPassword', 'assertion', 'clientAssertion',
            'headerValue', 'HttpHeaders', 'invokeRestMethodParameters', 'azOutput', 'azStandardOutput'
        )

        # Names that are only a credential inside the authentication code. Elsewhere '$token' is an
        # ACL token (a path such as 'repoV2/<project>/<repo>') and '$body' an ordinary request body.
        $script:authenticationOnlySecretVariables = @('token', 'body', 'response', 'secret', 'password')

        # Properties that hold a credential when read from a token or settings object.
        $script:secretMembers = @('access_token', 'accessToken', 'clientSecret', 'certificatePassword', 'client_secret', 'refresh_token')

        function Test-IsRedacted
        {
            # True when the node sits inside a Protect-AzDoSecretString call.
            param ($Node)

            $parent = $Node.Parent
            while ($null -ne $parent)
            {
                if (($parent -is [System.Management.Automation.Language.CommandAst]) -and ($parent.GetCommandName() -eq 'Protect-AzDoSecretString'))
                {
                    return $true
                }
                $parent = $parent.Parent
            }
            return $false
        }

        function Get-SinkNode
        {
            # Every log/file-writing command and every throw statement in a file.
            param ([String]$Path)

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

            return @($ast.FindAll({
                param ($node)
                ($node -is [System.Management.Automation.Language.ThrowStatementAst]) -or
                (($node -is [System.Management.Automation.Language.CommandAst]) -and ($node.GetCommandName() -in $script:sinkCommands))
            }, $true))
        }
    }

    Context 'Log lines and error messages in <Name>' -ForEach $sourceFileCases {

        It 'Never writes a secret-bearing variable to a log, a file or an error message' {
            $isAuthenticationCode = $Path -match '[\\/]Authentication[\\/]'
            $findings = [System.Collections.Generic.List[String]]::new()

            foreach ($sink in (Get-SinkNode -Path $Path))
            {
                $variables = $sink.FindAll({ param ($node) $node -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)

                foreach ($variable in $variables)
                {
                    $name = $variable.VariablePath.UserPath

                    $isSecret = ($name -in $script:secretVariables) -or
                                ($isAuthenticationCode -and ($name -in $script:authenticationOnlySecretVariables))

                    if ($isSecret -and (-not (Test-IsRedacted -Node $variable)))
                    {
                        $findings.Add(('line {0}: ${1} in: {2}' -f $sink.Extent.StartLineNumber, $name, ($sink.Extent.Text -replace '\s+', ' ')))
                    }
                }
            }

            $findings | Should -BeNullOrEmpty -Because 'a credential held in a variable must not reach a log line, a file or an exception message; wrap text you cannot vouch for in Protect-AzDoSecretString'
        }

        It 'Never writes a secret-bearing property or the result of a token Get() to a log, a file or an error message' {
            $findings = [System.Collections.Generic.List[String]]::new()

            foreach ($sink in (Get-SinkNode -Path $Path))
            {
                $members = $sink.FindAll({ param ($node) $node -is [System.Management.Automation.Language.MemberExpressionAst] }, $true)

                foreach ($member in $members)
                {
                    $memberName = [String]$member.Member.Extent.Text

                    $isSecretProperty = ($memberName -in $script:secretMembers)
                    $isTokenGet       = ($member -is [System.Management.Automation.Language.InvokeMemberExpressionAst]) -and
                                        ($memberName -eq 'Get') -and ($member.Expression.Extent.Text -match '(?i)token')

                    if (($isSecretProperty -or $isTokenGet) -and (-not (Test-IsRedacted -Node $member)))
                    {
                        $findings.Add(('line {0}: {1} in: {2}' -f $sink.Extent.StartLineNumber, $member.Extent.Text, ($sink.Extent.Text -replace '\s+', ' ')))
                    }
                }
            }

            $findings | Should -BeNullOrEmpty -Because 'the plain token must only ever be used to build the Authorization header'
        }
    }

    Context 'Request path' {

        It 'Only sends web requests from the audited request path and the token endpoints' {
            # Invoke-AzDevOpsApiRestMethod is the one place that enforces https, checks the host
            # before attaching the credential, and redacts errors. The token endpoint functions
            # talk to the identity provider, not to Azure DevOps, and carry their own handling.
            $allowed = @(
                'Invoke-AzDevOpsApiRestMethod.ps1'
                'Get-AzServicePrincipalToken.ps1'
                'Get-AzServicePrincipalCertificateToken.ps1'
                'Get-AzWorkloadIdentityFederationToken.ps1'
                'Get-AzFederatedAssertion.ps1'
            )

            $root   = Join-Path -Path $Global:RepositoryRoot -ChildPath 'source'
            $direct = foreach ($file in (Get-ChildItem -LiteralPath $root -Recurse -File -Include '*.ps1', '*.psm1'))
            {
                if ($file.FullName -match '[\\/]Examples[\\/]') { continue }

                $ast   = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
                $calls = $ast.FindAll({
                    param ($node)
                    ($node -is [System.Management.Automation.Language.CommandAst]) -and
                    ($node.GetCommandName() -in @('Invoke-RestMethod', 'Invoke-WebRequest', 'irm', 'iwr', 'curl', 'wget'))
                }, $true)

                if (@($calls).Count -gt 0 -and ($file.Name -notin $allowed)) { $file.Name }
            }

            $direct | Should -BeNullOrEmpty -Because 'a request that bypasses Invoke-AzDevOpsApiRestMethod skips the https, host and redaction checks'
        }

        It 'Uses the .NET web clients nowhere' {
            $root = Join-Path -Path $Global:RepositoryRoot -ChildPath 'source'
            $hits = Get-ChildItem -LiteralPath $root -Recurse -File -Include '*.ps1', '*.psm1' |
                Select-String -Pattern 'System\.Net\.WebClient|System\.Net\.Http\.HttpClient\]|HttpWebRequest\]::Create' |
                ForEach-Object { '{0}:{1}' -f $_.Filename, $_.LineNumber }

            $hits | Should -BeNullOrEmpty
        }

        It 'Never runs text as code (Invoke-Expression)' {
            $root = Join-Path -Path $Global:RepositoryRoot -ChildPath 'source'
            $hits = foreach ($file in (Get-ChildItem -LiteralPath $root -Recurse -File -Include '*.ps1', '*.psm1'))
            {
                $ast   = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
                $calls = $ast.FindAll({
                    param ($node)
                    ($node -is [System.Management.Automation.Language.CommandAst]) -and ($node.GetCommandName() -in @('Invoke-Expression', 'iex'))
                }, $true)
                foreach ($call in $calls) { '{0}:{1}' -f $file.Name, $call.Extent.StartLineNumber }
            }

            $hits | Should -BeNullOrEmpty -Because 'cache files and API responses are data; evaluating any of it as code would let whoever controls that data run commands'
        }
    }

    Context 'DSC resource class <Name>' -ForEach $classFileCases {

        It 'Declares every secret-looking DSC property as secret so export and logging redact it' {
            $ast     = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
            $classes = $ast.FindAll({ param ($node) $node -is [System.Management.Automation.Language.TypeDefinitionAst] -and $node.IsClass }, $true)

            # 'Authorization' and 'ConsumerInputs' are property bags that carry keys and passwords.
            $secretNamePattern = '(?i)^(Authorization|ConsumerInputs)$|password|secret|apitoken|accesstoken|credential|privatekey|sharedkey|connectionstring|^pat$'

            foreach ($class in $classes)
            {
                $dscProperties = @($class.Members | Where-Object {
                    ($_ -is [System.Management.Automation.Language.PropertyMemberAst]) -and
                    (@($_.Attributes | Where-Object { $_.TypeName.Name -eq 'DscProperty' }).Count -gt 0)
                })

                $secretLooking = @($dscProperties | Where-Object { $_.Name -match $secretNamePattern } | ForEach-Object { $_.Name })
                if ($secretLooking.Count -eq 0) { continue }

                $method = $class.Members | Where-Object {
                    ($_ -is [System.Management.Automation.Language.FunctionMemberAst]) -and ($_.Name -eq 'GetDscResourceSecretPropertyNames')
                }

                $method | Should -Not -BeNullOrEmpty -Because "$($class.Name) has secret-looking properties ($($secretLooking -join ', ')) and must override GetDscResourceSecretPropertyNames()"

                $declared = @($method.Body.FindAll({ param ($node) $node -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) | ForEach-Object { $_.Value })

                foreach ($name in $secretLooking)
                {
                    $declared | Should -Contain $name -Because "$($class.Name).$name looks like a secret and would otherwise be exported and logged in plain text"
                }
            }
        }
    }

    Context 'Credentials committed to the repository: <Name>' -ForEach $literalFileCases {

        It 'Contains nothing shaped like a real credential' {
            # Deliberately fake fixtures. Each entry is a file and the reason it is safe.
            $knownFixtures = @{
                # A JWT whose payload is {"sub":"1234567890"} with the signature 'abc-DEF_123=='.
                'ConvertFrom-AzDoSecureString.tests.ps1' = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9' + '.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abc-DEF_123=='
            }

            $patterns = [ordered]@{
                'JSON Web Token'                    = 'eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{6,}'
                'Azure DevOps PAT (52 characters)'  = '(?<![A-Za-z0-9])[a-z2-7]{52}(?![A-Za-z0-9])'
                'Azure DevOps PAT (84 characters)'  = '(?<![A-Za-z0-9])[A-Za-z0-9]{76}AZDO[A-Za-z0-9]{4}(?![A-Za-z0-9])'
                'Private key'                       = '-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----'
                'Entra ID client secret'            = '(?<![A-Za-z0-9])[A-Za-z0-9_~.\-]{3}8Q~[A-Za-z0-9_~.\-]{31,34}(?![A-Za-z0-9])'
                'GitHub token'                      = '(?<![A-Za-z0-9])gh[pousr]_[A-Za-z0-9]{36,}'
            }

            $content = Get-Content -LiteralPath $Path -Raw
            if ([String]::IsNullOrEmpty($content)) { return }

            $fixture = $knownFixtures[(Split-Path -Path $Path -Leaf)]
            if ($fixture) { $content = $content.Replace($fixture, '') }

            foreach ($kind in $patterns.Keys)
            {
                $found = [regex]::Matches($content, $patterns[$kind], [System.Text.RegularExpressions.RegexOptions]::None)
                @($found | ForEach-Object { $_.Value.Substring(0, [Math]::Min(12, $_.Value.Length)) + '...' }) |
                    Should -BeNullOrEmpty -Because "a $kind must never be committed; if this one is real, revoke it now, and build test values at run time instead"
            }
        }
    }
}

Describe 'Secret leakage: behaviour' -Tag 'Unit', 'Security' {

    BeforeAll {

        # Get-FunctionItem builds the file index that Import-Enums and Get-ClassFilePath read.
        $files = Get-FunctionItem @(
            'Invoke-AzDevOpsApiRestMethod.ps1', 'Add-AuthenticationHTTPHeader.ps1', 'Test-AzDevOpsApiHttpRequestHeader.ps1',
            'Get-AzDevOpsApiVersion.ps1', 'Test-AzDoApiHost.ps1', 'Protect-AzDoSecretString.ps1', 'Protect-AzDoCacheSecret.ps1',
            'Protect-AzDoCachePath.ps1', 'Test-AzDoIsWindows.ps1', 'Export-CacheObject.ps1', 'Get-AzDoCacheObjects.ps1', 'Set-CacheFileStamp.ps1', 'Test-CacheFileStamp.ps1',
            'ConvertTo-Base64String.ps1', 'ConvertFrom-AzDoSecureString.ps1', 'Add-AzDoLogFileEntry.ps1',
            'Get-AzServicePrincipalToken.ps1', 'Get-AzWorkloadIdentityFederationToken.ps1', 'Get-AzFederatedAssertion.ps1',
            'Get-AzCliToken.ps1',
            # The cache layer: what puts a value in a cache, and what writes and reads a cache file.
            'Add-CacheItem.ps1', 'Get-CacheObject.ps1', 'Get-CacheKeyIndex.ps1', 'Import-CacheObject.ps1',
            'Write-AzDoCacheFile.ps1', 'Read-AzDoCacheFile.ps1',
            'Get-AzDoCacheFileHeader.ps1', 'Protect-AzDoCacheData.ps1', 'Unprotect-AzDoCacheData.ps1'
        )
        Import-Enums | ForEach-Object { . $_.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '007.APIRateLimit')

        ForEach ($file in $files) { . $file.FullName }

        # The logging proxies share their names with the cmdlets they wrap, so they are loaded by path.
        $proxyDirectory = Join-Path -Path $Global:RepositoryRoot -ChildPath 'source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Helper/Logging/Proxy Functions'
        $script:proxyFiles = @(Get-ChildItem -LiteralPath $proxyDirectory -Filter '*.ps1')

        # Canaries: built at run time, shaped like the real thing, and unmistakable in any output.
        $script:canaryPat       = ('canary7pat' * 6).Substring(0, 52)
        $script:canaryBasic     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($script:canaryPat)"))
        $script:canaryJwt       = 'eyJ' + ('Q0FOQVJZand0' * 3) + '.eyJ' + ('Q0FOQVJZcGF5bG9hZA' * 3) + '.' + ('Q0FOQVJZc2ln' * 4)
        $script:canarySecret    = 'CANARY~client.secret-Value_0123456789'
        $script:canaryVariable  = 'CANARY-variable-group-secret-value'
        $script:canaries        = @($script:canaryPat, $script:canaryBasic, $script:canaryJwt, $script:canarySecret, [Uri]::EscapeDataString($script:canarySecret), $script:canaryVariable)

        function Assert-NoCanary
        {
            param ([String]$Text, [String]$Because)

            foreach ($canary in $script:canaries)
            {
                $Text.Contains($canary) | Should -BeFalse -Because "$Because (found '$($canary.Substring(0, 10))...')"
            }
        }

        $script:savedEnvironment = @{
            AZDODSC_CACHE_DIRECTORY      = $env:AZDODSC_CACHE_DIRECTORY
            AZDO_VERBOSELOGGING_FILEPATH = $env:AZDO_VERBOSELOGGING_FILEPATH
            AZDO_WARNINGLOGGING_FILEPATH = $env:AZDO_WARNINGLOGGING_FILEPATH
            AZDO_ERRORLOGGING_FILEPATH   = $env:AZDO_ERRORLOGGING_FILEPATH
            AZDODSC_ALLOWED_API_HOSTS    = $env:AZDODSC_ALLOWED_API_HOSTS
        }
        $script:savedToken        = $Global:DSCAZDO_AuthenticationToken
        $script:savedOrganization = $Global:DSCAZDO_OrganizationName
        $script:savedRateLimit    = $Global:DSCAZDO_APIRateLimit

        $env:AZDODSC_ALLOWED_API_HOSTS     = $null
        $Global:DSCAZDO_OrganizationName   = 'canary-org'
        $Global:DSCAZDO_AuthenticationToken = [PersonalAccessToken]::new($script:canaryPat)
        $Global:DSCAZDO_APIRateLimit       = $null

        $script:apiCall = @{
            ApiUri          = 'https://dev.azure.com/canary-org/_apis/projects?api-version=7.1'
            HttpMethod      = 'Get'
            RetryAttempts   = 0
            RetryIntervalMs = 250
        }
    }

    AfterAll {
        foreach ($name in $script:savedEnvironment.Keys)
        {
            Set-Item -Path "env:$name" -Value $script:savedEnvironment[$name]
        }
        $Global:DSCAZDO_AuthenticationToken = $script:savedToken
        $Global:DSCAZDO_OrganizationName    = $script:savedOrganization
        $Global:DSCAZDO_APIRateLimit        = $script:savedRateLimit
    }

    Context 'The canary is live' {

        It 'Really sends the canary credential, so the checks below are searching for something real' {
            $script:sentAuthorization = $null
            Mock -CommandName Invoke-RestMethod -MockWith { $script:sentAuthorization = $Headers.Authorization; return @{ value = @() } }

            $null = Invoke-AzDevOpsApiRestMethod @script:apiCall

            $script:sentAuthorization | Should -Match ([regex]::Escape($script:canaryBasic))
        }
    }

    Context 'Azure DevOps API calls' {

        It 'Leaks nothing to any output stream on a successful call with -Verbose' {
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ value = @() } }

            $output = Invoke-AzDevOpsApiRestMethod @script:apiCall -Verbose *>&1 | Out-String

            Assert-NoCanary -Text $output -Because 'a successful call must not print the credential'
        }

        It 'Leaks nothing when the server echoes the request, credential included, in its error' {
            Mock -CommandName Invoke-RestMethod -MockWith {
                throw "400 Bad Request. Received headers: Authorization=$($Headers.Authorization); also saw Bearer $($script:canaryJwt) and client_secret=$($script:canarySecret)"
            }

            $thrown = $null
            $output = try { Invoke-AzDevOpsApiRestMethod @script:apiCall -Verbose *>&1 | Out-String } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $text = "$output`n$($thrown | Out-String)`n$($thrown.Exception.Message)`n$($thrown.ScriptStackTrace)"
            $text | Should -Match '400 Bad Request'
            Assert-NoCanary -Text $text -Because 'an API error must not carry the credential into the DSC log'
        }

        It 'Leaves no credential behind in the header table the caller passed in' {
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ value = @() } }
            $headers = @{ Metadata = 'true' }

            $null = Invoke-AzDevOpsApiRestMethod @script:apiCall -HttpHeaders $headers

            Assert-NoCanary -Text ($headers | Out-String) -Because 'the Authorization header is cleared after each request'
        }

        It 'Refuses to hand the credential to a host that is not Azure DevOps' {
            Mock -CommandName Invoke-RestMethod -MockWith { return @{ value = @() } }
            $call = $script:apiCall.Clone()
            $call.ApiUri = 'https://dev.azure.com.attacker.example/canary-org/_apis/projects'

            { Invoke-AzDevOpsApiRestMethod @call } | Should -Throw '*Refusing to send the Azure DevOps credential*'
            Should -Invoke -CommandName Invoke-RestMethod -Exactly 0
        }

        It 'Escapes a continuation token from the response so it cannot rewrite the next request' {
            $script:requestedUris = [System.Collections.Generic.List[String]]::new()
            Mock -CommandName Invoke-RestMethod -MockWith {
                $script:requestedUris.Add([String]$Uri)
                if ($script:requestedUris.Count -eq 1)
                {
                    Set-Variable -Name responseHeaders -Value @{ 'x-ms-continuationtoken' = 'abc&api-version=1.0&$top=999999#fragment' } -Scope Global
                }
                else
                {
                    Set-Variable -Name responseHeaders -Value @{} -Scope Global
                }
                return @{ value = @() }
            }

            try
            {
                $null = Invoke-AzDevOpsApiRestMethod @script:apiCall
            }
            finally
            {
                Remove-Variable -Name responseHeaders -Scope Global -ErrorAction SilentlyContinue
            }

            $script:requestedUris.Count | Should -Be 2
            $second = [System.Uri]$script:requestedUris[1]
            $second.Host     | Should -Be 'dev.azure.com'
            $second.Fragment | Should -BeNullOrEmpty
            $second.Query    | Should -Be '?api-version=7.1&continuationToken=abc%26api-version%3D1.0%26%24top%3D999999%23fragment'
        }
    }

    Context 'Token requests' {

        It 'Leaks nothing when the service principal token request fails and the error echoes the request body' {
            Mock -CommandName Invoke-RestMethod -MockWith { throw "AADSTS7000215: Invalid client secret. Request body was: $Body" }

            $thrown = $null
            try { Get-AzServicePrincipalToken -OrganizationName 'canary-org' -TenantId 'tenant' -ClientId 'client' -ClientSecret $script:canarySecret } catch { $thrown = $_ }

            $thrown.Exception.Message | Should -Match 'AADSTS7000215'
            Assert-NoCanary -Text "$($thrown | Out-String)`n$($thrown.Exception.Message)" -Because 'a failed token request must not print the client secret'
        }

        It 'Leaks nothing when the workload identity token request fails and the error echoes the assertion' {
            Mock -CommandName Invoke-RestMethod -MockWith { throw "AADSTS70021: No matching federated identity record. Request body was: $Body" }

            $thrown = $null
            try { Get-AzWorkloadIdentityFederationToken -OrganizationName 'canary-org' -TenantId 'tenant' -ClientId 'client' -FederatedToken $script:canaryJwt } catch { $thrown = $_ }

            $thrown.Exception.Message | Should -Match 'AADSTS70021'
            Assert-NoCanary -Text "$($thrown | Out-String)`n$($thrown.Exception.Message)" -Because 'a failed token request must not print the federated token'
        }

        It 'Leaks nothing when the Azure CLI output cannot be parsed' {
            Mock -CommandName Get-Command -MockWith { return [PSCustomObject]@{ Name = 'az' } } -ParameterFilter { $Name -eq 'az' }
            Mock -CommandName Invoke-AzCLICommand -MockWith {
                return [PSCustomObject]@{ Output = "WARNING: banner`n{`"accessToken`": `"$($script:canaryJwt)`", `"tokenType`": `"Bearer`""; ExitCode = 0 }
            }

            $thrown = $null
            try { Get-AzCliToken -OrganizationName 'canary-org' } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            Assert-NoCanary -Text "$($thrown | Out-String)`n$($thrown.Exception.Message)" -Because 'the az output holds the access token'
        }
    }

    Context 'The token object' {

        It 'Does not reveal the credential when rendered as <Rendering>' -ForEach @(
            @{ Rendering = 'a string';         Script = { param ($t) "$t" } }
            @{ Rendering = 'Out-String';       Script = { param ($t) $t | Out-String } }
            @{ Rendering = 'Format-List *';    Script = { param ($t) $t | Format-List -Property * -Force | Out-String } }
            @{ Rendering = 'ConvertTo-Json';   Script = { param ($t) $t | ConvertTo-Json -Depth 5 } }
            @{ Rendering = 'Select-Object *';  Script = { param ($t) $t | Select-Object -Property * | Out-String } }
            @{ Rendering = 'ConvertTo-Csv';    Script = { param ($t) $t | ConvertTo-Csv | Out-String } }
        ) {
            $text = & $Script $Global:DSCAZDO_AuthenticationToken

            Assert-NoCanary -Text ([String]$text) -Because "the token object is rendered by anything that logs a variable ($Rendering)"
        }

        It 'Refuses to return the plain token outside the request path' {
            { $Global:DSCAZDO_AuthenticationToken.Get() } | Should -Throw '*Access Denied*'
        }

        It 'Is not written in plain text when serialized on Windows' -Skip:(-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $path = Join-Path -Path $TestDrive -ChildPath 'token.clixml'
            $Global:DSCAZDO_AuthenticationToken | Export-Clixml -LiteralPath $path -Depth 5

            $text     = Get-Content -LiteralPath $path -Raw
            $utf16Hex = -join ([Text.Encoding]::Unicode.GetBytes($script:canaryBasic) | ForEach-Object { $_.ToString('x2') })

            Assert-NoCanary -Text $text -Because 'ModuleSettings.clixml is written the same way'
            $text.ToLowerInvariant().Contains($utf16Hex) | Should -BeFalse -Because 'DPAPI must encrypt the SecureString, not merely hex-encode it'
        }
    }

    Context 'Log files' {

        BeforeAll {
            ForEach ($proxy in $script:proxyFiles) { . $proxy.FullName }

            $script:logDirectory = Join-Path -Path $TestDrive -ChildPath 'logs'
            $null = New-Item -Path $script:logDirectory -ItemType Directory -Force

            $env:AZDO_VERBOSELOGGING_FILEPATH = Join-Path -Path $script:logDirectory -ChildPath 'verbose.log'
            $env:AZDO_WARNINGLOGGING_FILEPATH = Join-Path -Path $script:logDirectory -ChildPath 'warning.log'
            $env:AZDO_ERRORLOGGING_FILEPATH   = Join-Path -Path $script:logDirectory -ChildPath 'error.log'

            $message = "request failed. Authorization: Basic $($script:canaryBasic); Bearer $($script:canaryJwt); client_secret=$($script:canarySecret); pat $($script:canaryPat)"

            $script:streamOutput = & {
                Write-Verbose $message -Verbose
                Write-Warning $message
                Write-Error $message -ErrorAction Continue
            } *>&1 | Out-String
        }

        AfterAll {
            $env:AZDO_VERBOSELOGGING_FILEPATH = $null
            $env:AZDO_WARNINGLOGGING_FILEPATH = $null
            $env:AZDO_ERRORLOGGING_FILEPATH   = $null
        }

        It 'Keeps the credential out of the verbose, warning and error streams' {
            $script:streamOutput | Should -Match 'request failed'
            Assert-NoCanary -Text $script:streamOutput -Because 'DSC captures these streams into its own logs'
        }

        It 'Keeps the credential out of the <Name> log file' -ForEach @(
            @{ Name = 'verbose' }
            @{ Name = 'warning' }
            @{ Name = 'error' }
        ) {
            $path = Join-Path -Path $script:logDirectory -ChildPath "$Name.log"

            Test-Path -LiteralPath $path | Should -BeTrue
            $text = Get-Content -LiteralPath $path -Raw
            $text | Should -Match 'request failed'
            $text | Should -Match '<redacted>'
            Assert-NoCanary -Text $text -Because 'log files outlive the run and are read by other tools'
        }

        It 'Creates the <Name> log file readable by its owner only' -Skip:([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) -ForEach @(
            @{ Name = 'verbose' }
            @{ Name = 'warning' }
            @{ Name = 'error' }
        ) {
            $path = Join-Path -Path $script:logDirectory -ChildPath "$Name.log"

            [String](Get-Item -LiteralPath $path).UnixMode | Should -Be '-rw-------'
        }
    }

    Context 'Cache files' {

        BeforeAll {
            $env:AZDODSC_CACHE_DIRECTORY = Join-Path -Path $TestDrive -ChildPath 'cache'
            $null = New-Item -Path $env:AZDODSC_CACHE_DIRECTORY -ItemType Directory -Force
            $script:cacheDirectory = Join-Path -Path $env:AZDODSC_CACHE_DIRECTORY -ChildPath 'Cache'

            # What a cache file holds, as text. The file is encrypted on Windows, so it is read
            # back the way the module reads it and serialized again.
            function Get-CacheFileText
            {
                param ([string]$CacheType)
                $path = Join-Path -Path $script:cacheDirectory -ChildPath "$CacheType.clixml"
                return [System.Management.Automation.PSSerializer]::Serialize((Read-AzDoCacheFile -Path $path), 6)
            }

            # Everything a cache holds in memory, as text.
            function Get-CacheMemoryText
            {
                param ([string]$CacheType)
                $cache = Get-Variable -Name "AzDo$CacheType" -Scope Global -ValueOnly
                return [System.Management.Automation.PSSerializer]::Serialize(@($cache), 6)
            }

            $script:echoedVariableGroup     = '{"id":1,"name":"Group","variables":{"PLAIN":{"value":"plain-value"},"API_KEY":{"value":"' + $script:canaryVariable + '","isSecret":true}}}'
            $script:echoedServiceConnection = '{"id":"e1","name":"Connection","authorization":{"scheme":"ServicePrincipal","parameters":{"tenantid":"tenant-value","serviceprincipalid":"client","serviceprincipalkey":"' + $script:canarySecret + '"}}}'
            $script:echoedAuditStream       = '{"id":3,"consumerType":"AzureMonitorLogs","consumerInputs":{"WorkspaceId":"workspace-value","SharedKey":"' + $script:canarySecret + '"}}'
        }

        BeforeEach {
            foreach ($type in 'LiveVariableGroups', 'LiveServiceConnections', 'LiveAuditStreams')
            {
                Remove-Variable -Name "AzDo$type" -Scope Global -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name AzDoCacheKeyIndex -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name AzDoCacheFileStamp -Scope Global -ErrorAction SilentlyContinue
            Get-ChildItem -LiteralPath $script:cacheDirectory -File -ErrorAction SilentlyContinue | Remove-Item -Force
        }

        AfterAll {
            foreach ($type in 'LiveVariableGroups', 'LiveServiceConnections', 'LiveAuditStreams')
            {
                Remove-Variable -Name "AzDo$type" -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Never holds a secret echoed by a write response in memory: <CacheType>' -ForEach @(
            @{ CacheType = 'LiveVariableGroups';     Echoed = 'echoedVariableGroup';     Kept = 'plain-value' }
            @{ CacheType = 'LiveServiceConnections'; Echoed = 'echoedServiceConnection'; Kept = 'tenant-value' }
            @{ CacheType = 'LiveAuditStreams';       Echoed = 'echoedAuditStream';       Kept = 'workspace-value' }
        ) {
            $value = (Get-Variable -Name $Echoed -Scope Script -ValueOnly) | ConvertFrom-Json

            Add-CacheItem -Key 'Project\Item' -Value $value -Type $CacheType

            $text = Get-CacheMemoryText -CacheType $CacheType
            $text | Should -Match $Kept
            Assert-NoCanary -Text $text -Because 'a cache must not hold a secret in memory'
        }

        It 'Removes a secret from a cache file written by an earlier version, in memory and on disk' {
            # An earlier version of the module wrote the echoed secret to the file as it was.
            $legacy = [System.Collections.Generic.List[CacheItem]]::new()
            $legacy.Add([CacheItem]::new('Project\Group', ($script:echoedVariableGroup | ConvertFrom-Json)))
            $null = New-Item -Path $script:cacheDirectory -ItemType Directory -Force
            $path = Join-Path -Path $script:cacheDirectory -ChildPath 'LiveVariableGroups.clixml'
            Export-Clixml -InputObject $legacy -Depth 6 -LiteralPath $path
            (Get-Content -LiteralPath $path -Raw) | Should -Match ([regex]::Escape($script:canaryVariable))

            $null = Import-CacheObject -CacheType 'LiveVariableGroups' -WarningAction SilentlyContinue

            Assert-NoCanary -Text (Get-CacheMemoryText -CacheType 'LiveVariableGroups') -Because 'an imported cache must not hold a secret in memory'
            $text = Get-CacheFileText -CacheType 'LiveVariableGroups'
            $text | Should -Match 'plain-value'
            Assert-NoCanary -Text $text -Because 'the file must be rewritten without the secret'
            Assert-NoCanary -Text (Get-Content -LiteralPath $path -Raw) -Because 'the file must be rewritten without the secret'
        }

        It 'Encrypts a cache file on Windows so its content cannot be read from the file' -Skip:(-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $cache = [System.Collections.Generic.List[CacheItem]]::new()
            $cache.Add([CacheItem]::new('Project\Connection', ('{"id":"e1","name":"plain-connection-name"}' | ConvertFrom-Json)))

            Export-CacheObject -CacheType 'LiveServiceConnections' -Content $cache

            $path  = Join-Path -Path $script:cacheDirectory -ChildPath 'LiveServiceConnections.clixml'
            $bytes = [System.IO.File]::ReadAllBytes($path)
            foreach ($encoding in [System.Text.Encoding]::UTF8, [System.Text.Encoding]::Unicode)
            {
                $encoding.GetString($bytes) | Should -Not -Match 'plain-connection-name'
            }
            (Get-CacheFileText -CacheType 'LiveServiceConnections') | Should -Match 'plain-connection-name'
        }

        It 'Never writes a secret variable value echoed by a write response to the variable group cache' {
            $echoed = ('{"id":1,"name":"Group","variables":{"PLAIN":{"value":"plain-value"},"API_KEY":{"value":"' + $script:canaryVariable + '","isSecret":true}}}') | ConvertFrom-Json
            $cache  = [System.Collections.Generic.List[CacheItem]]::new()
            $cache.Add([CacheItem]::new('Project\Group', $echoed))

            Export-CacheObject -CacheType 'LiveVariableGroups' -Content $cache

            $text = Get-CacheFileText -CacheType 'LiveVariableGroups'
            $text | Should -Match 'plain-value'
            $text | Should -Match 'API_KEY'
            Assert-NoCanary -Text $text -Because 'a cache file must not hold a secret variable value'
        }

        It 'Never writes a service connection key echoed by a write response to the service connection cache' {
            $echoed = ('{"id":"e1","name":"Connection","authorization":{"scheme":"ServicePrincipal","parameters":{"tenantid":"tenant-value","serviceprincipalid":"client","serviceprincipalkey":"' + $script:canarySecret + '"}}}') | ConvertFrom-Json
            $cache  = [System.Collections.Generic.List[CacheItem]]::new()
            $cache.Add([CacheItem]::new('Project\Connection', $echoed))

            Export-CacheObject -CacheType 'LiveServiceConnections' -Content $cache

            $text = Get-CacheFileText -CacheType 'LiveServiceConnections'
            $text | Should -Match 'tenant-value'
            Assert-NoCanary -Text $text -Because 'a cache file must not hold a service connection key'
        }

        It 'Never writes an audit stream shared key echoed by a write response to the audit stream cache' {
            $echoed = ('{"id":3,"consumerType":"AzureMonitorLogs","consumerInputs":{"WorkspaceId":"workspace-value","SharedKey":"' + $script:canarySecret + '"}}') | ConvertFrom-Json
            $cache  = [System.Collections.Generic.List[CacheItem]]::new()
            $cache.Add([CacheItem]::new('Stream', $echoed))

            Export-CacheObject -CacheType 'LiveAuditStreams' -Content $cache

            $text = Get-CacheFileText -CacheType 'LiveAuditStreams'
            $text | Should -Match 'workspace-value'
            Assert-NoCanary -Text $text -Because 'a cache file must not hold an audit stream key'
        }

        It 'Writes cache files and the cache directory readable by their owner only' -Skip:([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            # Start without the directory, so the module creates it as it would on a first run.
            Remove-Item -LiteralPath $script:cacheDirectory -Recurse -Force -ErrorAction SilentlyContinue
            $cache = [System.Collections.Generic.List[CacheItem]]::new()
            $cache.Add([CacheItem]::new('Project\Group', ('{"id":1,"name":"Group"}' | ConvertFrom-Json)))
            Export-CacheObject -CacheType 'LiveVariableGroups' -Content $cache

            [String](Get-Item -LiteralPath $script:cacheDirectory).UnixMode | Should -Be 'drwx------'

            $files = @(Get-ChildItem -LiteralPath $script:cacheDirectory -File)
            $files.Count | Should -BeGreaterThan 0
            foreach ($file in $files)
            {
                [String]$file.UnixMode | Should -Be '-rw-------' -Because "$($file.Name) names the identities permission grants resolve to"
            }
        }
    }
}
