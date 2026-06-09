$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoAgentQueue" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoAgentQueue.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when agent queue exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 10; name = 'TestQueue' }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache" {
            $result = Get-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }

        It "queries cache with correct composite key" {
            Get-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'TestQueue' -PoolName 'TestPool'
            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestQueue' -and $Type -eq 'LiveAgentQueues'
            } -Times 1
        }
    }

    Context "when agent queue does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoAgentQueue -ProjectName 'TestProject' -QueueName 'NonExistent' -PoolName 'TestPool'
            $result.status | Should -Be 'NotFound'
        }
    }
}
