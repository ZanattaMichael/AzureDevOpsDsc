$currentFile = $MyInvocation.MyCommand.Path

Describe 'List-DevOpsBranchPolicies' -Tags "Unit", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-DevOpsBranchPolicies.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ value = @(@{ id = 'mock-id'; name = 'mock-name' }) }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Returns data when API returns results' {
        $result = List-DevOpsBranchPolicies -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Returns null when API returns no data' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $null } }
        $result = List-DevOpsBranchPolicies -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject'
        $result | Should -BeNullOrEmpty
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with GET method' {
        List-DevOpsBranchPolicies -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'GET'
        } -Times 1
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { List-DevOpsBranchPolicies -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' } | Should -Throw
    }

}
