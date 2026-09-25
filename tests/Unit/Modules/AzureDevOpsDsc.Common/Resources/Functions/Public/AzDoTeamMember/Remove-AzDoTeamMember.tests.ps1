$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTeamMember" -Tag "Unit", "TeamMember" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTeamMember.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockTeam = @{
            id         = 'team-id-001'
            name       = 'TestTeam'
            descriptor = 'vssgp.team-descriptor-001'
        }

        $mockMember = @{
            descriptor    = 'aad.member-descriptor-001'
            principalName = 'user@example.com'
        }

        $mockMemberWithAclIdentity = @{
            descriptor    = 'aad.member-descriptor-002'
            principalName = 'admin@example.com'
            ACLIdentity   = @{ descriptor = 'Microsoft.TeamFoundation.Identity;S-1-9-cached' }
        }

        $mockProject = @{ id = 'project-id-001'; name = 'TestProject' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsTeamMember
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Get-DevOpsDescriptorIdentity -MockWith {
            return [PSCustomObject]@{ descriptor = 'Microsoft.TeamFoundation.Identity;S-1-9-live' }
        }
        Mock -CommandName Set-DevOpsTeamAdministrator
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Resolve-AzDoProject -MockWith { Get-CacheItem -Key $ProjectName -Type 'LiveProjects' }
        Mock -CommandName List-DevOpsTeams -MockWith { return $null }
        Mock -CommandName Find-AzDoIdentity -MockWith { return $null }
        Mock -CommandName Get-DevOpsSecurityDescriptor -MockWith { return $null }
    }

    Context "when team and member are found in cache (member from LiveGroups)" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Type -eq 'LiveProjects'
            } -MockWith { return $null }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            } -MockWith { return $mockTeam }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'user@example.com' -and $Type -eq 'LiveGroups'
            } -MockWith { return $mockMember }
        }

        It "calls Remove-DevOpsTeamMember" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 1
        }

        It "calls Remove-DevOpsTeamMember with MemberDescriptor and GroupDescriptor" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 1 -ParameterFilter {
                $MemberDescriptor -eq 'aad.member-descriptor-001' -and $GroupDescriptor -eq 'vssgp.team-descriptor-001'
            }
        }

        It "calls Remove-CacheItem with the composite key and LiveTeamMembers type" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\user@example.com' -and $Type -eq 'LiveTeamMembers'
            }
        }

        It "calls Export-CacheObject for LiveTeamMembers" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTeamMembers'
            }
        }
    }

    Context "when member is not in LiveGroups but is found in LiveUsers" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Type -eq 'LiveProjects'
            } -MockWith { return $null }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            } -MockWith { return $mockTeam }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Type -eq 'LiveGroups'
            } -MockWith { return $null }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'user@example.com' -and $Type -eq 'LiveUsers'
            } -MockWith { return $mockMember }
        }

        It "falls back to LiveUsers and calls Remove-DevOpsTeamMember" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 1
        }

        It "calls Remove-CacheItem after falling back to LiveUsers" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1
        }
    }

    Context "when the team is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $null }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveGroups' } -MockWith { return $mockMember }
            Mock -CommandName Write-Error
        }

        It "treats a missing team as already absent (no removal, no throw)" {
            { Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'NonExistentTeam' -MemberName 'user@example.com' } | Should -Not -Throw
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 0
        }

        It "does not call Remove-CacheItem" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'NonExistentTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 0
        }
    }

    Context "when both team and member are not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
            Mock -CommandName Write-Error
        }

        It "treats a missing team and member as already absent (no removal, no throw)" {
            { Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com' } | Should -Not -Throw
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 0
        }
    }

    Context "when revoking team-administrator rights on removal" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject' -and $Type -eq 'LiveProjects'
            } -MockWith { return $mockProject }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            } -MockWith { return $mockTeam }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'admin@example.com' -and $Type -eq 'LiveGroups'
            } -MockWith { return $mockMemberWithAclIdentity }
        }

        It "always attempts the revoke, even when IsTeamAdmin is false" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com' -IsTeamAdmin $false
            Assert-MockCalled -CommandName Set-DevOpsTeamAdministrator -Exactly -Times 1 -ParameterFilter {
                $ProjectId -eq 'project-id-001' -and $TeamId -eq 'team-id-001' -and
                $MemberDescriptor -eq 'Microsoft.TeamFoundation.Identity;S-1-9-cached' -and $IsTeamAdmin -eq $false
            }
        }

        It "always attempts the revoke, even when IsTeamAdmin was true" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com' -IsTeamAdmin $true
            Assert-MockCalled -CommandName Set-DevOpsTeamAdministrator -Exactly -Times 1 -ParameterFilter {
                $IsTeamAdmin -eq $false
            }
        }

        It "uses the member's cached ACLIdentity descriptor rather than resolving it live" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com'
            Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentity -Exactly -Times 0
        }

        It "still removes the membership after a successful revoke" {
            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com'
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 1
        }

        It "resolves the member's ACL descriptor live when no cached ACLIdentity is present" {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'user@example.com' -and $Type -eq 'LiveGroups'
            } -MockWith { return $mockMember }

            Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentity -Exactly -Times 1
            Assert-MockCalled -CommandName Set-DevOpsTeamAdministrator -Exactly -Times 1 -ParameterFilter {
                $MemberDescriptor -eq 'Microsoft.TeamFoundation.Identity;S-1-9-live'
            }
        }

        It "logs a warning instead of throwing when Set-DevOpsTeamAdministrator fails, and still removes the membership" {
            Mock -CommandName Set-DevOpsTeamAdministrator -MockWith { throw 'ACL write failed' }

            { Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com' } | Should -Not -Throw
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 1
        }

        It "skips the revoke without throwing when the ACL descriptor cannot be resolved, and still removes the membership" {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'user@example.com' -and $Type -eq 'LiveGroups'
            } -MockWith { return $mockMember }
            Mock -CommandName Get-DevOpsDescriptorIdentity -MockWith { return $null }

            { Remove-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com' } | Should -Not -Throw
            Assert-MockCalled -CommandName Set-DevOpsTeamAdministrator -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DevOpsTeamMember -Exactly -Times 1
        }
    }
}
