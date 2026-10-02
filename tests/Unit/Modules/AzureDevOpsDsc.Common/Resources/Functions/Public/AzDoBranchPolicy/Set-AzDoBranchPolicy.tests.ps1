$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoBranchPolicy" -Tag "Unit", "BranchPolicy" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsBranchPolicy -MockWith { return @{ id = 'updated-policy-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when branch policy exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveBranchPolicies' { return @{ id = 'existing-policy-id'; settings = @{} } }
                    'LivePolicyTypes'    { return @{ id = 'mock-type-id' } }
                    default { return $null }
                }
            }
        }

        It "calls Set-DevOpsBranchPolicy" {
            Set-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Set-DevOpsBranchPolicy -Exactly -Times 1
        }

        It "calls Add-CacheItem to update cache" {
            Set-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1
        }
    }

    Context "when PolicySettings is supplied without a 'scope' key" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveBranchPolicies' {
                        return @{
                            id       = 'existing-policy-id'
                            settings = @{ scope = @(@{ repositoryId = 'repo-1'; refName = 'refs/heads/release/'; matchKind = 'prefix' }) }
                        }
                    }
                    'LivePolicyTypes' { return @{ id = 'mock-type-id' } }
                    default { return $null }
                }
            }
        }

        It "carries the cached policy's existing scope over rather than dropping it" {
            Set-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' -BranchName 'release/' `
                -MatchKind 'Prefix' -PolicyType 'RequiredReviewers' -PolicySettings @{ minimumApproverCount = 2 }

            Assert-MockCalled -CommandName Set-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                ($Settings.scope[0].matchKind -eq 'prefix') -and ($Settings.scope[0].refName -eq 'refs/heads/release/') -and ($Settings.minimumApproverCount -eq 2)
            }
        }
    }

    Context "when PolicySettings is supplied with its own 'scope' key" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveBranchPolicies' {
                        return @{
                            id       = 'existing-policy-id'
                            settings = @{ scope = @(@{ repositoryId = 'repo-1'; refName = 'refs/heads/main'; matchKind = 'exact' }) }
                        }
                    }
                    'LivePolicyTypes' { return @{ id = 'mock-type-id' } }
                    default { return $null }
                }
            }
        }

        It "uses the configuration-supplied scope verbatim instead of the cached one" {
            $customScope = @(@{ repositoryId = 'repo-2'; refName = 'refs/heads/develop'; matchKind = 'exact' })
            Set-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' -BranchName 'main' `
                -PolicyType 'RequiredReviewers' -PolicySettings @{ scope = $customScope; minimumApproverCount = 2 }

            Assert-MockCalled -CommandName Set-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].repositoryId -eq 'repo-2'
            }
        }
    }

    Context "when branch policy not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsBranchPolicy" {
            Set-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsBranchPolicy -Times 0
        }
    }
}
