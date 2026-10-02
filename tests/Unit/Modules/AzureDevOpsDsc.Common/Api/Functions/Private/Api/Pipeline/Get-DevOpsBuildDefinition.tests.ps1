$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsBuildDefinition' -Tag "Unit", "Pipeline", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsBuildDefinition.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 42; revision = 3 }
        }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with GET method against the classic build definitions endpoint' {
        Get-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $Method -eq 'GET' -and $Uri -like '*_apis/build/definitions/42*'
        }
    }

    It 'Returns the API response' {
        $result = Get-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42
        $result.id | Should -Be 42
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Get-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 } | Should -Throw
    }
}
