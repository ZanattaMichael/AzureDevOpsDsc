$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsPipelineEnvironment' -Tag "Unit", "PipelineEnvironment", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsPipelineEnvironment.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 1; name = 'mock-item' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with DELETE method' {
        Remove-DevOpsPipelineEnvironment -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -EnvironmentId 1
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'DELETE'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Remove-DevOpsPipelineEnvironment -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -EnvironmentId 1
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Remove-DevOpsPipelineEnvironment -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -EnvironmentId 1 } | Should -Throw
    }
}
