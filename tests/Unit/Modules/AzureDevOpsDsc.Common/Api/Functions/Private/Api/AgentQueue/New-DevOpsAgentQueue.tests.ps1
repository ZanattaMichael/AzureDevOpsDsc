$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsAgentQueue' -Tag "Unit", "AgentQueue", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsAgentQueue.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 1; name = 'mock-item' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsAgentQueue -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolId 1
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsAgentQueue -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolId 1
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsAgentQueue -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolId 1 } | Should -Throw
    }
}
