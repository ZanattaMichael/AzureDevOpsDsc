$currentFile = $MyInvocation.MyCommand.Path

Describe 'Protect-AzDoCacheSecret' -Tag 'Unit', 'Helper', 'Security' {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Protect-AzDoCacheSecret.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    Context 'LiveVariableGroups' {

        It 'Blanks the value of a secret variable and keeps everything else (API-shaped object)' {
            $entry = [PSCustomObject]@{
                Key   = 'Project\Group'
                Value = '{"id":7,"name":"Group","variables":{"PLAIN":{"value":"visible"},"API_KEY":{"value":"echoed-secret","isSecret":true},"NOT_SECRET":{"value":"kept","isSecret":false}}}' | ConvertFrom-Json
            }

            Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content @($entry)

            $entry.Value.variables.API_KEY.value    | Should -BeNullOrEmpty
            $entry.Value.variables.API_KEY.isSecret | Should -BeTrue
            $entry.Value.variables.PLAIN.value      | Should -Be 'visible'
            $entry.Value.variables.NOT_SECRET.value | Should -Be 'kept'
            $entry.Value.id                         | Should -Be 7
        }

        It 'Blanks the value of a secret variable held in hashtables' {
            $entry = [PSCustomObject]@{
                Key   = 'Project\Group'
                Value = @{ name = 'Group'; variables = @{ PLAIN = 'visible'; API_KEY = @{ value = 'echoed-secret'; isSecret = $true } } }
            }

            Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content @($entry)

            $entry.Value.variables.API_KEY.value | Should -BeNullOrEmpty
            $entry.Value.variables.PLAIN         | Should -Be 'visible'
        }
    }

    Context 'LiveServiceConnections' {

        It 'Blanks the secret authorization parameter <Name>' -ForEach @(
            @{ Name = 'serviceprincipalkey' }
            @{ Name = 'password' }
            @{ Name = 'apitoken' }
            @{ Name = 'AccessToken' }
            @{ Name = 'servicePrincipalCertificate' }
            @{ Name = 'nugetkey' }
        ) {
            $parameters = @{ tenantid = 'tenant'; serviceprincipalid = 'client'; $Name = 'echoed-secret' }
            $entry = [PSCustomObject]@{
                Key   = 'Project\Connection'
                Value = [PSCustomObject]@{ name = 'Connection'; authorization = [PSCustomObject]@{ scheme = 'ServicePrincipal'; parameters = [PSCustomObject]$parameters } }
            }

            Protect-AzDoCacheSecret -CacheType 'LiveServiceConnections' -Content @($entry)

            $entry.Value.authorization.parameters.$Name              | Should -BeNullOrEmpty
            $entry.Value.authorization.parameters.tenantid           | Should -Be 'tenant'
            $entry.Value.authorization.parameters.serviceprincipalid | Should -Be 'client'
            $entry.Value.authorization.scheme                        | Should -Be 'ServicePrincipal'
        }
    }

    Context 'LiveAuditStreams' {

        It 'Blanks the secret consumer inputs and keeps the others' {
            $entry = [PSCustomObject]@{
                Key   = 'Stream'
                Value = [PSCustomObject]@{ consumerType = 'AzureMonitorLogs'; consumerInputs = [PSCustomObject]@{ WorkspaceId = 'workspace'; SharedKey = 'echoed-secret' } }
            }

            Protect-AzDoCacheSecret -CacheType 'LiveAuditStreams' -Content @($entry)

            $entry.Value.consumerInputs.SharedKey   | Should -BeNullOrEmpty
            $entry.Value.consumerInputs.WorkspaceId | Should -Be 'workspace'
        }
    }

    Context 'Abnormal content' {

        It 'Leaves a cache type that holds no secrets untouched' {
            $entry = [PSCustomObject]@{ Key = 'k'; Value = [PSCustomObject]@{ password = 'not-touched'; variables = @{ A = @{ value = 'v'; isSecret = $true } } } }

            Protect-AzDoCacheSecret -CacheType 'LiveProjects' -Content @($entry)

            $entry.Value.password          | Should -Be 'not-touched'
            $entry.Value.variables.A.value | Should -Be 'v'
        }

        It 'Does not throw on <Description>' -ForEach @(
            @{ Description = 'null content';              Content = $null }
            @{ Description = 'an empty list';             Content = @() }
            @{ Description = 'a null entry';              Content = @($null) }
            @{ Description = 'an entry with no value';    Content = @([PSCustomObject]@{ Key = 'k'; Value = $null }) }
            @{ Description = 'a value with no variables'; Content = @([PSCustomObject]@{ Key = 'k'; Value = [PSCustomObject]@{ name = 'n' } }) }
            @{ Description = 'variables that is a string'; Content = @([PSCustomObject]@{ Key = 'k'; Value = [PSCustomObject]@{ variables = 'unexpected' } }) }
            @{ Description = 'a scalar value';            Content = @([PSCustomObject]@{ Key = 'k'; Value = 42 }) }
        ) {
            { Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content $Content }     | Should -Not -Throw
            { Protect-AzDoCacheSecret -CacheType 'LiveServiceConnections' -Content $Content } | Should -Not -Throw
            { Protect-AzDoCacheSecret -CacheType 'LiveAuditStreams' -Content $Content }       | Should -Not -Throw
        }
    }

    Context 'A single entry and -PassThru' {

        It 'Accepts one entry that is not wrapped in an array' {
            $entry = [PSCustomObject]@{
                Key   = 'Project\Group'
                Value = '{"variables":{"API_KEY":{"value":"echoed-secret","isSecret":true}}}' | ConvertFrom-Json
            }

            Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content $entry

            $entry.Value.variables.API_KEY.value | Should -BeNullOrEmpty
        }

        It 'Returns nothing without -PassThru' {
            $entry = [PSCustomObject]@{ Key = 'k'; Value = '{"variables":{"API_KEY":{"value":"echoed-secret","isSecret":true}}}' | ConvertFrom-Json }

            Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content $entry | Should -BeNullOrEmpty
            Protect-AzDoCacheSecret -CacheType 'LiveProjects' -Content $entry       | Should -BeNullOrEmpty
        }

        It 'Returns the number of values it blanked with -PassThru' {
            $entries = @(
                [PSCustomObject]@{ Key = 'a'; Value = '{"variables":{"ONE":{"value":"s1","isSecret":true},"TWO":{"value":"s2","isSecret":true},"PLAIN":{"value":"v"}}}' | ConvertFrom-Json }
                [PSCustomObject]@{ Key = 'b'; Value = '{"variables":{"THREE":{"value":"s3","isSecret":true}}}' | ConvertFrom-Json }
            )

            Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content $entries -PassThru | Should -Be 3
        }

        It 'Returns 0 with -PassThru when the secrets are already blank, as a read returns them' {
            $entry = [PSCustomObject]@{ Key = 'a'; Value = '{"variables":{"ONE":{"value":null,"isSecret":true}}}' | ConvertFrom-Json }

            Protect-AzDoCacheSecret -CacheType 'LiveVariableGroups' -Content $entry -PassThru | Should -Be 0
        }

        It 'Returns 0 with -PassThru for <Description>' -ForEach @(
            @{ Description = 'a cache type that holds no secrets'; CacheType = 'LiveProjects';       Content = @([PSCustomObject]@{ Key = 'k'; Value = 1 }) }
            @{ Description = 'null content';                       CacheType = 'LiveVariableGroups'; Content = $null }
        ) {
            Protect-AzDoCacheSecret -CacheType $CacheType -Content $Content -PassThru | Should -Be 0
        }
    }
}
