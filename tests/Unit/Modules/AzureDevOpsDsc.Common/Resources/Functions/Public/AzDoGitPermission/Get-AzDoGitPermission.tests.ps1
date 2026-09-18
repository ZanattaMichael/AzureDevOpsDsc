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

}
