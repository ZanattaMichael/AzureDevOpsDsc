$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsBranchPolicy' -Tag "Unit", "BranchPolicy", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; isEnabled = $true; isBlocking = $true; settings = @{ minimumApproverCount = 1 } }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Returns data when the API returns a policy' {
        $result = Get-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyId 'mock-id'
        $result | Should -Not -BeNullOrEmpty
        $result.id | Should -Be 'mock-id'
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with GET method against the policy id' {
        Get-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyId 'mock-id'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'GET' -and $Uri -like '*_apis/policy/configurations/mock-id*'
        } -Times 1
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Get-DevOpsBranchPolicy -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PolicyId 'mock-id' } | Should -Throw
    }

}
