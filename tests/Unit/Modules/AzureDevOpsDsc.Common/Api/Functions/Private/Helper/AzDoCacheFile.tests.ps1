$currentFile = $MyInvocation.MyCommand.Path

Describe 'Cache file encryption' -Tag 'Unit', 'Helper', 'Security' {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'AzDoCacheFile.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # The file helpers live one-per-file; dot-source them all so cross-calls resolve.
        ForEach ($fn in 'Write-AzDoCacheFile', 'Read-AzDoCacheFile', 'Get-AzDoCacheFileHeader',
                        'Protect-AzDoCacheData', 'Unprotect-AzDoCacheData', 'Test-AzDoIsWindows')
        {
            . (Get-FunctionItem "$fn.ps1")
        }

        # The permission change itself is covered by Protect-AzDoCachePath's own tests.
        Mock -CommandName Protect-AzDoCachePath


        # A stand-in for DPAPI that runs anywhere: reversible, and the output shares no text with the input.
        function Script:Invoke-TestCipher
        {
            param ([System.Byte[]]$Data)
            $out = [System.Byte[]]::new($Data.Length)
            for ($i = 0; $i -lt $Data.Length; $i++) { $out[$i] = $Data[$i] -bxor 0x5A }
            return , $out
        }

        function Script:New-TestContent
        {
            return @(
                [PSCustomObject]@{ Key = 'Project\One'; Value = [PSCustomObject]@{ id = 1; name = 'visible-name-one' } },
                [PSCustomObject]@{ Key = 'Project\Two'; Value = [PSCustomObject]@{ id = 2; name = 'visible-name-two' } }
            )
        }
    }

    BeforeEach {
        $script:path = Join-Path -Path $TestDrive -ChildPath ('{0}.clixml' -f [System.Guid]::NewGuid().ToString('N'))
    }

    Context 'Write-AzDoCacheFile outside Windows' {

        BeforeAll {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
            Mock -CommandName Protect-AzDoCacheData -MockWith { throw 'must not be called' }
        }

        It 'Writes plain CLIXML that Import-Clixml reads' {
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            $imported = Import-Clixml -LiteralPath $script:path
            @($imported).Count     | Should -Be 2
            $imported[1].Value.name | Should -Be 'visible-name-two'
            Should -Invoke -CommandName Protect-AzDoCacheData -Exactly 0
        }

        It 'Restricts the file it wrote to its owner' {
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 1 -ParameterFilter { $Path -eq $script:path }
        }
    }

    Context 'Write-AzDoCacheFile on Windows' {

        BeforeAll {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
            Mock -CommandName Protect-AzDoCacheData -MockWith { return , (Invoke-TestCipher -Data $Data) }
            Mock -CommandName Unprotect-AzDoCacheData -MockWith { return , (Invoke-TestCipher -Data $Data) }
        }

        It 'Writes the marker followed by the encrypted content' {
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            $bytes  = [System.IO.File]::ReadAllBytes($script:path)
            $header = Get-AzDoCacheFileHeader
            [System.Text.Encoding]::ASCII.GetString($bytes, 0, $header.Length) | Should -Be "AZDODSC-DPAPI-1`n"
            [System.Text.Encoding]::UTF8.GetString($bytes) | Should -Not -Match 'visible-name'
            [System.Text.Encoding]::UTF8.GetString($bytes) | Should -Not -Match 'Project'
            Should -Invoke -CommandName Protect-AzDoCacheData -Exactly 1
        }

        It 'Restricts the file it wrote to its owner' {
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 1 -ParameterFilter { $Path -eq $script:path }
        }

        It 'Round-trips a list of items' {
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            $read = Read-AzDoCacheFile -Path $script:path
            @($read).Count      | Should -Be 2
            $read[0].Key        | Should -Be 'Project\One'
            $read[1].Value.name | Should -Be 'visible-name-two'
        }

        It 'Round-trips a single item as a one-item collection' {
            Write-AzDoCacheFile -Path $script:path -InputObject @((New-TestContent)[0])

            $read = Read-AzDoCacheFile -Path $script:path
            @($read).Count | Should -Be 1
            foreach ($item in $read) { $item.Key | Should -Be 'Project\One' }
        }

        It 'Round-trips an empty collection as an empty collection, not null' {
            Write-AzDoCacheFile -Path $script:path -InputObject @()

            $read = Read-AzDoCacheFile -Path $script:path
            $null -eq $read | Should -BeFalse
            @($read).Count  | Should -Be 0
        }

        It 'Round-trips a hashtable as a hashtable' {
            Write-AzDoCacheFile -Path $script:path -InputObject @{ 'descriptor-1' = @{ displayName = 'Someone' } } -Depth 3

            $read = Read-AzDoCacheFile -Path $script:path
            $read -is [hashtable]              | Should -BeTrue
            $read['descriptor-1'].displayName | Should -Be 'Someone'
        }

        It 'Keeps nested values down to the depth it is given' {
            $deep = [PSCustomObject]@{ a = [PSCustomObject]@{ b = [PSCustomObject]@{ c = [PSCustomObject]@{ d = 'deep-value' } } } }

            Write-AzDoCacheFile -Path $script:path -InputObject $deep -Depth 6

            (Read-AzDoCacheFile -Path $script:path).a.b.c.d | Should -Be 'deep-value'
        }

        It 'Writes the file unencrypted, with a warning, when encryption fails' {
            Mock -CommandName Protect-AzDoCacheData -MockWith { throw 'profile not loaded' }
            Mock -CommandName Write-Warning

            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            Should -Invoke -CommandName Write-Warning -Exactly 1 -ParameterFilter { $Message -match 'unencrypted' -and $Message -match 'profile not loaded' }
            $imported = Import-Clixml -LiteralPath $script:path
            @($imported).Count | Should -Be 2
            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 1 -ParameterFilter { $Path -eq $script:path }
        }
    }

    Context 'Read-AzDoCacheFile' {

        BeforeAll {
            Mock -CommandName Protect-AzDoCacheData -MockWith { return , (Invoke-TestCipher -Data $Data) }
            Mock -CommandName Unprotect-AzDoCacheData -MockWith { return , (Invoke-TestCipher -Data $Data) }
        }

        It 'Reads a plain CLIXML file written by an earlier version, whatever the platform: on Windows <OnWindows>' -ForEach @(
            @{ OnWindows = $true }
            @{ OnWindows = $false }
        ) {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $OnWindows }
            Export-Clixml -InputObject (New-TestContent) -LiteralPath $script:path -Depth 6

            $read = Read-AzDoCacheFile -Path $script:path

            @($read).Count | Should -Be 2
            $read[0].Key   | Should -Be 'Project\One'
            Should -Invoke -CommandName Unprotect-AzDoCacheData -Exactly 0
        }

        It 'Reads a plain file of one item as a one-item collection' {
            Export-Clixml -InputObject @((New-TestContent)[0]) -LiteralPath $script:path -Depth 6

            $read = Read-AzDoCacheFile -Path $script:path

            @($read).Count | Should -Be 1
            foreach ($item in $read) { $item.Key | Should -Be 'Project\One' }
        }

        It 'Throws an error that says how to recover when the file cannot be decrypted' {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)
            Mock -CommandName Unprotect-AzDoCacheData -MockWith { throw 'Key not valid for use in specified state.' }

            { Read-AzDoCacheFile -Path $script:path } | Should -Throw -ExpectedMessage '*could not be decrypted*New-AzDoAuthenticationProvider*Key not valid*'
        }

        It 'Leaves the file readable by another reader while it is open' {
            Export-Clixml -InputObject (New-TestContent) -LiteralPath $script:path -Depth 6
            $other = [System.IO.File]::Open($script:path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            try
            {
                $read = Read-AzDoCacheFile -Path $script:path
                @($read).Count | Should -Be 2
            }
            finally
            {
                $other.Dispose()
            }
        }
    }

    Context 'DPAPI' {

        It 'Encrypts and decrypts for the current account' -Skip:(-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $clear     = [System.Text.Encoding]::UTF8.GetBytes('visible-name-one')
            $protected = Protect-AzDoCacheData -Data $clear

            $protected -is [System.Byte[]] | Should -BeTrue
            [System.Text.Encoding]::UTF8.GetString($protected) | Should -Not -Match 'visible-name-one'
            [System.Text.Encoding]::UTF8.GetString((Unprotect-AzDoCacheData -Data $protected)) | Should -Be 'visible-name-one'
        }

        It 'Does not decrypt data that has been changed' -Skip:(-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $protected = Protect-AzDoCacheData -Data ([System.Text.Encoding]::UTF8.GetBytes('visible-name-one'))
            $protected[$protected.Length - 1] = $protected[$protected.Length - 1] -bxor 0xFF

            { Unprotect-AzDoCacheData -Data $protected } | Should -Throw
        }

        It 'Writes a file on Windows that holds no readable content and reads it back' -Skip:(-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            Write-AzDoCacheFile -Path $script:path -InputObject (New-TestContent)

            $bytes = [System.IO.File]::ReadAllBytes($script:path)
            [System.Text.Encoding]::UTF8.GetString($bytes)    | Should -Not -Match 'visible-name'
            [System.Text.Encoding]::Unicode.GetString($bytes) | Should -Not -Match 'visible-name'

            $read = Read-AzDoCacheFile -Path $script:path
            @($read).Count      | Should -Be 2
            $read[1].Value.name | Should -Be 'visible-name-two'
        }

        It 'Is not available outside Windows' -Skip:([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            { Protect-AzDoCacheData -Data ([System.Byte[]]@(1, 2, 3)) } | Should -Throw
        }
    }
}
