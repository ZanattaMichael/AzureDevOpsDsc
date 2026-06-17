$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTeamSettings" -Tag "Unit", "TeamSettings" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTeamSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Set-DevOpsTeamSettings
    }

    Context "when invoked" {

        It "does not throw (team settings cannot be removed)" {
            { Remove-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam' } | Should -Not -Throw
        }

        It "is a no-op and makes no API call" {
            Remove-AzDoTeamSettings -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Set-DevOpsTeamSettings -Exactly -Times 0
        }
    }
}
