$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoTaskGroupPermission' -Tag "Unit", "TaskGroupPermission" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTaskGroupPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Set-AzDoTaskGroupPermission
    }

    It 'applies the permissions through Set-AzDoTaskGroupPermission with the same arguments' {
        $lookup = @{ aclToken = 'project-id/tg-id' }
        New-AzDoTaskGroupPermission -ProjectName 'P' -isInherited $false -LookupResult $lookup
        Assert-MockCalled -CommandName Set-AzDoTaskGroupPermission -Times 1 -ParameterFilter {
            $ProjectName -eq 'P' -and $isInherited -eq $false -and $LookupResult.aclToken -eq 'project-id/tg-id'
        }
    }
}
