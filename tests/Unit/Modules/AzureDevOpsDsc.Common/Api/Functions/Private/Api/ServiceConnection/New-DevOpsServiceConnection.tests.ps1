$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsServiceConnection' -Tag "Unit", "ServiceConnection", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' } | Should -Throw
    }

    Context 'serviceEndpointProjectReferences JSON shape (CLAUDE.md gotcha #7)' {

        It 'Serializes the default single project reference as a JSON array, not an object' {
            New-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body -match '"serviceEndpointProjectReferences"\s*:\s*\['
            }
        }

        It 'Serializes two explicit project references as a JSON array' {
            $refs = @(
                @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' },
                @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'shared-conn' }
            )
            New-DevOpsServiceConnection -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -ProjectName 'TestProject' -ServiceConnectionName 'TestSC' -ServiceConnectionType 'generic' -ProjectReferences $refs

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body -match '"serviceEndpointProjectReferences"\s*:\s*\[' -and (($Body | ConvertFrom-Json).serviceEndpointProjectReferences | Measure-Object).Count -eq 2
            }
        }

    }
}
