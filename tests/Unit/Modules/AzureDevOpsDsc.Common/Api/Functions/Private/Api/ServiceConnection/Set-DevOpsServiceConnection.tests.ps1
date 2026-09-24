$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsServiceConnection' -Tag "Unit", "ServiceConnection", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' } | Should -Throw
    }

    Context 'serviceEndpointProjectReferences JSON shape (CLAUDE.md gotcha #7)' {

        It 'Serializes the default single project reference as a JSON array, not an object' {
            Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body -match '"serviceEndpointProjectReferences"\s*:\s*\['
            }
        }

        It 'Serializes two explicit project references as a JSON array' {
            $refs = @(
                @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' },
                @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'shared-conn' }
            )
            Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' -ProjectReferences $refs

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body -match '"serviceEndpointProjectReferences"\s*:\s*\[' -and (($Body | ConvertFrom-Json).serviceEndpointProjectReferences | Measure-Object).Count -eq 2
            }
        }

    }

    Context 'Endpoint url and authorization shape (issue #79)' {

        It 'Sends the url from Data as the top-level url - the update call rejects a body without one' {
            Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' -Data @{ url = 'https://data.example.com' } -Url 'https://existing.example.com'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                ($Body | ConvertFrom-Json).url -eq 'https://data.example.com'
            }
        }

        It 'Falls back to the -Url parameter when Data has no url' {
            Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' -Url 'https://existing.example.com'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                ($Body | ConvertFrom-Json).url -eq 'https://existing.example.com'
            }
        }

        It 'Nests flat credential values under authorization.parameters' {
            Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' -Authorization @{ scheme = 'UsernamePassword'; username = 'u'; password = 'p' }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $auth = ($Body | ConvertFrom-Json).authorization
                $auth.scheme -eq 'UsernamePassword' -and $auth.parameters.username -eq 'u' -and $auth.parameters.password -eq 'p' -and $null -eq $auth.username
            }
        }

        It 'Leaves an already nested authorization unchanged' {
            Set-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionId 'sc-id' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' -Authorization @{ scheme = 'Token'; parameters = @{ apitoken = 't' } }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $auth = ($Body | ConvertFrom-Json).authorization
                $auth.scheme -eq 'Token' -and $auth.parameters.apitoken -eq 't'
            }
        }

    }
}
