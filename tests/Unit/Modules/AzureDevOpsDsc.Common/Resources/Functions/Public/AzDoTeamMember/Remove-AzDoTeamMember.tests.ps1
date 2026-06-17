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

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsTeamMember
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Resolve-AzDoProject -MockWith { Get-CacheItem -Key $ProjectName -Type 'LiveProjects' }
        Mock -CommandName List-DevOpsTeams -MockWith { return $null }
        Mock -CommandName Find-AzDoIdentity -MockWith { return $null }
        Mock -CommandName Get-DevOpsSecurityDescriptor -MockWith { return $null }
    }

    Context "when team and member are found in cache (member from LiveGroups)" {

        BeforeEach {
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
}
