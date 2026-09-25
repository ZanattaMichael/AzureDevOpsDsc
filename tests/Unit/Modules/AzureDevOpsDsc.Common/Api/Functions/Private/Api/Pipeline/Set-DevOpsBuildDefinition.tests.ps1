$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsBuildDefinition' -Tag "Unit", "Pipeline", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsBuildDefinition.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 42; revision = 4 }
        }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method against the classic build definitions endpoint' {
        Set-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 -Definition @{ id = 42; revision = 3 }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PUT' -and $Uri -like '*_apis/build/definitions/42*'
        }
    }

    It 'Sends the whole definition object as the body, not a partial one' {
        $definition = @{ id = 42; revision = 3; name = 'CI'; variables = @{ Foo = @{ value = 'bar' } } }
        Set-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 -Definition $definition
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.revision -eq 3 -and $body.name -eq 'CI' -and $body.variables.Foo.value -eq 'bar'
        }
    }

    It 'Returns the API response' {
        $result = Set-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 -Definition @{ id = 42; revision = 3 }
        $result.revision | Should -Be 4
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 -Definition @{ id = 42; revision = 3 } } | Should -Throw
    }
}
