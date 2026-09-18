$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoQueryFolder" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoQueryFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
    }

    Context "when the folder is in its desired state" {

        It "takes no action, because a folder has no mutable properties" {
            Set-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }

    Context "when a query occupies the folder path" {

        It "reports the conflict rather than resolving it by deleting the query" {
            $lookup = @{ reason = 'PathIsNotAFolder' }

            Set-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
