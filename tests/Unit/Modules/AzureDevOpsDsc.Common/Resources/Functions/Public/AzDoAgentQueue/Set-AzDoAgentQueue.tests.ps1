$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoAgentQueue" -Tag "Unit", "AgentQueue" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoAgentQueue.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsAgentQueue -MockWith { return @{ id = 10 } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when agent queue exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 10; name = 'TestQueue' } }
        }

        It "calls Set-DevOpsAgentQueue" {
            Set-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Set-DevOpsAgentQueue -Exactly -Times 1
        }

        It "calls Add-CacheItem to update cache" {
            Set-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when agent queue not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsAgentQueue" {
            Set-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'NonExistent' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsAgentQueue -Times 0
        }
    }
}
