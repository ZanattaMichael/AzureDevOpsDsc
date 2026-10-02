$currentFile = $MyInvocation.MyCommand.Path

Describe 'ConvertFrom-GitRefToken' -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertFrom-GitRefToken.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Decoding is the mirror image of ConvertTo-GitRefToken - load it so encode/decode can be
        # exercised together without hand-computing hex literals for every case.
        . (Get-FunctionItem 'ConvertTo-GitRefToken.ps1').FullName

    }

    It 'Decodes a single-segment hex/UTF-16LE branch name' {
        $result = ConvertFrom-GitRefToken -EncodedRef '6d00610069006e00'
        $result | Should -Be 'main'
    }

    It 'Decodes a multi-segment ref, rejoined with a literal slash' {
        $encoded = ConvertTo-GitRefToken -RefName 'release/1.0'
        $result  = ConvertFrom-GitRefToken -EncodedRef $encoded
        $result | Should -Be 'release/1.0'
    }

    It 'Round-trips a non-ASCII branch name' {
        $refName = 'función'
        $encoded = ConvertTo-GitRefToken -RefName $refName
        $result  = ConvertFrom-GitRefToken -EncodedRef $encoded
        $result | Should -Be $refName
    }

    It 'Round-trips a branch name with several segments and non-ASCII characters' {
        $refName = 'feature/ключ-1'
        $encoded = ConvertTo-GitRefToken -RefName $refName
        $result  = ConvertFrom-GitRefToken -EncodedRef $encoded
        $result | Should -Be $refName
    }

    It 'Throws for an empty encoded ref (Mandatory parameter, never reached with one in practice)' {
        { ConvertFrom-GitRefToken -EncodedRef '' } | Should -Throw
    }
}
