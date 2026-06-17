$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTeamSettings" -Tag "Unit", "TeamSettings" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTeamSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Set-AzDoTeamSettings
    }

    Context "when invoked" {

        It "delegates to Set-AzDoTeamSettings (settings always exist for a team)" {
            New-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -BugsBehavior 'asRequirements'
            Assert-MockCalled -CommandName Set-AzDoTeamSettings -Exactly -Times 1
        }

        It "forwards its parameters to Set-AzDoTeamSettings" {
            New-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' -DefaultAreaPath 'TestProject\Frontend'
            Assert-MockCalled -CommandName Set-AzDoTeamSettings -Exactly -Times 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $TeamName -eq 'TestTeam' -and $DefaultAreaPath -eq 'TestProject\Frontend'
            }
        }
    }
}
