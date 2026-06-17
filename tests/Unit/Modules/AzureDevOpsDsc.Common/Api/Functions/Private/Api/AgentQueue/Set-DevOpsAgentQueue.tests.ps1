$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsAgentQueue' -Tag "Unit", "AgentQueue", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsAgentQueue.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 1; name = 'mock-item' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsAgentQueue -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -QueueId 1
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PATCH'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsAgentQueue -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -QueueId 1
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsAgentQueue -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -QueueId 1 } | Should -Throw
    }
}
