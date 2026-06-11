$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsTeam' -Tag "Unit", "Team", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsTeam.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 1; name = 'mock-item' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsTeam -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -TeamId 'team-id'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PATCH'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsTeam -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -TeamId 'team-id'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsTeam -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-id' -TeamId 'team-id' } | Should -Throw
    }
}
