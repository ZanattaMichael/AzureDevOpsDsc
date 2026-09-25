$currentFile = $MyInvocation.MyCommand.Path

Describe 'ConvertTo-GitRefToken' -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-GitRefToken.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

    }

    It 'Encodes a single-segment branch name to its hex/UTF-16LE form' {
        # 'main' -> m,a,i,n each as a UTF-16LE code unit (little-endian byte pairs).
        $result = ConvertTo-GitRefToken -RefName 'main'
        $result | Should -Be '6d00610069006e00'
    }

    It 'Encodes each segment of a multi-segment ref separately, rejoined with a literal slash' {
        $result = ConvertTo-GitRefToken -RefName 'release/1.0'

        $segments = $result -split '/'
        $segments.Count | Should -Be 2

        # Each segment decodes independently back to its own ref path component.
        $bytes0 = [byte[]]::new($segments[0].Length / 2)
        for ($i = 0; $i -lt $bytes0.Length; $i++) { $bytes0[$i] = [Convert]::ToByte($segments[0].Substring($i * 2, 2), 16) }
        [System.Text.Encoding]::Unicode.GetString($bytes0) | Should -Be 'release'

        $bytes1 = [byte[]]::new($segments[1].Length / 2)
        for ($i = 0; $i -lt $bytes1.Length; $i++) { $bytes1[$i] = [Convert]::ToByte($segments[1].Substring($i * 2, 2), 16) }
        [System.Text.Encoding]::Unicode.GetString($bytes1) | Should -Be '1.0'
    }

    It 'Encodes a non-ASCII branch name without error' {
        $result = ConvertTo-GitRefToken -RefName 'función'
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match '^[0-9a-fA-F]+$'
    }

    It 'Round-trips through a manual UTF-16LE decode' {
        $refName = 'ключ'
        $encoded = ConvertTo-GitRefToken -RefName $refName

        $bytes = [byte[]]::new($encoded.Length / 2)
        for ($i = 0; $i -lt $bytes.Length; $i++) { $bytes[$i] = [Convert]::ToByte($encoded.Substring($i * 2, 2), 16) }
        [System.Text.Encoding]::Unicode.GetString($bytes) | Should -Be $refName
    }

    It 'Throws for an empty ref name (Mandatory parameter, never reached with one in practice)' {
        # Get-AzDoGitPermission only calls in once BranchName/TagName is confirmed non-empty, so
        # this documents the boundary rather than exercising a real call path.
        { ConvertTo-GitRefToken -RefName '' } | Should -Throw
    }
}
