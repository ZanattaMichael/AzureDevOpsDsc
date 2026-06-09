$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTeamMember" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
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

        Mock -CommandName Write-Verbose
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
}
