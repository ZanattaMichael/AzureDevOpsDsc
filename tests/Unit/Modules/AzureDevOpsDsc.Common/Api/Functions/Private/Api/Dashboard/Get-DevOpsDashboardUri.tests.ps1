$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsDashboardUri' -Tag "Unit", "Dashboard", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsDashboardUri.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It 'addresses the project collection when no team is given' {
        Get-DevOpsDashboardUri -Organization 'myorg' -ProjectName 'My Project' |
            Should -Be 'https://dev.azure.com/myorg/My%20Project/_apis/dashboard/dashboards?api-version=7.1-preview.3'
    }

    It 'addresses the team collection, escaping the team name' {
        Get-DevOpsDashboardUri -Organization 'myorg' -ProjectName 'My Project' -TeamName 'My Project Team' |
            Should -Be 'https://dev.azure.com/myorg/My%20Project/My%20Project%20Team/_apis/dashboard/dashboards?api-version=7.1-preview.3'
    }

    It 'addresses a single dashboard by id' {
        Get-DevOpsDashboardUri -Organization 'myorg' -ProjectName 'P' -TeamName 'T' -DashboardId 'abc' |
            Should -Be 'https://dev.azure.com/myorg/P/T/_apis/dashboard/dashboards/abc?api-version=7.1-preview.3'
    }
}
