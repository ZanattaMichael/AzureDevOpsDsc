$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoAgentPool" -Tag "Unit", "AgentPool" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoAgentPool.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsAgentPool
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when agent pool exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestPool' } }
        }

        It "calls Remove-DevOpsAgentPool" {
            Remove-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Remove-DevOpsAgentPool -Exactly -Times 1
        }

        It "calls Remove-CacheItem" {
            Remove-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Key -eq 'TestPool' -and $Type -eq 'LiveAgentPools'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when agent pool not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsAgentPool" {
            Remove-AzDoAgentPool -PoolName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsAgentPool -Times 0
        }
    }
}
