$currentFile = $MyInvocation.MyCommand.Path

Describe 'Update-DevOpsDashboard' -Tag "Unit", "Dashboard", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-DevOpsDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Get-DevOpsDashboardUri.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod
    }

    It 'PUTs to the dashboard id with the eTag and without widgets' {
        Update-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -TeamName 'T' -DashboardId 'd1' -ETag '7' -Name 'Overview' -Description 'D' -RefreshInterval 0

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Method -eq 'PUT' -and
            $Uri -eq 'https://dev.azure.com/myorg/P/T/_apis/dashboard/dashboards/d1?api-version=7.1-preview.3' -and
            $body.id -eq 'd1' -and $body.eTag -eq '7' -and $body.name -eq 'Overview' -and
            $body.description -eq 'D' -and $body.refreshInterval -eq 0 -and
            ($body.PSObject.Properties.Name -notcontains 'widgets')
        }
    }

    It 'throws with the dashboard id when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { Update-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -DashboardId 'd1' -ETag '7' -Name 'Overview' } |
            Should -Throw '*id d1*API error*'
    }
}
