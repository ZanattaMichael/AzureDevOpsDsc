$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoDashboard" -Tag "Unit", "Dashboard" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsDashboard -MockWith { return $null }
    }

    Context "when the LookupResult carries the live dashboard" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith { return $null }
        }

        It "uses the cached id and eTag rather than looking them up again" {
            $live = [PSCustomObject]@{ id = 'd1'; eTag = '7'; name = 'Overview'; description = 'Old'; refreshInterval = 0 }

            Set-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -TeamName 'Team A' -Description 'New' -LookupResult @{ liveCache = $live }

            Assert-MockCalled -CommandName Get-DevOpsDashboard -Exactly -Times 0
            Assert-MockCalled -CommandName Update-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
                $DashboardId -eq 'd1' -and $ETag -eq '7' -and $TeamName -eq 'Team A' -and $Description -eq 'New'
            }
        }
    }

    Context "when a setting is not managed" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith {
                return [PSCustomObject]@{ id = 'd1'; eTag = '7'; name = 'Overview'; description = 'Live description'; refreshInterval = 5 }
            }
        }

        It "sends the live value back, since the update replaces the dashboard settings" {
            Set-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -Description '' -RefreshInterval -1

            Assert-MockCalled -CommandName Update-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
                $Description -eq 'Live description' -and $RefreshInterval -eq 5
            }
        }

        It "sends the desired RefreshInterval when it is managed" {
            Set-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -RefreshInterval 0

            Assert-MockCalled -CommandName Update-DevOpsDashboard -Exactly -Times 1 -ParameterFilter {
                $RefreshInterval -eq 0 -and $Description -eq 'Live description'
            }
        }
    }

    Context "when the dashboard no longer exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsDashboard -MockWith { return $null }
        }

        It "writes an error rather than creating it" {
            Set-AzDoDashboard -DashboardName 'Overview' -ProjectName 'TestProject' -Description 'New'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsDashboard -Exactly -Times 0
        }
    }
}
