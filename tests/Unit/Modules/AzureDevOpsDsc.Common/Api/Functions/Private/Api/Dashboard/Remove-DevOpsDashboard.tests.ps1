$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsDashboard' -Tag "Unit", "Dashboard", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsDashboard.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Get-DevOpsDashboardUri.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod
    }

    It 'sends a DELETE addressed by the dashboard id' {
        Remove-DevOpsDashboard -Organization 'myorg' -ProjectName 'My Project' -DashboardId 'd1'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and
            $Uri -eq 'https://dev.azure.com/myorg/My%20Project/_apis/dashboard/dashboards/d1?api-version=7.1-preview.3'
        }
    }

    It 'throws with the dashboard id when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { Remove-DevOpsDashboard -Organization 'myorg' -ProjectName 'P' -DashboardId 'd1' } | Should -Throw '*id d1*API error*'
    }
}
