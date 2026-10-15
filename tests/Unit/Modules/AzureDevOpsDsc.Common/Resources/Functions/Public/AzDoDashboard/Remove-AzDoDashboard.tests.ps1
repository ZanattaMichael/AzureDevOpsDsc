$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoDashboard" -Tag "Unit", "Dashboard" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsDashboard -MockWith { return $null }
    }

    It "deletes by the id in the LookupResult without looking it up again" {
        Mock -CommandName Get-DevOpsDashboard -MockWith { return $null }

        Remove-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -TeamName 'Team A' -LookupResult @{ liveCache = [PSCustomObject]@{ id = 'd1' } }

        Assert-MockCalled -CommandName Get-DevOpsDashboard -Exactly -Times 0
        Assert-MockCalled -CommandName Remove-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
            $DashboardId -eq 'd1' -and $TeamName -eq 'Team A'
        }
    }

    It "looks the dashboard up when there is no LookupResult" {
        Mock -CommandName Get-DevOpsDashboard -MockWith { return [PSCustomObject]@{ id = 'd2' } }

        Remove-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject'

        Assert-MockCalled -CommandName Remove-DevOpsDashboard -Exactly -Times 1 -ParameterFilter { $DashboardId -eq 'd2' }
    }

    It "does nothing when the dashboard does not exist" {
        Mock -CommandName Get-DevOpsDashboard -MockWith { return $null }

        Remove-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject'

        Assert-MockCalled -CommandName Remove-DevOpsDashboard -Exactly -Times 0
    }
}
