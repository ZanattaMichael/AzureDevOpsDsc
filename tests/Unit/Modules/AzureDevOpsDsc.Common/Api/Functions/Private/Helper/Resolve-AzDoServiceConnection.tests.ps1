$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoServiceConnection" -Tag "Unit", "Pipeline" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the connection is already cached" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'cached-conn-id'; name = 'GitHub-org' } }
            Mock -CommandName List-DevOpsServiceConnections
            Mock -CommandName Add-CacheItem
        }

        It "returns the cached connection without a live lookup" {
            $result = Resolve-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'GitHub-org'
            $result.id | Should -Be 'cached-conn-id'
            Assert-MockCalled -CommandName List-DevOpsServiceConnections -Times 0
        }
    }

    Context "when the connection is not cached but exists live" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsServiceConnections -MockWith {
                return @(@{ id = 'live-conn-id'; name = 'GitHub-org' }, @{ id = 'other-id'; name = 'Other' })
            }
            Mock -CommandName Add-CacheItem
        }

        It "falls back to a live lookup and returns the matching connection" {
            $result = Resolve-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'GitHub-org'
            $result.id | Should -Be 'live-conn-id'
        }

        It "caches the resolved connection" {
            Resolve-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'GitHub-org'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1 -ParameterFilter {
                $Type -eq 'LiveServiceConnections'
            }
        }
    }

    Context "when the connection does not exist" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsServiceConnections -MockWith { return @(@{ id = 'other-id'; name = 'Other' }) }
            Mock -CommandName Add-CacheItem
        }

        It "returns null and does not cache anything" {
            $result = Resolve-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'Missing'
            $result | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Add-CacheItem -Times 0
        }
    }
}
