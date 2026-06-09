$currentFile = $MyInvocation.MyCommand.Path

Describe 'List-DevOpsAgentPools' -Tags "Unit", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-DevOpsAgentPools.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ value = @(@{ id = 1; name = 'mock-item' }) }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Returns data when the API returns results' {
        $result = List-DevOpsAgentPools -ApiUri 'https://dev.azure.com/myorg'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Returns null when the API returns no data' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $null } }
        $result = List-DevOpsAgentPools -ApiUri 'https://dev.azure.com/myorg'
        $result | Should -BeNullOrEmpty
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with GET method' {
        List-DevOpsAgentPools -ApiUri 'https://dev.azure.com/myorg'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'GET'
        } -Times 1
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { List-DevOpsAgentPools -ApiUri 'https://dev.azure.com/myorg' } | Should -Throw
    }
}
