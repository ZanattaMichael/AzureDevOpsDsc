$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTeamMember" -Tag "Unit", "TeamMember" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTeamMember.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # Set-AzDoTeamMember delegates to New-AzDoTeamMember; load it explicitly
        . (Get-FunctionItem 'New-AzDoTeamMember.ps1').FullName

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
        # Set-AzDoTeamMember delegates to New-AzDoTeamMember, so mock the dependencies of New-AzDoTeamMember
        Mock -CommandName New-DevOpsTeamMember
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
    }

    Context "when team and member are found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            } -MockWith { return $mockTeam }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq '[TestProject]\user@example.com' -and $Type -eq 'LiveGroups'
            } -MockWith { return $mockMember }
        }

        It "delegates to New-AzDoTeamMember and calls New-DevOpsTeamMember" {
            # Set-AzDoTeamMember delegates entirely to New-AzDoTeamMember because
            # team membership has no update semantics (add/remove only)
            Set-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName New-DevOpsTeamMember -Exactly -Times 1
        }

        It "delegates to New-AzDoTeamMember and calls Add-CacheItem" {
            Set-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1
        }

        It "delegates to New-AzDoTeamMember and calls Export-CacheObject for LiveTeamMembers" {
            Set-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'TestTeam' -MemberName 'user@example.com'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTeamMembers'
            }
        }
    }

    Context "when the team or member is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "propagates the error from New-AzDoTeamMember and does not call New-DevOpsTeamMember" {
            Set-AzDoTeamMember -ProjectName 'TestProject' -TeamName 'NonExistentTeam' -MemberName 'user@example.com'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-DevOpsTeamMember -Exactly -Times 0
        }
    }
}
