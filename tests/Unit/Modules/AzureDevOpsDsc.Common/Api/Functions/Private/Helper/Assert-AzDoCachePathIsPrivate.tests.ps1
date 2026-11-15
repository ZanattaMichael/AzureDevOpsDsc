$currentFile = $MyInvocation.MyCommand.Path

Describe "Assert-AzDoCachePathIsPrivate" -Tag "Unit", "Helper", "Security" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Assert-AzDoCachePathIsPrivate.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Warning
        $script:savedOverride = $env:AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY
    }

    AfterAll {
        $env:AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY = $script:savedOverride
    }

    BeforeEach {
        $env:AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY = $null
    }

    Context "when there is nothing to check" {

        It "returns for an empty path" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $false }

            { Assert-AzDoCachePathIsPrivate -Path '' } | Should -Not -Throw
        }

        It "returns for a directory that does not exist" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $false }

            { Assert-AzDoCachePathIsPrivate -Path (Join-Path -Path $TestDrive -ChildPath 'missing') } | Should -Not -Throw
        }

        It "does not inspect the directory on Windows, where the credential is DPAPI-encrypted" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
            Mock -CommandName Get-Item

            { Assert-AzDoCachePathIsPrivate -Path $TestDrive } | Should -Not -Throw

            Should -Invoke -CommandName Get-Item -Times 0
        }
    }

    Context "on a non-Windows platform" -Skip:$IsWindows {

        BeforeAll {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
        }

        BeforeEach {
            $script:directory = Join-Path -Path $TestDrive -ChildPath ([System.Guid]::NewGuid().ToString('N'))
            $null = New-Item -Path $script:directory -ItemType Directory -Force
        }

        It "accepts a directory only its owner can use" {
            & chmod 700 $script:directory

            { Assert-AzDoCachePathIsPrivate -Path $script:directory } | Should -Not -Throw
        }

        It "refuses a directory with <Mode> permissions" -ForEach @(
            @{ Mode = '755' }
            @{ Mode = '770' }
            @{ Mode = '701' }
            @{ Mode = '777' }
        ) {
            & chmod $Mode $script:directory

            { Assert-AzDoCachePathIsPrivate -Path $script:directory } | Should -Throw '*is not private*chmod 700*'
        }

        It "uses AZDODSC_CACHE_DIRECTORY when no path is given" {
            & chmod 755 $script:directory
            $saved = $env:AZDODSC_CACHE_DIRECTORY
            try
            {
                $env:AZDODSC_CACHE_DIRECTORY = $script:directory
                { Assert-AzDoCachePathIsPrivate } | Should -Throw '*is not private*'
            }
            finally
            {
                $env:AZDODSC_CACHE_DIRECTORY = $saved
            }
        }

        It "refuses a directory owned by another account" {
            & chmod 700 $script:directory
            Mock -CommandName Get-Item -MockWith { [PSCustomObject]@{ UnixMode = 'drwx------'; User = 'someone-else' } }

            { Assert-AzDoCachePathIsPrivate -Path $script:directory } | Should -Throw "*owned by 'someone-else'*"
        }

        It "accepts a directory owned by root" {
            Mock -CommandName Get-Item -MockWith { [PSCustomObject]@{ UnixMode = 'drwx------'; User = 'root' } }

            { Assert-AzDoCachePathIsPrivate -Path $script:directory } | Should -Not -Throw
        }

        It "only warns when AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY is 1" {
            & chmod 755 $script:directory
            $env:AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY = '1'

            { Assert-AzDoCachePathIsPrivate -Path $script:directory } | Should -Not -Throw

            Should -Invoke -CommandName Write-Warning -Times 1 -ParameterFilter { $Message -like '*is not private*' }
        }
    }
}
