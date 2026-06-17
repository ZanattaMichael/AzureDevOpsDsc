$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTeamSettings" -Tag "Unit", "TeamSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTeamSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockProject = @{ id = 'project-id-001'; name = 'TestProject' }
        $mockTeam    = @{ id = 'team-id-001';    name = 'TestTeam' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return $mockProject }
        Mock -CommandName List-DevOpsTeams -MockWith { return @($mockTeam) }
        Mock -CommandName Set-DevOpsTeamSettings -MockWith { return [PSCustomObject]@{ BugsBehavior = 'asTasks' } }
    }

    Context "when project and team are resolved" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $mockTeam }
        }

        It "calls Set-DevOpsTeamSettings with the resolved ProjectId and TeamId" {
            Set-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -BugsBehavior 'asTasks'
            Assert-MockCalled -CommandName Set-DevOpsTeamSettings -Exactly -Times 1 -ParameterFilter {
                $ProjectId -eq 'project-id-001' -and $TeamId -eq 'team-id-001'
            }
        }

        It "forwards the iteration, area, working-day and bugs-behavior parameters" {
            Set-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' `
                -DefaultIterationPath 'TestProject\Sprint 1' -DefaultAreaPath 'TestProject\Frontend' `
                -WorkingDays @('monday') -BugsBehavior 'off'
            Assert-MockCalled -CommandName Set-DevOpsTeamSettings -Exactly -Times 1 -ParameterFilter {
                $DefaultIterationPath -eq 'TestProject\Sprint 1' -and
                $DefaultAreaPath -eq 'TestProject\Frontend' -and
                $BugsBehavior -eq 'off'
            }
        }
    }

    Context "when the project cannot be resolved" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not call Set-DevOpsTeamSettings" {
            Set-AzDoTeamSettings -ProjectName 'NonExistentProject' -TeamName 'TestTeam'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsTeamSettings -Exactly -Times 0
        }
    }

    Context "when the team cannot be resolved" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $null }
            Mock -CommandName List-DevOpsTeams -MockWith { return @() }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not call Set-DevOpsTeamSettings" {
            Set-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'NonExistentTeam'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsTeamSettings -Exactly -Times 0
        }
    }
}
