$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoAgentQueue" -Tag "Unit", "AgentQueue" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoAgentQueue.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsAgentQueue -MockWith { return @{ id = 10; name = 'TestQueue' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when pool is found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestPool' } }
        }

        It "calls New-DevOpsAgentQueue" {
            New-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName New-DevOpsAgentQueue -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveAgentQueues" {
            New-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveAgentQueues'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }

    Context "when pool not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call New-DevOpsAgentQueue" {
            New-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'MissingPool'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsAgentQueue -Times 0
        }
    }
}
