$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoDashboard" -Tag "Unit", "Dashboard" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the dashboard exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith {
                return [PSCustomObject]@{ id = 'd1'; name = 'Overview'; description = 'Sprint overview'; refreshInterval = 5; eTag = '3' }
            }
        }

        It "returns status Unchanged and Ensure Present when nothing is managed" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -TeamName 'Team A'
            $result.status | Should -Be 'Unchanged'
            $result.Ensure | Should -Be 'Present'
        }

        It "returns the live dashboard as liveCache" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject'
            $result.liveCache.id | Should -Be 'd1'
        }

        It "passes the team through to the lookup" {
            $null = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -TeamName 'Team A'
            Assert-MockCalled -CommandName Get-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
                $TeamName -eq 'Team A' -and $Name -eq 'Overview' -and $ProjectName -eq 'TestProject'
            }
        }

        It "returns status Unchanged when Description and RefreshInterval match" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -Description 'Sprint overview' -RefreshInterval 5
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when Description differs" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -Description 'Something else'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Description'
        }

        It "returns status Changed when RefreshInterval differs, including turning refresh off" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -RefreshInterval 0
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'RefreshInterval'
        }

        It "does not compare an empty Description or the default RefreshInterval" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -Description '' -RefreshInterval -1
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }

    Context "when the dashboard has no refresh interval set" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith {
                return [PSCustomObject]@{ id = 'd1'; name = 'Overview' }
            }
        }

        It "treats the missing value as 0" {
            $result = Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -RefreshInterval 0
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context "when the dashboard does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith { return $null }
        }

        It "returns status NotFound and Ensure Absent" {
            $result = Get-AzDoDashboard -DashboardName 'Missing' -ProjectName 'TestProject'
            $result.status | Should -Be 'NotFound'
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "when the name is empty" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith { return $null }
        }

        It "returns status Error without calling the API" {
            $result = Get-AzDoDashboard -DashboardName '   ' -ProjectName 'TestProject'
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Get-DevOpsDashboard -Exactly -Times 0
        }
    }
}
