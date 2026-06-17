$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsVariableGroup' -Tag "Unit", "VariableGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with DELETE method' {
        Remove-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-guid' -VariableGroupId 1
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $HttpMethod -eq 'DELETE'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Remove-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-guid' -VariableGroupId 1
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Remove-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectId 'proj-guid' -VariableGroupId 1 } | Should -Throw
    }

}
