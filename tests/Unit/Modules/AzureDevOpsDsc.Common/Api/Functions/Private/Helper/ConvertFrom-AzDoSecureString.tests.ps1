$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertFrom-AzDoSecureString" -Tag "Unit", "Helper", "Authentication" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "ConvertFrom-AzDoSecureString.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

    }

    It "should round-trip an ASCII string" {
        $secure = ConvertTo-SecureString -String "Hello, World!" -AsPlainText -Force

        ConvertFrom-AzDoSecureString -SecureString $secure | Should -Be "Hello, World!"
    }

    It "should round-trip a string with non-ASCII characters" {
        # On Linux and macOS PtrToStringAuto reads the UTF-16 BSTR as UTF-8 and returns garbage for
        # anything outside ASCII; this is the case the helper exists for.
        $plain  = "pässwörd-こんにちは-€"
        $secure = ConvertTo-SecureString -String $plain -AsPlainText -Force

        ConvertFrom-AzDoSecureString -SecureString $secure | Should -BeExactly $plain
    }

    It "should round-trip a string that looks like a token" {
        $plain  = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abc-DEF_123=="
        $secure = ConvertTo-SecureString -String $plain -AsPlainText -Force

        ConvertFrom-AzDoSecureString -SecureString $secure | Should -BeExactly $plain
    }

    It "should return a string" {
        $secure = ConvertTo-SecureString -String "value" -AsPlainText -Force

        ConvertFrom-AzDoSecureString -SecureString $secure | Should -BeOfType [String]
    }

    It "should leave the SecureString usable afterwards" {
        $secure = ConvertTo-SecureString -String "twice" -AsPlainText -Force

        ConvertFrom-AzDoSecureString -SecureString $secure | Should -Be "twice"
        ConvertFrom-AzDoSecureString -SecureString $secure | Should -Be "twice"
    }

    It "should throw when SecureString is null" {
        { ConvertFrom-AzDoSecureString -SecureString $null } | Should -Throw
    }
}
