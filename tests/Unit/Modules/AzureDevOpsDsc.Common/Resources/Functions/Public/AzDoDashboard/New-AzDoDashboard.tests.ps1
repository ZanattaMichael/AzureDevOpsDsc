$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoDashboard" -Tag "Unit", "Dashboard" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsDashboard -MockWith { return $null }
    }

    It "creates the dashboard in the team with the managed settings" {
        New-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -TeamName 'Team A' -Description 'Sprint overview' -RefreshInterval 5

        Assert-MockCalled -CommandName New-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
            $Organization -eq 'TestOrganization' -and $ProjectName -eq 'TestProject' -and $TeamName -eq 'Team A' -and
            $Name -eq 'Overview' -and $Description -eq 'Sprint overview' -and $RefreshInterval -eq 5
        }
    }

    It "does not send unmanaged settings" {
        New-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -Description '' -RefreshInterval -1

        Assert-MockCalled -CommandName New-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
            (-not $PesterBoundParameters.ContainsKey('Description')) -and (-not $PesterBoundParameters.ContainsKey('RefreshInterval'))
        }
    }

    It "sends a RefreshInterval of 0" {
        New-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -RefreshInterval 0

        Assert-MockCalled -CommandName New-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
            $PesterBoundParameters.ContainsKey('RefreshInterval') -and $RefreshInterval -eq 0
        }
    }
}
