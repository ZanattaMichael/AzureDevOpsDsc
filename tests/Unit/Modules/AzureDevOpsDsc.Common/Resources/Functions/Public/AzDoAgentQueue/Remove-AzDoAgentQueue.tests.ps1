$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoAgentQueue" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoAgentQueue.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsAgentQueue
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when agent queue exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 10; name = 'TestQueue' } }
        }

        It "calls Remove-DevOpsAgentQueue" {
            Remove-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Remove-DevOpsAgentQueue -Exactly -Times 1
        }

        It "calls Remove-CacheItem with LiveAgentQueues" {
            Remove-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Type -eq 'LiveAgentQueues'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when agent queue not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsAgentQueue" {
            Remove-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'NonExistent' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsAgentQueue -Times 0
        }
    }
}
