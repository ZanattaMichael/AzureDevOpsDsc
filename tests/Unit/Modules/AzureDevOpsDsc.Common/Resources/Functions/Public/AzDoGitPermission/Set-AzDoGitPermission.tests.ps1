$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoGitPermission' -Tag "Unit", "GitPermission" {


    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoGitPermission.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')

        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'SampleNamespaceId' } }
        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return 'SerializedACLs' }
        Mock -CommandName Set-AzDoPermission

        $ProjectName = 'TestProject'
        $RepositoryName = 'TestRepo'
        $isInherited = $true
        $Permissions = @(@{ User = 'TestUser'; Permission = 'Allow' })
        $LookupResult = @{ propertiesChanged = 'someValue' }
        $Ensure = [Ensure]::Present

        $params = @{
            ProjectName = $ProjectName
            RepositoryName = $RepositoryName
            isInherited = $isInherited
            Permissions = $Permissions
            LookupResult = $LookupResult
            Ensure = $Ensure
        }

        $Global:DSCAZDO_OrganizationName = 'TestOrg'

    }

    BeforeEach {

        Mock Get-CacheItem -MockWith {
            return @{
                namespaceId = 'SampleNamespaceId'
            }
        }
        Mock ConvertTo-ACLHashtable -MockWith {
            return 'SerializedACLs'
        }
        Mock Set-AzDoPermission -MockWith {
            return $null
        }

    }

    It 'Calls Get-CacheItem with the correct parameters for security namespace' {
        Set-AzDoGitPermission @params
        Assert-MockCalled Get-CacheItem -Exactly 1 -ParameterFilter { ($Key -eq 'Git Repositories') -and ($Type -eq 'SecurityNamespaces') }
    }

    It 'Calls Get-CacheItem with the correct parameters for the project' {
        Set-AzDoGitPermission @params
        Assert-MockCalled Get-CacheItem -Exactly 1 -ParameterFilter { ($Key -eq $ProjectName) -and ($Type -eq 'LiveProjects') }
    }

    It 'Calls Set-AzDoPermission with the correct parameters' {
        Set-AzDoGitPermission @params
        Assert-MockCalled Set-AzDoPermission -Exactly 1 -ParameterFilter {
            ($OrganizationName -eq 'TestOrganization') -and
            ($SecurityNamespaceID -eq 'SampleNamespaceId') -and
            ($SerializedACLs -eq 'SerializedACLs')
        }
    }

    It 'Serializes ACLs using ConvertTo-ACLHashtable with correct parameters' {
        Set-AzDoGitPermission @params
        Assert-MockCalled ConvertTo-ACLHashtable -Exactly 1 -ParameterFilter {
            $ReferenceACLs -eq 'someValue'
        }
    }

    It 'writes an error if Get-CacheItem is null' {

        Mock Get-CacheItem -MockWith { return $null }
        Mock Write-Error -Verifiable

        Set-AzDoGitPermission @params
        Assert-VerifiableMock
    }

    Context 'Branch and Tag scoped permissions' {

        BeforeAll {
            . (Get-FunctionItem 'Format-AzDoGitRefName.ps1').FullName
            . (Get-FunctionItem 'ConvertTo-GitRefToken.ps1').FullName
        }

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                switch ($Type) {
                    'SecurityNamespaces' { @{ namespaceId = 'SampleNamespaceId' } }
                    'LiveProjects'       { @{ id = 'projectIdValue' } }
                    'LiveRepositories'   { @{ id = 'repositoryIdValue' } }
                    default              { $null }
                }
            }
        }

        It 'Stops without calling Set-AzDoPermission when LookupResult.reason is the mutual-exclusion refusal' {
            $branchParams = $params.Clone()
            $branchParams.LookupResult = @{ reason = 'BranchName and TagName are mutually exclusive.' }

            Mock -CommandName Write-Warning -Verifiable

            Set-AzDoGitPermission @branchParams

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 0
            Assert-VerifiableMock
        }

        It 'Stops without calling Set-AzDoPermission when LookupResult.reason is the RepositoryName-required refusal' {
            $branchParams = $params.Clone()
            $branchParams.LookupResult = @{ reason = 'BranchName/TagName requires RepositoryName.' }

            Mock -CommandName Write-Warning -Verifiable

            Set-AzDoGitPermission @branchParams

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 0
            Assert-VerifiableMock
        }

        It 'Stops without calling Set-AzDoPermission when BranchName and TagName are both specified directly' {
            $branchParams = $params.Clone()
            $branchParams.BranchName = 'main'
            $branchParams.TagName = 'v1.0'

            Mock -CommandName Write-Warning -Verifiable

            Set-AzDoGitPermission @branchParams

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 0
            Assert-VerifiableMock
        }

        It 'Writes an error and returns when the Repository is not found for a branch-scoped call' {
            Mock -CommandName Get-CacheItem -MockWith {
                switch ($Type) {
                    'SecurityNamespaces' { @{ namespaceId = 'SampleNamespaceId' } }
                    'LiveProjects'       { @{ id = 'projectIdValue' } }
                    'LiveRepositories'   { $null }
                    default              { $null }
                }
            }
            Mock -CommandName Write-Error -Verifiable

            $branchParams = $params.Clone()
            $branchParams.BranchName = 'main'

            Set-AzDoGitPermission @branchParams

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 0
            Assert-VerifiableMock
        }

        It 'Builds a branch-scoped DescriptorMatchToken using the hex/UTF-16LE-encoded branch name' {
            $script:capturedToken = $null
            Mock -CommandName ConvertTo-ACLHashtable -MockWith {
                $script:capturedToken = $DescriptorMatchToken
                return 'SerializedACLs'
            }

            $branchParams = $params.Clone()
            $branchParams.BranchName = 'main'

            Set-AzDoGitPermission @branchParams

            $expected = '^repoV2\/[A-Za-z0-9-]+\/repositoryIdValue\/refs\/heads\/6d00610069006e00$'
            $script:capturedToken | Should -Be $expected
        }

        It 'Builds a tag-scoped DescriptorMatchToken using the hex/UTF-16LE-encoded tag name' {
            $script:capturedToken = $null
            Mock -CommandName ConvertTo-ACLHashtable -MockWith {
                $script:capturedToken = $DescriptorMatchToken
                return 'SerializedACLs'
            }

            $tagParams = $params.Clone()
            $tagParams.TagName = 'v1.0'

            Set-AzDoGitPermission @tagParams

            $expected = '^repoV2\/[A-Za-z0-9-]+\/repositoryIdValue\/refs\/tags\/{0}$' -f (ConvertTo-GitRefToken -RefName 'v1.0')
            $script:capturedToken | Should -Be $expected
        }

        It 'Strips a leading refs/heads/ prefix from BranchName before building the token' {
            $script:capturedToken = $null
            Mock -CommandName ConvertTo-ACLHashtable -MockWith {
                $script:capturedToken = $DescriptorMatchToken
                return 'SerializedACLs'
            }

            $branchParams = $params.Clone()
            $branchParams.BranchName = 'refs/heads/main'

            Set-AzDoGitPermission @branchParams

            $expected = '^repoV2\/[A-Za-z0-9-]+\/repositoryIdValue\/refs\/heads\/6d00610069006e00$'
            $script:capturedToken | Should -Be $expected
        }
    }

}
