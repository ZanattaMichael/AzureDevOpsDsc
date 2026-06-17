$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsTaskGroup' -Tag "Unit", "TaskGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsTaskGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsTaskGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -TaskGroupName 'TestTG'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsTaskGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -TaskGroupName 'TestTG'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsTaskGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -TaskGroupName 'TestTG' } | Should -Throw
    }
}
