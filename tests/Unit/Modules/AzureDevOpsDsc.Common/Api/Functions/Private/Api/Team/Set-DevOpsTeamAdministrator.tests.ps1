$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsTeamAdministrator' -Tag "Unit", "Team", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsTeamAdministrator.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # ManageMembership is bit 8 in the real 'Identity' namespace; Read (1) is included so
        # ACEs with other bits set can be used to prove those bits are preserved untouched.
        $script:mockNamespace = [PSCustomObject]@{
            namespaceId = 'identity-namespace-id'
            actions     = @(
                [PSCustomObject]@{ bit = 1; name = 'Read' }
                [PSCustomObject]@{ bit = 8; name = 'ManageMembership' }
            )
        }

        Mock -CommandName Get-CacheItem -ParameterFilter {
            $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces'
        } -MockWith { return $script:mockNamespace }

        Mock -CommandName Set-AzDoPermission
    }

    Context 'granting team administrator rights to a member with no existing ACE' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'bystander-desc' = [PSCustomObject]@{ allow = 1; deny = 0 }
                        }
                    }
                )
            }
        }

        It 'calls Set-AzDoPermission with the ManageMembership bit set for the target member' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].acesDictionary['member-desc-1'].allow -eq 8
            }
        }

        It 'preserves the bystander ACE unchanged' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].acesDictionary['bystander-desc'].allow -eq 1
            }
        }

        It 'submits the token and inheritPermissions from the live ACL' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].token -eq 'proj-1\team-1' -and $SerializedACLs.value[0].inheritPermissions -eq $true -and
                $SecurityNamespaceID -eq 'identity-namespace-id'
            }
        }
    }

    Context 'granting team administrator rights to a member that already holds other bits' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'member-desc-1' = [PSCustomObject]@{ allow = 1; deny = 8 }
                        }
                    }
                )
            }
        }

        It 'ORs the ManageMembership bit into the existing allow mask' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].acesDictionary['member-desc-1'].allow -eq 9
            }
        }

        It 'clears any conflicting deny bit for ManageMembership' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].acesDictionary['member-desc-1'].deny -eq 0
            }
        }
    }

    Context 'revoking team administrator rights from a member whose ACE has only that bit' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'member-desc-1'  = [PSCustomObject]@{ allow = 8; deny = 0 }
                            'bystander-desc' = [PSCustomObject]@{ allow = 1; deny = 0 }
                        }
                    }
                )
            }
        }

        It 'removes the ACE entirely rather than leaving a zero-permission entry' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $false

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                (-not $SerializedACLs.value[0].acesDictionary.ContainsKey('member-desc-1')) -and
                $SerializedACLs.value[0].acesDictionary['bystander-desc'].allow -eq 1
            }
        }
    }

    Context 'revoking team administrator rights from a member whose ACE also has other bits' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'member-desc-1' = [PSCustomObject]@{ allow = 9; deny = 0 } # Read + ManageMembership
                        }
                    }
                )
            }
        }

        It 'clears only the ManageMembership bit and keeps the ACE' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $false

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].acesDictionary.ContainsKey('member-desc-1') -and
                $SerializedACLs.value[0].acesDictionary['member-desc-1'].allow -eq 1
            }
        }
    }

    Context 'revoking team administrator rights from a member with no existing ACE' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'bystander-desc' = [PSCustomObject]@{ allow = 1; deny = 0 }
                        }
                    }
                )
            }
        }

        It 'is a no-op that still submits the ACL with the bystander ACE preserved' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $false

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                (-not $SerializedACLs.value[0].acesDictionary.ContainsKey('member-desc-1')) -and
                $SerializedACLs.value[0].acesDictionary['bystander-desc'].allow -eq 1
            }
        }
    }

    Context 'when no ACL exists yet for the token' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
        }

        It 'grants by creating a fresh ACL with only the target ACE and default inheritPermissions' {
            Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $SerializedACLs.value[0].acesDictionary['member-desc-1'].allow -eq 8 -and
                $SerializedACLs.value[0].inheritPermissions -eq $true
            }
        }
    }

    Context 'when the Identity security namespace is not cached' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces'
            } -MockWith { return $null }
            Mock -CommandName Get-DevOpsACL
        }

        It 'throws and does not call Set-AzDoPermission' {
            { Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' -IsTeamAdmin $true } | Should -Throw
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 0
        }
    }
}
