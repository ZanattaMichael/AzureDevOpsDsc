$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-NormalizedWikiPageContent" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-NormalizedWikiPageContent.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It "collapses CRLF to LF" {
        ConvertTo-NormalizedWikiPageContent -Content "# Title`r`n`r`nBody" | Should -Be "# Title`n`nBody"
    }

    It "collapses lone CR to LF" {
        ConvertTo-NormalizedWikiPageContent -Content "# Title`rBody" | Should -Be "# Title`nBody"
    }

    It "strips trailing whitespace on each line" {
        ConvertTo-NormalizedWikiPageContent -Content "# Title   `nBody  " | Should -Be "# Title`nBody"
    }

    It "ignores a single trailing newline" {
        ConvertTo-NormalizedWikiPageContent -Content "# Title`n" | Should -Be "# Title"
    }

    It "does not strip significant leading whitespace" {
        ConvertTo-NormalizedWikiPageContent -Content "- item`n  - nested" | Should -Be "- item`n  - nested"
    }

    It "returns an empty string for null input" {
        ConvertTo-NormalizedWikiPageContent -Content $null | Should -Be ''
    }

    It "returns an empty string for empty input" {
        ConvertTo-NormalizedWikiPageContent -Content '' | Should -Be ''
    }

    It "treats equivalent content as equal after normalization" {
        $a = ConvertTo-NormalizedWikiPageContent -Content "# On-call`r`n"
        $b = ConvertTo-NormalizedWikiPageContent -Content "# On-call   `n"
        $a | Should -Be $b
    }
}
