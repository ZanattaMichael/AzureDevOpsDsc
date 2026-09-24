$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsTeamAdministrator' -Tag "Unit", "Team", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsTeamAdministrator.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # The 'Identity' security namespace, as it is stamped into the cache from
        # '_apis/securitynamespaces'. ManageMembership is bit 8 in the real namespace; a second,
        # unrelated action is included to prove only the ManageMembership bit is inspected.
        $script:mockNamespace = [PSCustomObject]@{
            namespaceId = 'identity-namespace-id'
            actions     = @(
                [PSCustomObject]@{ bit = 1; name = 'Read' }
                [PSCustomObject]@{ bit = 2; name = 'Write' }
                [PSCustomObject]@{ bit = 8; name = 'ManageMembership' }
            )
        }

        Mock -CommandName Get-CacheItem -ParameterFilter {
            $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces'
        } -MockWith { return $script:mockNamespace }
    }

    Context 'when the member holds the ManageMembership ACE' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'member-desc-1' = [PSCustomObject]@{ allow = 9; deny = 0 } # Read (1) + ManageMembership (8)
                        }
                    }
                )
            }
        }

        It 'returns IsTeamAdmin true' {
            $result = Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1'
            $result.IsTeamAdmin | Should -BeTrue
        }

        It 'returns the resolved token and namespace id' {
            $result = Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1'
            $result.Token | Should -Be 'proj-1\team-1'
            $result.NamespaceId | Should -Be 'identity-namespace-id'
            $result.ManageMembershipBit | Should -Be 8
        }
    }

    Context "when the member's ACE does not include the ManageMembership bit" {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'member-desc-1' = [PSCustomObject]@{ allow = 3; deny = 0 } # Read + Write only
                        }
                    }
                )
            }
        }

        It 'returns IsTeamAdmin false' {
            $result = Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1'
            $result.IsTeamAdmin | Should -BeFalse
        }
    }

    Context 'when the member has no ACE on the token' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith {
                return @(
                    [PSCustomObject]@{
                        token              = 'proj-1\team-1'
                        inheritPermissions = $true
                        acesDictionary     = [PSCustomObject]@{
                            'someone-else' = [PSCustomObject]@{ allow = 8; deny = 0 }
                        }
                    }
                )
            }
        }

        It 'returns IsTeamAdmin false without throwing' {
            { Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' } | Should -Not -Throw
            $result = Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1'
            $result.IsTeamAdmin | Should -BeFalse
        }
    }

    Context 'when no ACL exists for the token' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
        }

        It 'returns IsTeamAdmin false without throwing' {
            { Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' } | Should -Not -Throw
            $result = Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1'
            $result.IsTeamAdmin | Should -BeFalse
        }
    }

    Context 'when the Identity security namespace is not cached' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces'
            } -MockWith { return $null }
            Mock -CommandName Get-DevOpsACL
        }

        It 'throws' {
            { Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' } | Should -Throw
        }
    }

    Context 'when the ManageMembership action is not present on the namespace' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces'
            } -MockWith {
                return [PSCustomObject]@{
                    namespaceId = 'identity-namespace-id'
                    actions     = @([PSCustomObject]@{ bit = 1; name = 'Read' })
                }
            }
            Mock -CommandName Get-DevOpsACL
        }

        It 'throws' {
            { Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId 'proj-1' -TeamId 'team-1' -MemberDescriptor 'member-desc-1' } | Should -Throw
        }
    }
}
