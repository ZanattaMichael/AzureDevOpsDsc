$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsBranchPolicy' -Tag "Unit", "BranchPolicy", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        Set-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyId 1 -PolicyTypeId 'policy-type-id' -IsEnabled $true -IsBlocking $false
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyId 1 -PolicyTypeId 'policy-type-id' -IsEnabled $true -IsBlocking $false
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyId 1 -PolicyTypeId 'policy-type-id' -IsEnabled $true -IsBlocking $false } | Should -Throw
    }
}
