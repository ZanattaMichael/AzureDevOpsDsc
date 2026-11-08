$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoArcSecretFilePath Tests" -Tag "Unit", "ManagedIdentity", "Authentication" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoArcSecretFilePath.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Not mocked, so the harness does not load it; the real directory resolution is exercised.
        . (Get-FunctionItem 'Get-AzDoArcTokensDirectory.ps1').FullName

        $script:originalProgramData = $env:ProgramData
        if ([String]::IsNullOrWhiteSpace($env:ProgramData)) {
            $env:ProgramData = 'C:\ProgramData'
        }

        $WindowsTokens = '{0}\AzureConnectedMachineAgent\Tokens' -f $env:ProgramData
        $LinuxTokens   = '/var/opt/azcmagent/tokens'
    }

    AfterAll {
        $env:ProgramData = $script:originalProgramData
    }

    Context "On Windows" {

        BeforeAll {
            Mock -CommandName Get-OperatingSystemInfo -MockWith { return @{ Windows = $true; Linux = $false; MacOS = $false } }
        }

        It "should accept a .key file directly inside the tokens directory" {
            Test-AzDoArcSecretFilePath -Path "$WindowsTokens\4f6c1d2e-9a7b-4c3d-8e1f-0a2b3c4d5e6f.key" | Should -BeTrue
        }

        It "should accept a .key file whose path differs only by case" {
            Test-AzDoArcSecretFilePath -Path "$($WindowsTokens.ToUpperInvariant())\SECRET.KEY" | Should -BeTrue
        }

        It "should accept forward slashes as separators" {
            Test-AzDoArcSecretFilePath -Path (($WindowsTokens -replace '\\', '/') + '/secret.key') | Should -BeTrue
        }

        It "should accept a path with a redundant '.' segment that still resolves inside the directory" {
            Test-AzDoArcSecretFilePath -Path "$WindowsTokens\.\secret.key" | Should -BeTrue
        }

        It "should accept a traversal that resolves back inside the directory" {
            Test-AzDoArcSecretFilePath -Path "$WindowsTokens\..\Tokens\secret.key" | Should -BeTrue
        }

        It "should reject '<Path>'" -TestCases @(
            @{ Path = 'C:\Windows\win.ini';                                                           Reason = 'a file elsewhere on the system drive' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\..\..\..\Windows\win.ini';    Reason = 'a .. traversal out of the directory' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\..\..\..\Windows\evil.key';   Reason = 'a .. traversal that keeps the .key extension' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.txt';                 Reason = 'a non-.key file inside the directory' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret';                     Reason = 'a file with no extension inside the directory' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.key.txt';             Reason = 'a .key in the middle of the name' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\nested\secret.key';          Reason = 'a nested subdirectory' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens';                            Reason = 'the directory itself' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\secret.key';                        Reason = 'the parent directory' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\TokensX\secret.key';                Reason = 'a sibling directory sharing the prefix' }
            @{ Path = 'D:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.key';                 Reason = 'the same tree on another drive' }
            @{ Path = '\\attacker\share\AzureConnectedMachineAgent\Tokens\secret.key';               Reason = 'a UNC share' }
            @{ Path = 'Tokens\secret.key';                                                           Reason = 'a relative path' }
            @{ Path = 'secret.key';                                                                  Reason = 'a bare file name' }
            @{ Path = '/var/opt/azcmagent/tokens/secret.key';                                        Reason = 'the Linux directory on Windows' }
            @{ Path = 'MOCKMOCKMOCKMOCKMOCKMOCK';                                                    Reason = 'an arbitrary token' }
        ) {
            param ($Path, $Reason)

            Test-AzDoArcSecretFilePath -Path $Path | Should -BeFalse -Because "$Reason must not be read"
        }

        It "should reject an empty path" {
            Test-AzDoArcSecretFilePath -Path '' | Should -BeFalse
        }

        It "should reject a whitespace path" {
            Test-AzDoArcSecretFilePath -Path '   ' | Should -BeFalse
        }

        It "should reject a null path" {
            Test-AzDoArcSecretFilePath -Path $null | Should -BeFalse
        }

        It "should fall back to C:\ProgramData when ProgramData is not set" {
            $saved = $env:ProgramData
            try {
                $env:ProgramData = $null
                Test-AzDoArcSecretFilePath -Path 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.key' | Should -BeTrue
                Test-AzDoArcSecretFilePath -Path 'C:\Other\AzureConnectedMachineAgent\Tokens\secret.key' | Should -BeFalse
            }
            finally {
                $env:ProgramData = $saved
            }
        }

        It "should follow a relocated ProgramData" {
            $saved = $env:ProgramData
            try {
                $env:ProgramData = 'D:\Data'
                Test-AzDoArcSecretFilePath -Path 'D:\Data\AzureConnectedMachineAgent\Tokens\secret.key' | Should -BeTrue
                Test-AzDoArcSecretFilePath -Path 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.key' | Should -BeFalse
            }
            finally {
                $env:ProgramData = $saved
            }
        }
    }

    Context "On Linux" {

        BeforeAll {
            Mock -CommandName Get-OperatingSystemInfo -MockWith { return @{ Windows = $false; Linux = $true; MacOS = $false } }
        }

        It "should accept a .key file directly inside the tokens directory" {
            Test-AzDoArcSecretFilePath -Path "$LinuxTokens/4f6c1d2e-9a7b-4c3d-8e1f-0a2b3c4d5e6f.key" | Should -BeTrue
        }

        It "should accept a traversal that resolves back inside the directory" {
            Test-AzDoArcSecretFilePath -Path "$LinuxTokens/../tokens/secret.key" | Should -BeTrue
        }

        It "should reject '<Path>'" -TestCases @(
            @{ Path = '/etc/shadow';                                              Reason = 'a file elsewhere on the system' }
            @{ Path = '/var/opt/azcmagent/tokens/../../../../etc/shadow';         Reason = 'a .. traversal out of the directory' }
            @{ Path = '/var/opt/azcmagent/tokens/../../../../etc/evil.key';       Reason = 'a .. traversal that keeps the .key extension' }
            @{ Path = '/var/opt/azcmagent/tokens/secret.txt';                     Reason = 'a non-.key file inside the directory' }
            @{ Path = '/var/opt/azcmagent/tokens/secret.KEY';                     Reason = 'a different-case extension on a case-sensitive platform' }
            @{ Path = '/var/opt/azcmagent/Tokens/secret.key';                     Reason = 'a different-case directory on a case-sensitive platform' }
            @{ Path = '/var/opt/azcmagent/tokens/nested/secret.key';              Reason = 'a nested subdirectory' }
            @{ Path = '/var/opt/azcmagent/tokens';                                Reason = 'the directory itself' }
            @{ Path = '/var/opt/azcmagent/secret.key';                            Reason = 'the parent directory' }
            @{ Path = '/var/opt/azcmagent/tokens2/secret.key';                    Reason = 'a sibling directory sharing the prefix' }
            @{ Path = 'tokens/secret.key';                                        Reason = 'a relative path' }
            @{ Path = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.key'; Reason = 'the Windows directory on Linux' }
        ) {
            param ($Path, $Reason)

            Test-AzDoArcSecretFilePath -Path $Path | Should -BeFalse -Because "$Reason must not be read"
        }

        It "should reject an empty path" {
            Test-AzDoArcSecretFilePath -Path '' | Should -BeFalse
        }
    }
}
