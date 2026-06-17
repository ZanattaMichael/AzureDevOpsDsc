$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoRepositorySettings" -Tag "Unit", "RepositorySettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoRepositorySettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Warning
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when repository exists and settings match" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'repo-id'; name = 'TestRepo' } }
            Mock -CommandName Get-DevOpsRepositorySettings -MockWith {
                return @{ allowSquashMerge = $true; allowNoFastForward = $true; allowRebaseMerge = $true }
            }
        }

        It "returns status Unchanged when settings match" {
            $result = Get-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -AllowSquashMerge $true -AllowNoFastForward $true -AllowRebaseMerge $true
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when AllowSquashMerge differs" {
            $result = Get-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -AllowSquashMerge $false -AllowNoFastForward $true -AllowRebaseMerge $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AllowSquashMerge'
        }

        It "populates liveCache" {
            $result = Get-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }
    }

    Context "when repository not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'NonExistent'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when API call fails" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'repo-id' } }
            Mock -CommandName Get-DevOpsRepositorySettings -MockWith { throw "API error" }
        }

        It "returns status Error" {
            $result = Get-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo'
            $result.status | Should -Be 'Error'
        }
    }
}
