$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTeamMember" -Tag "Unit", "TeamMember" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTeamMember.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

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
        $mockTeam    = @{ id = 'team-id-001';    name = 'TestTeam' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
    }

    Context "when the team member is found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\user@example.com' -and $Type -eq 'LiveTeamMembers'
            } -MockWith { return $mockMember }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache with the cached member object" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.descriptor | Should -Be 'aad.member-descriptor-001'
        }

        It "calls Get-CacheItem with the composite key ProjectName\TeamName\MemberName" {
            Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\user@example.com' -and $Type -eq 'LiveTeamMembers'
            }
        }
    }

    Context "when the team member is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'nonexistent@example.com'
            $result.status | Should -Be 'NotFound'
        }

        It "does not populate liveCache" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'nonexistent@example.com'
            $result.liveCache | Should -BeNullOrEmpty
        }
    }

    Context "when IsTeamAdmin is requested and matches the live ACE" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\admin@example.com' -and $Type -eq 'LiveTeamMembers'
            } -MockWith { return $mockMemberWithAclIdentity }

            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $mockTeam }
            Mock -CommandName Resolve-AzDoProject -MockWith { return $mockProject }
            Mock -CommandName Get-DevOpsTeamAdministrator -MockWith {
                return [PSCustomObject]@{ IsTeamAdmin = $true }
            }
            Mock -CommandName Get-DevOpsDescriptorIdentity
        }

        It "returns status Unchanged and does not report IsTeamAdmin as changed" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com' -IsTeamAdmin $true
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -Not -Contain 'IsTeamAdmin'
        }

        It "uses the member's cached ACLIdentity descriptor rather than resolving it live" {
            Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com' -IsTeamAdmin $true
            Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentity -Exactly -Times 0
            Assert-MockCalled -CommandName Get-DevOpsTeamAdministrator -Exactly -Times 1 -ParameterFilter {
                $MemberDescriptor -eq 'Microsoft.TeamFoundation.Identity;S-1-9-cached'
            }
        }
    }

    Context "when IsTeamAdmin is requested and differs from the live ACE" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\admin@example.com' -and $Type -eq 'LiveTeamMembers'
            } -MockWith { return $mockMemberWithAclIdentity }

            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $mockTeam }
            Mock -CommandName Resolve-AzDoProject -MockWith { return $mockProject }
            Mock -CommandName Get-DevOpsTeamAdministrator -MockWith {
                return [PSCustomObject]@{ IsTeamAdmin = $false }
            }
        }

        It "returns status Changed and reports IsTeamAdmin" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'admin@example.com' -IsTeamAdmin $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'IsTeamAdmin'
        }
    }

    Context "when the member's ACL descriptor must be resolved live (no cached ACLIdentity)" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\user@example.com' -and $Type -eq 'LiveTeamMembers'
            } -MockWith { return $mockMember }

            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $mockTeam }
            Mock -CommandName Resolve-AzDoProject -MockWith { return $mockProject }
            Mock -CommandName Get-DevOpsDescriptorIdentity -MockWith {
                return [PSCustomObject]@{ descriptor = 'Microsoft.TeamFoundation.Identity;S-1-9-live' }
            }
            Mock -CommandName Get-DevOpsTeamAdministrator -MockWith {
                return [PSCustomObject]@{ IsTeamAdmin = $true }
            }
        }

        It "falls back to Get-DevOpsDescriptorIdentity and passes the resolved descriptor through" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com' -IsTeamAdmin $true
            $result.status | Should -Be 'Unchanged'
            Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentity -Exactly -Times 1
            Assert-MockCalled -CommandName Get-DevOpsTeamAdministrator -Exactly -Times 1 -ParameterFilter {
                $MemberDescriptor -eq 'Microsoft.TeamFoundation.Identity;S-1-9-live'
            }
        }
    }

    Context "when the team-administrator state cannot be resolved" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam\user@example.com' -and $Type -eq 'LiveTeamMembers'
            } -MockWith { return $mockMember }

            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $null }
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
            Mock -CommandName List-DevOpsTeams -MockWith { return $null }
        }

        It "treats the membership lookup as Unchanged and logs a warning instead of throwing" {
            $result = Get-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com' -IsTeamAdmin $true
            $result.status | Should -Be 'Unchanged'
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1
        }
    }
}
