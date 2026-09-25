$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoGitPermission Tests' -Tag "Unit", "GitPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoGitPermission.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Function Mock-Get-CacheItem {
            param (
                [string]$Key,
                [string]$Type
            )
            switch ($Type) {
                'LiveRepositories' { return @{ id = 123; Name = "TestRepository" } }
                'SecurityNamespaces' { return @{ namespaceId = "TestNamespaceId" } }
                'LiveProjects' { return @{ id = 123; Name = "TestProject" } }
                default { return $null }
            }
        }

        # Get-DevOpsACL returns the API's RAW ACL objects, whose token is a plain wire-format
        # string - the parsed .Token shape only exists after ConvertTo-FormattedACL. Get- filters
        # on the raw token before formatting, so the fixture has to carry it. An ACL for another
        # repository is included so that filter is actually exercised.
        Function Mock-Get-DevOpsACL {
            param (
                [Parameter(Mandatory = $true)]
                [string]$OrganizationName,
                [Parameter(Mandatory = $true)]
                [string]$SecurityDescriptorId
            )
            return @(
                @{ token = 'repoV2/123/123'; Permission = 'Allow' }
                @{ token = 'repoV2/123/999'; Permission = 'Allow' }
            )
        }

        Function Mock-ConvertTo-FormattedACL {
            param (
                [Parameter(Mandatory = $true)]
                $SecurityNamespace,
                [Parameter(Mandatory = $true)]
                $OrganizationName
            )
            return @( @{ Token = @{ Type = 'GitRepository'; RepoId = 123 }; Permission = 'Allow' } )
        }

        Function Mock-ConvertTo-ACL {
            param (
                [Parameter(Mandatory = $true)]
                $Permissions,
                [Parameter(Mandatory = $true)]
                $SecurityNamespace,
                [Parameter(Mandatory = $true)]
                $isInherited,
                [Parameter(Mandatory = $true)]
                $OrganizationName,
                [Parameter(Mandatory = $true)]
                $TokenName
            )
            return @( @{ Token = @{ Type = 'GitRepository'; RepoId = 123 }; Permission = 'Deny' } )
        }

        # Not Mandatory, matching the real Test-ACLListforChanges: an empty difference list is a
        # valid input meaning "no ACL exists for this token", not a missing argument.
        Function Mock-Test-ACLListforChanges {
            param (
                [Parameter()]
                $ReferenceACLs,
                [Parameter()]
                $DifferenceACLs
            )
            return @{
                propertiesChanged = @('Permission');
                status = 'Changed';
                reason = 'Permission mismatch'
            }
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Get-CacheItem -MockWith { Mock-Get-CacheItem -Key $Key -Type $Type }
        Mock -CommandName Get-DevOpsACL -MockWith { Mock-Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $SecurityDescriptorId }
        Mock -CommandName ConvertTo-FormattedACL -MockWith { Mock-ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName }
        Mock -CommandName ConvertTo-ACL -MockWith { Mock-ConvertTo-ACL -Permissions $Permissions -SecurityNamespace $SecurityNamespace -isInherited $isInherited -OrganizationName $OrganizationName -TokenName $TokenName }
        Mock -CommandName Test-ACLListforChanges -MockWith { Mock-Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs }
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    It 'Should retrieve repository and namespace, and compare ACLs correctly' {
        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = 'Deny' })

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'Changed'
        $result.propertiesChanged | Should -Contain 'Permission'
    }

    It "Should return 'Unchanged' if the permissions are the same" {
        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = 'Allow' })

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{
                propertiesChanged = @()
                status = 'Unchanged'
                reason = 'No change'
            }
        }

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'Unchanged'
        $result.propertiesChanged | Should -BeNullOrEmpty
    }

    it "Should return 'Error' if the project enumeration is null" {
        Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveProjects' }

        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = 'Allow' })

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'Error'

    }

    It "Should returned 'Changed' if one of the permissions is null" {
        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = $null })

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'Changed'
        $result.propertiesChanged | Should -Contain 'Permission'
    }

    It "Should return 'NotFound' if the repository is not found" {

        Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveRepositories' }

        $ProjectName = 'TestProject'
        $RepositoryName = 'NotFoundRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = 'Allow' })

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'NotFound'
        $result.propertiesChanged | Should -BeNullOrEmpty

    }

    It "Should return 'Error' if Get-DevOpsACL is null" {
        Mock -CommandName Get-DevOpsACL -MockWith { return $null }
        Mock -CommandName Write-Error

        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = 'Allow' })

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'Error'

    }

    It "Should compare an empty ACL list rather than short-circuiting to 'NotFound'" {
        # An empty formatted list means the token has no explicit ACL - the state a repository is in
        # once its permissions revert to inherited. Returning NotFound here would tell the base class
        # Ensure is Absent and skip Set, so the empty list has to reach Test-ACLListforChanges.
        Mock -CommandName ConvertTo-FormattedACL -MockWith { return $null }

        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepository'
        $isInherited = $true
        $Permissions = @(@{ 'Permission' = 'Allow' })

        $result = Get-AzDoGitPermission -ProjectName $ProjectName -RepositoryName $RepositoryName -isInherited $isInherited -Permissions $Permissions

        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be 'Changed'
        Assert-MockCalled -CommandName Test-ACLListforChanges -Times 1 -Exactly -Scope It
    }

    It 'Should drop other repositories ACLs before the expensive formatting' {
        # ConvertTo-FormattedACL resolves every ACE through Find-Identity, an API round trip per
        # uncached descriptor, so only this repository's ACL may reach it.
        # ConvertTo-FormattedACL binds one ACL per pipeline item, so the mock records each -ACL it
        # is handed.
        $script:formattedTokens = [System.Collections.Generic.List[string]]::new()
        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            $script:formattedTokens.Add($ACL.token)
            return @( @{ Token = @{ Type = 'GitRepository'; RepoId = 123 }; Permission = 'Allow' } )
        }

        $null = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -Permissions @(@{ 'Permission' = 'Allow' })

        $script:formattedTokens.Count | Should -Be 1
        $script:formattedTokens[0] | Should -Be 'repoV2/123/123'
    }

    Context 'Branch and Tag scoped lookups' {

        BeforeAll {
            # Get-AzDoGitPermission calls these directly (not through a mocked command), so they
            # are not picked up by Find-MockedFunctions and need loading explicitly.
            . (Get-FunctionItem 'Format-AzDoGitRefName.ps1').FullName
            . (Get-FunctionItem 'ConvertTo-GitRefToken.ps1').FullName
        }

        It 'Returns Error when BranchName and TagName are both specified' {
            $result = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -BranchName 'main' -TagName 'v1.0'

            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'BranchName and TagName are mutually exclusive.'
        }

        It 'Returns Error when BranchName is specified without RepositoryName' {
            $result = Get-AzDoGitPermission -ProjectName 'TestProject' -isInherited $true -BranchName 'main'

            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'BranchName/TagName requires RepositoryName.'
        }

        It 'Returns Error when TagName is specified without RepositoryName' {
            $result = Get-AzDoGitPermission -ProjectName 'TestProject' -isInherited $true -TagName 'v1.0'

            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'BranchName/TagName requires RepositoryName.'
        }

        It 'Scopes the ACL lookup token to the hex/UTF-16LE-encoded branch ref' {
            $script:capturedToken = $null
            Mock -CommandName Get-DevOpsACL -MockWith {
                $script:capturedToken = $Token
                return @(@{ token = $Token; Permission = 'Allow' })
            }

            $null = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -BranchName 'main' -Permissions @(@{ 'Permission' = 'Allow' })

            $script:capturedToken | Should -Be 'repoV2/123/123/refs/heads/6d00610069006e00'
        }

        It 'Scopes the ACL lookup token to the hex/UTF-16LE-encoded tag ref' {
            $script:capturedToken = $null
            Mock -CommandName Get-DevOpsACL -MockWith {
                $script:capturedToken = $Token
                return @(@{ token = $Token; Permission = 'Allow' })
            }

            $null = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -TagName 'v1.0' -Permissions @(@{ 'Permission' = 'Allow' })

            $script:capturedToken | Should -Be ('repoV2/123/123/refs/tags/{0}' -f (ConvertTo-GitRefToken -RefName 'v1.0'))
        }

        It 'Strips a leading refs/heads/ prefix from BranchName before building the token' {
            $script:capturedToken = $null
            Mock -CommandName Get-DevOpsACL -MockWith {
                $script:capturedToken = $Token
                return @(@{ token = $Token; Permission = 'Allow' })
            }

            $null = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -BranchName 'refs/heads/main' -Permissions @(@{ 'Permission' = 'Allow' })

            $script:capturedToken | Should -Be 'repoV2/123/123/refs/heads/6d00610069006e00'
        }

        It 'Scopes a multi-segment branch name (branch folder) correctly' {
            $script:capturedToken = $null
            Mock -CommandName Get-DevOpsACL -MockWith {
                $script:capturedToken = $Token
                return @(@{ token = $Token; Permission = 'Allow' })
            }

            $null = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -BranchName 'release/1.0' -Permissions @(@{ 'Permission' = 'Allow' })

            $script:capturedToken | Should -Be ('repoV2/123/123/refs/heads/{0}' -f (ConvertTo-GitRefToken -RefName 'release/1.0'))
        }

        It 'Drops a formatted ACL whose decoded BranchName does not match, even if the raw token slipped past the first filter' {
            # Defence in depth: the pre-format filter already narrows on the exact raw token, but
            # this re-check on the decoded BranchName is what actually protects against reading a
            # different branch's ACL as this one's current state (see the comment above the real
            # filter in Get-AzDoGitPermission.ps1).
            $aclToken = 'repoV2/123/123/refs/heads/6d00610069006e00'
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(@{ token = $aclToken; Permission = 'Allow' })
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'GitBranch'; RepoId = 123; BranchName = 'some-other-branch' }; Permission = 'Allow' } )
            }
            $script:seenDifferenceACLs = $null
            Mock -CommandName Test-ACLListforChanges -MockWith {
                $script:seenDifferenceACLs = $DifferenceACLs
                return @{ propertiesChanged = @(); status = 'Unchanged'; reason = 'No change' }
            }

            $null = Get-AzDoGitPermission -ProjectName 'TestProject' -RepositoryName 'TestRepository' -isInherited $true -BranchName 'main' -Permissions @(@{ 'Permission' = 'Allow' })

            # A filtered-to-nothing Where-Object emits $null, not an empty array - @($null) would
            # wrongly report Count 1 (the single-element-array-unwrap gotcha in reverse), so this
            # checks for emptiness directly instead.
            $script:seenDifferenceACLs | Should -BeNullOrEmpty
        }
    }

}
