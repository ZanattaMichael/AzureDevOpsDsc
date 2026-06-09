$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsEnvironmentApproval' -Tags "Unit", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsEnvironmentApproval.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsEnvironmentApproval -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -CheckId 1 -EnvironmentId 2 -ApproverIds @('user-id-1')
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PATCH'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsEnvironmentApproval -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -CheckId 1 -EnvironmentId 2 -ApproverIds @('user-id-1')
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsEnvironmentApproval -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -CheckId 1 -EnvironmentId 2 -ApproverIds @('user-id-1') } | Should -Throw
    }
}
