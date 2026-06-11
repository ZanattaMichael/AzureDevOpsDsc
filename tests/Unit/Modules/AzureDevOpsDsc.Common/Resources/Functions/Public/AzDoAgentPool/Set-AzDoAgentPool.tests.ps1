$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoAgentPool" -Tag "Unit", "AgentPool" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoAgentPool.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsAgentPool -MockWith { return @{ id = 1; name = 'TestPool' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when agent pool exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestPool' } }
        }

        It "calls Set-DevOpsAgentPool" {
            Set-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Set-DevOpsAgentPool -Exactly -Times 1
        }

        It "calls Add-CacheItem to update cache" {
            Set-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when agent pool not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsAgentPool" {
            Set-AzDoAgentPool -PoolName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsAgentPool -Times 0
        }
    }
}
