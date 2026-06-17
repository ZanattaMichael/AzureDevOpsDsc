$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoBranchPolicy" -Tag "Unit", "BranchPolicy" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsBranchPolicy -MockWith { return @{ id = 'new-policy-id' } }
        # On a policy-type cache miss the resource queries the API; return nothing so the
        # not-found path is exercised without hitting a live endpoint.
        Mock -CommandName List-DevOpsPolicyTypes -MockWith { @() }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when all required cache items are found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'    { return @{ id = 'mock-project-id' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    'LivePolicyTypes' { return @{ id = 'mock-policy-type-id' } }
                    default { return $null }
                }
            }
        }

        It "calls New-DevOpsBranchPolicy" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1
        }

        It "calls Add-CacheItem" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1
        }

        It "calls Export-CacheObject" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1
        }

        It "calls Refresh-CacheObject" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1
        }
    }

    Context "when project not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return $null }
                return @{ id = 'mock-id' }
            }
        }

        It "writes an error and does not call New-DevOpsBranchPolicy" {
            New-AzDoBranchPolicy -ProjectName 'NonExistent' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Times 0
        }
    }

    Context "when policy type not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'    { return @{ id = 'mock-project-id' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    'LivePolicyTypes' { return $null }
                    default { return $null }
                }
            }
        }

        It "writes an error and does not call New-DevOpsBranchPolicy" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'UnknownType'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Times 0
        }
    }
}
