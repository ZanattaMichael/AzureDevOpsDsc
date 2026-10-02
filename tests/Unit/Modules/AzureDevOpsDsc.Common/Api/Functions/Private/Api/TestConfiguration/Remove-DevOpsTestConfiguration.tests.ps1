$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsTestConfiguration' -Tag "Unit", "TestManagement", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsTestConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod
    }

    It 'sends a DELETE addressed by the testConfiguartionId query parameter, not a path segment' {
        Remove-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'My Project' -TestConfigurationId 700

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and
            $Uri -eq 'https://dev.azure.com/myorg/My%20Project/_apis/testplan/configurations?testConfiguartionId=700&api-version=7.1'
        }
    }

    It 'throws with the configuration id when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { Remove-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -TestConfigurationId 700 } |
            Should -Throw '*id 700*API error*'
    }
}
