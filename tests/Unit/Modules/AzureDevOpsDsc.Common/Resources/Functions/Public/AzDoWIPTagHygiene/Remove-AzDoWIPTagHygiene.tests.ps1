$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoWIPTagHygiene" -Tag "Unit", "WIPTags" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoWIPTagHygiene.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Warning
    }

    Context "when Ensure is Absent" {

        It "takes no action and says so, rather than silently doing nothing" {
            Remove-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug')
            Assert-MockCalled -CommandName Write-Warning -Times 1
        }
    }
}
