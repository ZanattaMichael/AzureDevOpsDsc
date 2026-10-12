$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsDashboard' -Tag "Unit", "Dashboard", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Get-DevOpsDashboardUri.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{
                value = @(
                    [PSCustomObject]@{ id = 'team1';    name = 'Overview'; dashboardScope = 'project_Team'; groupId = 'team-guid' }
                    [PSCustomObject]@{ id = 'project1'; name = 'Overview'; dashboardScope = 'project';      groupId = $null }
                    [PSCustomObject]@{ id = 'team2';    name = 'Bugs';     dashboardScope = 'project_Team'; groupId = 'team-guid' }
                )
            }
        }
    }

    It 'lists on the team route and matches by name' {
        $result = Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -TeamName 'T' -Name 'Bugs'

        $result.id | Should -Be 'team2'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $Method -eq 'GET' -and $Uri -eq 'https://dev.azure.com/myorg/P/T/_apis/dashboard/dashboards?api-version=7.1-preview.3'
        }
    }

    It 'only considers project-scoped dashboards when no team is given' {
        $result = Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -Name 'Overview'
        $result.id | Should -Be 'project1'

        Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -Name 'Bugs' | Should -BeNullOrEmpty
    }

    It 'recognizes the numeric form of the project scope' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ value = @([PSCustomObject]@{ id = 'project1'; name = 'Overview'; dashboardScope = 2; groupId = 'x' }) }
        }

        (Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -Name 'Overview').id | Should -Be 'project1'
    }

    It 'returns $null when no dashboard matches the name' {
        Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -TeamName 'T' -Name 'Missing' | Should -BeNullOrEmpty
    }

    It 'throws with the scope when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -TeamName 'T' -Name 'Bugs' } |
            Should -Throw "*team 'T'*API error*"
    }
}
