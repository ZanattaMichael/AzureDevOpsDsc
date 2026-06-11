$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoAgentPool" -Tag "Unit", "AgentPool" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoAgentPool.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsAgentPool -MockWith { return @{ id = 1; name = 'TestPool' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when creating an agent pool" {
        It "calls New-DevOpsAgentPool" {
            New-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName New-DevOpsAgentPool -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveAgentPools type" {
            New-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Key -eq 'TestPool' -and $Type -eq 'LiveAgentPools'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            New-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1
        }

        It "calls Refresh-CacheObject" {
            New-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1
        }

        It "passes PoolName to New-DevOpsAgentPool" {
            New-AzDoAgentPool -PoolName 'MyPool' -PoolType 'automation'
            Assert-MockCalled -CommandName New-DevOpsAgentPool -ParameterFilter {
                $PoolName -eq 'MyPool' -and $PoolType -eq 'automation'
            } -Times 1
        }
    }
}
