$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoAgentPool" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoAgentPool.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when agent pool exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 1; name = 'TestPool'; poolType = 'automation' }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoAgentPool -PoolName 'TestPool'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache" {
            $result = Get-AzDoAgentPool -PoolName 'TestPool'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.name | Should -Be 'TestPool'
        }

        It "calls Get-CacheItem with correct key and type" {
            Get-AzDoAgentPool -PoolName 'TestPool'
            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestPool' -and $Type -eq 'LiveAgentPools'
            } -Times 1
        }
    }

    Context "when agent pool does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoAgentPool -PoolName 'NonExistentPool'
            $result.status | Should -Be 'NotFound'
        }
    }
}
