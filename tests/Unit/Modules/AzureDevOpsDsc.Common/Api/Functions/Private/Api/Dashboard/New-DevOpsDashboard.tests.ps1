$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsDashboard' -Tag "Unit", "Dashboard", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Get-DevOpsDashboardUri.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod
    }

    It 'POSTs a team-scoped dashboard to the team route' {
        New-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -TeamName 'T' -Name 'Overview' -Description 'D' -RefreshInterval 5

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and
            $Uri -eq 'https://dev.azure.com/myorg/P/T/_apis/dashboard/dashboards?api-version=7.1-preview.3' -and
            $body.name -eq 'Overview' -and $body.dashboardScope -eq 'project_Team' -and
            $body.description -eq 'D' -and $body.refreshInterval -eq 5
        }
    }

    It 'POSTs a project-scoped dashboard to the project route, without unbound settings' {
        New-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -Name 'Overview'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Uri -eq 'https://dev.azure.com/myorg/P/_apis/dashboard/dashboards?api-version=7.1-preview.3' -and
            $body.dashboardScope -eq 'project' -and
            ($body.PSObject.Properties.Name -notcontains 'description') -and
            ($body.PSObject.Properties.Name -notcontains 'refreshInterval')
        }
    }

    It 'throws with the dashboard name when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { New-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -Name 'Overview' } | Should -Throw "*'Overview'*API error*"
    }
}
