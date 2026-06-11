$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsBranchPolicy' -Tag "Unit", "BranchPolicy", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyTypeId 'policy-type-id' -IsEnabled $true -IsBlocking $false
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyTypeId 'policy-type-id' -IsEnabled $true -IsBlocking $false
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyTypeId 'policy-type-id' -IsEnabled $true -IsBlocking $false } | Should -Throw
    }
}
