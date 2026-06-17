$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsVariableGroup' -Tag "Unit", "VariableGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG' } | Should -Throw
    }

}
