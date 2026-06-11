$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsPipelineEnvironment' -Tag "Unit", "PipelineEnvironment", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsPipelineEnvironment.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 1; name = 'mock-item' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsPipelineEnvironment -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsPipelineEnvironment -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsPipelineEnvironment -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -EnvironmentName 'TestEnv' } | Should -Throw
    }
}
