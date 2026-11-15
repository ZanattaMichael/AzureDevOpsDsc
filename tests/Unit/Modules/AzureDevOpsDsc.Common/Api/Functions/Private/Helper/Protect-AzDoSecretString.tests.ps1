$currentFile = $MyInvocation.MyCommand.Path

Describe 'Protect-AzDoSecretString' -Tag 'Unit', 'Helper', 'Security' {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Protect-AzDoSecretString.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
        . (Get-FunctionItem 'Register-AzDoSecretValue.ps1').FullName

        # Built at run time so no credential-shaped literal sits in the repository.
        $script:jwt       = 'eyJ' + ('hbGciOiJSUzI1NiIs' * 2) + '.eyJ' + ('hdWQiOiI0OTliODRh' * 3) + '.' + ('c2lnbmF0dXJl' * 4)
        $script:classicPat = ('abcdefghijklmnopqrstuvwxyz234567' * 2).Substring(0, 52)
        $script:newPat     = ('Ab1' * 26).Substring(0, 76) + 'AZDO' + 'x9Zq'
        $script:basic      = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($script:classicPat)"))
    }

    Context 'Credentials are removed' {

        It 'Redacts a Bearer token and keeps the scheme' {
            $result = Protect-AzDoSecretString -InputString "Authorization: Bearer $($script:jwt)"
            $result | Should -Be 'Authorization: Bearer <redacted>'
        }

        It 'Redacts a Basic credential and keeps the scheme' {
            $result = Protect-AzDoSecretString -InputString "Authorization: Basic $($script:basic) was sent"
            $result | Should -Be 'Authorization: Basic <redacted> was sent'
        }

        It 'Redacts a bare JSON Web Token' {
            $result = Protect-AzDoSecretString -InputString "token was $($script:jwt)."
            $result | Should -Not -Match 'eyJ'
            $result | Should -Match '<redacted>'
        }

        It 'Redacts a 52-character personal access token' {
            Protect-AzDoSecretString -InputString "PAT $($script:classicPat) rejected" | Should -Be 'PAT <redacted> rejected'
        }

        It 'Redacts an 84-character personal access token' {
            Protect-AzDoSecretString -InputString "PAT $($script:newPat) rejected" | Should -Be 'PAT <redacted> rejected'
        }

        It 'Redacts the secret in a form-encoded request body and keeps the other fields' {
            $body   = 'grant_type=client_credentials&client_id=11111111-2222&client_secret=s3cr%7Et-V4lue&resource=499b84ac'
            $result = Protect-AzDoSecretString -InputString $body
            $result | Should -Be 'grant_type=client_credentials&client_id=11111111-2222&client_secret=<redacted>&resource=499b84ac'
        }

        It 'Redacts the value of the JSON property <Name>' -ForEach @(
            @{ Name = 'accessToken' }
            @{ Name = 'access_token' }
            @{ Name = 'refresh_token' }
            @{ Name = 'client_assertion' }
            @{ Name = 'password' }
            @{ Name = 'serviceprincipalkey' }
            @{ Name = 'apitoken' }
            @{ Name = 'sharedKey' }
            @{ Name = 'client_secret' }
        ) {
            $json   = '{{"name":"visible","{0}":"hunter2-Value","isSecret":true}}' -f $Name
            $result = Protect-AzDoSecretString -InputString $json
            $result | Should -Not -Match 'hunter2'
            $result | Should -Match '"name":"visible"'
            $result | Should -Match '"isSecret":true'
        }

        It 'Redacts every credential in a message that carries several' {
            $message = "first Bearer $($script:jwt) then password=hunter2 then $($script:classicPat)"
            $result  = Protect-AzDoSecretString -InputString $message
            $result | Should -Be 'first Bearer <redacted> then password=<redacted> then <redacted>'
        }

        It 'Redacts across the lines of a multi-line message' {
            $message = "line one`nAuthorization: Bearer $($script:jwt)`nline three"
            $result  = Protect-AzDoSecretString -InputString $message
            $result | Should -Be "line one`nAuthorization: Bearer <redacted>`nline three"
        }
    }

    Context 'Ordinary text is left alone' {

        It 'Returns "<Text>" unchanged' -ForEach @(
            @{ Text = '[Add-CacheItem] Adding item with key MyProject\MyRepo to the cache of type LiveRepositories.' }
            @{ Text = '[Get-AzDoVariableGroup] Variable group found. isSecret = True' }
            @{ Text = 'Basic authentication is not supported; a Bearer token is required.' }
            @{ Text = 'Basic realm=/var/opt/azcmagent/tokens/0a1b2c3d.key' }
            @{ Text = '[ConvertTo-ACL] Token Name: repoV2/7a1c2f4e-0000-4000-8000-123456789abc/refs/heads/main' }
            @{ Text = 'https://dev.azure.com/org/_apis/projects?api-version=7.1&continuationToken=42' }
            @{ Text = 'Verify TenantId, ClientId, and ClientSecret are correct.' }
            @{ Text = 'Descriptor vssgp.Uy0xLTktMTU1MTM3NDI0NS0xMjA0NDAwOTY5 resolved' }
            @{ Text = 'Project id 7a1c2f4e-0000-4000-8000-123456789abc' }
        ) {
            Protect-AzDoSecretString -InputString $Text | Should -BeExactly $Text
        }

        It 'Returns an empty string for null or empty input' {
            Protect-AzDoSecretString -InputString $null | Should -BeExactly ''
            Protect-AzDoSecretString -InputString ''    | Should -BeExactly ''
        }
    }

    Context 'Secrets the module was given (Register-AzDoSecretValue)' {

        BeforeEach {
            $script:AzDoKnownSecretValues    = $null
            $script:AzDoKnownSecretValueList = $null
        }

        AfterAll {
            $script:AzDoKnownSecretValues    = $null
            $script:AzDoKnownSecretValueList = $null
        }

        It 'Redacts a registered secret that has no recognisable shape' {
            Protect-AzDoSecretString -InputString 'sent hunter2-shapeless to the API' | Should -BeExactly 'sent hunter2-shapeless to the API'

            Register-AzDoSecretValue -Value 'hunter2-shapeless'

            Protect-AzDoSecretString -InputString 'sent hunter2-shapeless to the API' | Should -BeExactly 'sent <redacted> to the API'
        }

        It 'Redacts a registered SecureString' {
            Register-AzDoSecretValue -Value (ConvertTo-SecureString -String 'shapeless-secure-value' -AsPlainText -Force)

            Protect-AzDoSecretString -InputString 'value shapeless-secure-value!' | Should -BeExactly 'value <redacted>!'
        }

        It 'Redacts the JSON-escaped and the URL-escaped form of a registered secret' {
            $secret = 'pa"ss\word &more'
            Register-AzDoSecretValue -Value $secret

            $json = @{ field = $secret } | ConvertTo-Json -Compress
            Protect-AzDoSecretString -InputString $json | Should -BeExactly '{"field":"<redacted>"}'
            Protect-AzDoSecretString -InputString ('x=' + [Uri]::EscapeDataString($secret) + '&y=1') | Should -BeExactly 'x=<redacted>&y=1'
        }

        It 'Replaces the longer of two overlapping secrets whole' {
            Register-AzDoSecretValue -Value 'overlap-secret'
            Register-AzDoSecretValue -Value 'overlap-secret-with-a-tail'

            Protect-AzDoSecretString -InputString 'a overlap-secret-with-a-tail b' | Should -BeExactly 'a <redacted> b'
        }

        It 'Ignores <Name>, which would otherwise wipe ordinary words from every log line' -ForEach @(
            @{ Name = 'a value shorter than eight characters'; Value = 'true' }
            @{ Name = 'an empty string';                       Value = '' }
            @{ Name = 'null';                                  Value = $null }
            @{ Name = 'a value that is not text';              Value = 12345678 }
        ) {
            Register-AzDoSecretValue -Value $Value

            Protect-AzDoSecretString -InputString 'true 12345678 stays' | Should -BeExactly 'true 12345678 stays'
        }

        It 'Matches a registered secret by exact case only' {
            Register-AzDoSecretValue -Value 'CaseSensitiveSecret'

            Protect-AzDoSecretString -InputString 'casesensitivesecret' | Should -BeExactly 'casesensitivesecret'
        }
    }

    Context 'Abnormal input' {

        It 'Handles a very large message quickly' {
            $large   = ('x' * 200000) + " Bearer $($script:jwt) " + ('y ' * 100000)
            $elapsed = Measure-Command { $script:largeResult = Protect-AzDoSecretString -InputString $large }

            $script:largeResult | Should -Not -Match 'eyJ'
            $elapsed.TotalSeconds | Should -BeLessThan 10
        }

        It 'Does not hang on input built to make a pattern backtrack' {
            $hostile = ('eyJ' + ('a' * 5000) + '.') * 20 + ('Bearer ' * 2000) + ('password=' * 2000)
            $elapsed = Measure-Command { $null = Protect-AzDoSecretString -InputString $hostile }

            $elapsed.TotalSeconds | Should -BeLessThan 10
        }
    }
}
