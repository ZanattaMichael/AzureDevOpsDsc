$currentFile = $MyInvocation.MyCommand.Path

Describe 'List-DevOpsPipelineEnvironments' -Tags "Unit", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-DevOpsPipelineEnvironments.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ value = @(@{ id = 1; name = 'mock-item' }) }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Returns data when the API returns results' {
        $result = List-DevOpsPipelineEnvironments -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Returns null when the API returns no data' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $null } }
        $result = List-DevOpsPipelineEnvironments -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject'
        $result | Should -BeNullOrEmpty
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with GET method' {
        List-DevOpsPipelineEnvironments -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'GET'
        } -Times 1
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { List-DevOpsPipelineEnvironments -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' } | Should -Throw
    }
}
