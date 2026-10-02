$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoWikiPagePath" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-AzDoWikiPagePath.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It "adds a leading slash when missing" {
        Format-AzDoWikiPagePath -Path 'Runbooks/On-call' | Should -Be '/Runbooks/On-call'
    }

    It "converts backslashes to forward slashes" {
        Format-AzDoWikiPagePath -Path 'Runbooks\On-call' | Should -Be '/Runbooks/On-call'
    }

    It "removes a trailing separator" {
        Format-AzDoWikiPagePath -Path '/Runbooks/On-call/' | Should -Be '/Runbooks/On-call'
    }

    It "collapses repeated separators" {
        Format-AzDoWikiPagePath -Path '//Runbooks//On-call' | Should -Be '/Runbooks/On-call'
    }

    It "returns the root for an empty path" {
        Format-AzDoWikiPagePath -Path '' | Should -Be '/'
    }

    It "returns the root for a path of only separators" {
        Format-AzDoWikiPagePath -Path '///' | Should -Be '/'
    }

    It "leaves an already-canonical path unchanged" {
        Format-AzDoWikiPagePath -Path '/Runbooks/On-call' | Should -Be '/Runbooks/On-call'
    }
}
