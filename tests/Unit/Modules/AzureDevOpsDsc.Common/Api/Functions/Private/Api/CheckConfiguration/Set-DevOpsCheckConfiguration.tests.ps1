$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsCheckConfiguration' -Tags "Unit", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsCheckConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsCheckConfiguration -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -CheckId 1 -CheckTypeId 'check-type-id' -CheckTypeName 'Approval' -ResourceType 'environment' -ResourceId 'env-id' -Settings @{ approvers = @('user-id') }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PATCH'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsCheckConfiguration -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -CheckId 1 -CheckTypeId 'check-type-id' -CheckTypeName 'Approval' -ResourceType 'environment' -ResourceId 'env-id' -Settings @{ approvers = @('user-id') }
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsCheckConfiguration -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -CheckId 1 -CheckTypeId 'check-type-id' -CheckTypeName 'Approval' -ResourceType 'environment' -ResourceId 'env-id' -Settings @{ approvers = @('user-id') } } | Should -Throw
    }
}
