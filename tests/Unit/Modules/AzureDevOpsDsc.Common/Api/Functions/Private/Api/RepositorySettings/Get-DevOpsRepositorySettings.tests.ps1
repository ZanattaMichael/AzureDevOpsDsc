$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsRepositorySettings' -Tags "Unit", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsRepositorySettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ value = @(@{ id = 'mock-id'; name = 'mock-name' }) }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Returns data when API returns results' {
        $result = Get-DevOpsRepositorySettings -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -RepositoryId 'repo-id'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Returns null when API returns no data' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $null } }
        $result = Get-DevOpsRepositorySettings -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -RepositoryId 'repo-id'
        $result | Should -BeNullOrEmpty
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with GET method' {
        Get-DevOpsRepositorySettings -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -RepositoryId 'repo-id'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'GET'
        } -Times 1
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Get-DevOpsRepositorySettings -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -RepositoryId 'repo-id' } | Should -Throw
    }

}
