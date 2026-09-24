Describe "AzDoGitPermission Integration Tests" -Tag "Integration", "GitPermission" {

    BeforeAll {

        $PROJECTNAME = 'TESTPROJECT_GIT_PERMISSION'

        $parameters = @{
            Name = 'AzDoGitPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property = @{
                ProjectName = $PROJECTNAME
                RepositoryName = 'TESTREPOSITORY'
                isInherited = $false
                Permissions = @(
                    @{
                        Identity = "[$PROJECTNAME]\Group1"
                        Permission = @{
                            GenericRead        = 'Allow'
                            GenericContribute  = 'Allow'
                        }
                    }
                    @{
                        Identity = "[$PROJECTNAME]\Group2"
                        Permission = @{
                            GenericRead        = 'Deny'
                            GenericContribute  = 'Deny'
                        }
                    }
                )
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName 'TESTREPOSITORY'
        'Group1', 'Group2' | ForEach-Object { New-TestGroup -ProjectName $PROJECTNAME -GroupName $_ }
    }

    Context "Testing if the permissions exist" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

    }

    Context "Creating new permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

    }

    Context "Changing permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity = "[$PROJECTNAME]\Group1"
                    Permission = @{
                        GenericRead        = 'Allow'
                        GenericContribute  = 'Deny'
                    }
                }
                @{
                    Identity = "[$PROJECTNAME]\Group2"
                    Permission = @{
                        GenericRead        = 'Deny'
                        GenericContribute  = 'Allow'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Clearing permissions should revert to inherited" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Denying Force Push on a branch for a project group" {

        # Verifies the BranchName property (issue #76) end-to-end: the DSC resource writes to the
        # branch's own ACL token ('refs/heads/{encoded}'), not the repository's, and that ACE is
        # read back here with a hand-rolled encoder/plain REST call - independent of the module's
        # own ConvertTo-GitRefToken/Parse-ACLToken - so a bug shared by both sides would not
        # self-validate.

        BeforeAll {

            $BRANCHNAME = 'main'

            function ConvertTo-TestGitRefToken
            {
                param([Parameter(Mandatory)][string]$RefName)

                ($RefName -split '/' | ForEach-Object {
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($_)
                    -join ($bytes | ForEach-Object { $_.ToString('x2') })
                }) -join '/'
            }

            function Get-TestGitBranchACL
            {
                param(
                    [Parameter(Mandatory)][string]$ProjectId,
                    [Parameter(Mandatory)][string]$RepositoryId,
                    [Parameter(Mandatory)][string]$BranchName
                )

                $org_ = Resolve-TestOrg
                $hdr_ = Resolve-TestAuthHeader

                $namespaces  = Invoke-RestMethod -Uri "https://dev.azure.com/$org_/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $hdr_
                $namespaceId = ($namespaces.value | Where-Object { $_.name -eq 'Git Repositories' } | Select-Object -First 1).namespaceId
                if (-not $namespaceId) { throw "[Get-TestGitBranchACL] Could not resolve the 'Git Repositories' security namespace." }

                $token = 'repoV2/{0}/{1}/refs/heads/{2}' -f $ProjectId, $RepositoryId, (ConvertTo-TestGitRefToken -RefName $BranchName)
                $uri   = "https://dev.azure.com/{0}/_apis/accesscontrollists/{1}?token={2}&includeExtendedInfo=true&api-version=7.1-preview.1" -f `
                    $org_, $namespaceId, [System.Uri]::EscapeDataString($token)

                return (Invoke-RestMethod -Uri $uri -Headers $hdr_).value
            }

            $org_  = Resolve-TestOrg
            $hdr_  = Resolve-TestAuthHeader
            $proj_ = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/_apis/projects/{1}?api-version=7.1-preview.4" -f $org_, $PROJECTNAME) -Headers $hdr_
            $repo_ = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/TESTREPOSITORY?api-version=7.1-preview.1" -f $org_, $PROJECTNAME) -Headers $hdr_

            # Resolve the test group by display name through the graph API.
            $projDesc_ = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/descriptors/{1}?api-version=7.1-preview.1" -f $org_, $proj_.id) -Headers $hdr_
            $groups_   = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/groups?scopeDescriptor={1}&api-version=7.1-preview.1" -f $org_, $projDesc_.value) -Headers $hdr_
            $group1_   = $groups_.value | Where-Object { $_.displayName -eq 'Group1' } | Select-Object -First 1
            if (-not $group1_) { throw "[AzDoGitPermission.tests] Could not resolve test group 'Group1'." }

            # The security ACL API keys acesDictionary by identity descriptor
            # ('Microsoft.TeamFoundation.Identity;S-1-9-...'), not by the graph descriptor ('vssgp....').
            $identity_ = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/identities?subjectDescriptors={1}&api-version=7.1-preview.1" -f $org_, $group1_.descriptor) -Headers $hdr_
            $group1AceKey_ = ($identity_.value | Select-Object -First 1).descriptor
            if (-not $group1AceKey_) { throw "[AzDoGitPermission.tests] Could not resolve the identity descriptor of test group 'Group1'." }

            $branchParameters = @{
                Name       = 'AzDoGitPermission'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    ProjectName    = $PROJECTNAME
                    RepositoryName = 'TESTREPOSITORY'
                    isInherited    = $false
                    BranchName     = $BRANCHNAME
                    Permissions    = @(
                        @{
                            Identity   = "[$PROJECTNAME]\Group1"
                            Permission = @{
                                ForcePush = 'Deny'
                            }
                        }
                    )
                }
            }
        }

        AfterAll {
            $branchParameters.Method = 'Set'
            $branchParameters.property.Permissions = @()
            $branchParameters.property.isInherited = $true
            $null = Invoke-DscResource @branchParameters
        }

        It "Should not throw any exceptions when setting the branch-scoped permission" {
            $branchParameters.Method = 'Set'
            { Invoke-DscResource @branchParameters } | Should -Not -Throw
        }

        It "Should return True on Test after setting the branch-scoped permission" {
            $branchParameters.Method = 'Test'
            $result = Invoke-DscResource @branchParameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should deny ForcePush for the group directly on the branch's own ACL, read via the REST API" {

            $acl = Get-TestGitBranchACL -ProjectId $proj_.id -RepositoryId $repo_.id -BranchName $BRANCHNAME
            $acl | Should -Not -BeNullOrEmpty

            $aceProperty = $acl.acesDictionary.PSObject.Properties | Where-Object { $_.Name -eq $group1AceKey_ } | Select-Object -First 1
            $aceProperty | Should -Not -BeNullOrEmpty
            $ace = $aceProperty.Value

            # The bit position is read from the namespace's own action list rather than
            # hardcoded, since actionId bit values are namespace-specific.
            $namespaces   = Invoke-RestMethod -Uri "https://dev.azure.com/$org_/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $hdr_
            $gitNamespace = $namespaces.value | Where-Object { $_.name -eq 'Git Repositories' } | Select-Object -First 1
            $forcePushBit = ($gitNamespace.actions | Where-Object { $_.name -eq 'ForcePush' } | Select-Object -First 1).bit

            ([int]$ace.deny -band $forcePushBit) | Should -Be $forcePushBit
            ([int]$ace.allow -band $forcePushBit) | Should -Be 0
        }

        It "Should not write the ForcePush deny to the repository's own ACL" {

            $org2  = Resolve-TestOrg
            $hdr2  = Resolve-TestAuthHeader
            $namespaces   = Invoke-RestMethod -Uri "https://dev.azure.com/$org2/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $hdr2
            $namespaceId  = ($namespaces.value | Where-Object { $_.name -eq 'Git Repositories' } | Select-Object -First 1).namespaceId
            $repoToken    = 'repoV2/{0}/{1}' -f $proj_.id, $repo_.id
            $uri          = "https://dev.azure.com/{0}/_apis/accesscontrollists/{1}?token={2}&includeExtendedInfo=true&api-version=7.1-preview.1" -f `
                $org2, $namespaceId, [System.Uri]::EscapeDataString($repoToken)
            $repoAcl      = (Invoke-RestMethod -Uri $uri -Headers $hdr2).value

            if ($repoAcl)
            {
                $repoAceProperty = $repoAcl.acesDictionary.PSObject.Properties | Where-Object { $_.Name -eq $group1AceKey_ } | Select-Object -First 1
                if ($repoAceProperty)
                {
                    $gitNamespace = $namespaces.value | Where-Object { $_.name -eq 'Git Repositories' } | Select-Object -First 1
                    $forcePushBit = ($gitNamespace.actions | Where-Object { $_.name -eq 'ForcePush' } | Select-Object -First 1).bit
                    ([int]$repoAceProperty.Value.deny -band $forcePushBit) | Should -Be 0
                }
            }
        }
    }

}
