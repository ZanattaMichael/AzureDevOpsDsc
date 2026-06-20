$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTeamSettings" -Tag "Unit", "TeamSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTeamSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Test-AzDoArrayDrift.ps1')

        $mockProject = @{ id = 'project-id-001'; name = 'TestProject' }
        $mockTeam    = @{ id = 'team-id-001';    name = 'TestTeam' }

        $mockLiveSettings = [PSCustomObject]@{
            BacklogIterationPath = 'TestProject'
            DefaultIterationPath = 'TestProject\Sprint 1'
            IterationPaths       = @('TestProject\Sprint 1')
            DefaultAreaPath      = 'TestProject\Frontend'
            AreaPaths            = @('TestProject\Frontend')
            WorkingDays          = @('monday', 'tuesday')
            BugsBehavior         = 'asRequirements'
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
        Mock -CommandName List-DevOpsTeams -MockWith { return @($mockTeam) }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Get-DevOpsTeamSettings -MockWith { return $mockLiveSettings }
    }

    Context "when Ensure is Absent (no-op)" {

        It "short-circuits to NotFound without resolving the team" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -Ensure 'Absent'
            $result.status | Should -Be 'NotFound'
            Assert-MockCalled -CommandName Get-DevOpsTeamSettings -Exactly -Times 0
        }
    }

    Context "when the project or team cannot be resolved" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
            Mock -CommandName List-DevOpsTeams -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam'
            $result.status | Should -Be 'NotFound'
        }

        It "does not call Get-DevOpsTeamSettings" {
            Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Get-DevOpsTeamSettings -Exactly -Times 0
        }
    }

    Context "when project and team resolve and settings match desired state" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $mockProject }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' }    -MockWith { return $mockTeam }
        }

        It "returns status Unchanged when no properties drift" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' `
                -DefaultIterationPath 'TestProject\Sprint 1' -BugsBehavior 'asRequirements'
            $result.status | Should -Be 'Unchanged'
            $result.Ensure | Should -Be 'Present'
        }

        It "populates liveCache with the live settings" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam'
            $result.liveCache.BugsBehavior | Should -Be 'asRequirements'
        }
    }

    Context "when project and team resolve but settings drift" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $mockProject }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' }    -MockWith { return $mockTeam }
        }

        It "returns status Changed and reports the changed property" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -BugsBehavior 'off'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'BugsBehavior'
        }

        It "detects drift on iteration and area paths" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' `
                -DefaultAreaPath 'TestProject\Backend' -IterationPaths @('TestProject\Sprint 9')
            $result.propertiesChanged | Should -Contain 'DefaultAreaPath'
            $result.propertiesChanged | Should -Contain 'IterationPaths'
        }

        It "detects drift on the backlog and default iteration paths" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' `
                -BacklogIterationPath 'TestProject\Other' -DefaultIterationPath 'TestProject\Sprint 9'
            $result.propertiesChanged | Should -Contain 'BacklogIterationPath'
            $result.propertiesChanged | Should -Contain 'DefaultIterationPath'
        }

        It "detects drift on working days" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -WorkingDays @('monday')
            $result.propertiesChanged | Should -Contain 'WorkingDays'
        }

        It "detects drift on the team area paths" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -AreaPaths @('TestProject\Backend', 'TestProject\Api')
            $result.propertiesChanged | Should -Contain 'AreaPaths'
        }
    }

    Context "when project and team are resolved via the live API (cache miss)" {

        BeforeEach {
            # Cache misses for both project and team force the live-API fallback paths.
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $mockProject }
            Mock -CommandName List-DevOpsTeams -MockWith { return @($mockTeam) }
        }

        It "resolves project and team from the API and returns Unchanged" {
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam'
            $result.status | Should -Be 'Unchanged'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1
            Assert-MockCalled -CommandName List-DevOpsTeams -Times 1
        }

        It "returns NotFound when the team is not in the live list" {
            Mock -CommandName List-DevOpsTeams -MockWith { return @() }
            $result = Get-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'Ghost'
            $result.status | Should -Be 'NotFound'
        }
    }
}
