$currentFile = $MyInvocation.MyCommand.Path

Describe "Export-CacheObject" -Tag "Unit", "Cache" {

    AfterAll {
        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue
    }

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Export-CacheObject.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
        . (Get-FunctionItem 'Protect-AzDoCacheSecret.ps1')

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Set-CacheFileStamp.ps1')
        . (Get-FunctionItem 'Test-CacheFileStamp.ps1')

        # Mock dependencies
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('Project', 'Team', 'Group', 'SecurityDescriptor') } -Verifiable
        Mock -CommandName Test-Path -MockWith { param ($Path) return $false } -Verifiable
        Mock -CommandName New-Item -MockWith { param ($Path, $ItemType) } -Verifiable
        Mock -CommandName Write-AzDoCacheFile -MockWith { param ($Path, $InputObject, $Depth) } -Verifiable
        Mock -CommandName Protect-AzDoCachePath

    }

    BeforeEach {
        $env:AZDODSC_CACHE_DIRECTORY = "C:\MockPath\AzDoCache"
    }

    AfterEach {
        Remove-Variable -Name AZDODSC_CACHE_DIRECTORY -ErrorAction SilentlyContinue
    }

    Context "when the environment variable AZDODSC_CACHE_DIRECTORY is not set" {
        BeforeEach {
            $env:AZDODSC_CACHE_DIRECTORY = $null
        }

        It "should throw an error" {
            { Export-CacheObject -CacheType 'Project' -Content @() } | Should -Throw "The environment variable 'AZDODSC_CACHE_DIRECTORY' is not set. Please set the variable to the path of the cache directory."
        }
    }

    Context "when the environment variable AZDODSC_CACHE_DIRECTORY is set" {
        BeforeEach {
            $env:AZDODSC_CACHE_DIRECTORY = "C:\Temp\AzDoCache"
        }

        It "should create the cache directory if it does not exist" {
            Mock -CommandName Test-Path -MockWith { param ($Path) return $false } -Verifiable
            Mock -CommandName New-Item -Verifiable

            Export-CacheObject -CacheType 'Project' -Content @()

            Assert-MockCalled -CommandName New-Item -Exactly 1 -ParameterFilter {
                $Path     -eq "C:\Temp\AzDoCache\Cache" -and
                $ItemType -eq "Directory"
            }
        }

        It "should not create the cache directory if it already exists" {
            Mock -CommandName Test-Path -MockWith { param ($Path) return $true } -Verifiable
            Mock -CommandName New-Item

            Export-CacheObject -CacheType 'Project' -Content @()

            Assert-MockCalled -CommandName New-Item -Exactly 0 -Scope It
        }

        It "should save content to the cache file" {

            Mock -CommandName Write-AzDoCacheFile -Verifiable

            $content = @(
                [PSCustomObject]@{ Name = 'Project1'; Id = 1 },
                [PSCustomObject]@{ Name = 'Project2'; Id = 2 }
            )

            Export-CacheObject -CacheType 'Project' -Content $content
            Assert-MockCalled -CommandName Write-AzDoCacheFile -Times 1

        }

        It "should use the default depth value of 6" {

            Mock -CommandName Write-AzDoCacheFile

            $content = @(
                [PSCustomObject]@{ Name = 'Project1'; Id = 1 },
                [PSCustomObject]@{ Name = 'Project2'; Id = 2 }
            )

            Export-CacheObject -CacheType 'Project' -Content $content

            Assert-MockCalled -CommandName Write-AzDoCacheFile -Times 1 -ParameterFilter {
                $Depth       -eq 6 -and
                $Path        -eq "C:\Temp\AzDoCache\Cache\Project.clixml"
            }
        }

        It "should use the specified depth value" {

            Mock -CommandName Write-AzDoCacheFile

            $content = @(
                [PSCustomObject]@{ Name = 'Project1'; Id = 1 },
                [PSCustomObject]@{ Name = 'Project2'; Id = 2 }
            )

            Export-CacheObject -CacheType 'Project' -Content $content -Depth 5

            Assert-MockCalled -CommandName Write-AzDoCacheFile -Times 1 -ParameterFilter {
                $Depth       -eq 5 -and
                $Path        -eq "C:\Temp\AzDoCache\Cache\Project.clixml"
            }
        }
    }

    Context "cache file permissions" {

        # TestDrive rather than a C:\ path so these also run on Linux.
        BeforeEach {
            $env:AZDODSC_CACHE_DIRECTORY = $TestDrive
            $script:expectedDirectory = Join-Path -Path $TestDrive -ChildPath 'Cache'
            $script:expectedFile      = Join-Path -Path $script:expectedDirectory -ChildPath 'Project.clixml'
        }

        # Write-AzDoCacheFile restricts the file it writes (see its own tests); Export-CacheObject
        # restricts the directory it creates and hands the file to Write-AzDoCacheFile.
        It "restricts the cache directory it creates and writes the cache file through Write-AzDoCacheFile" {
            Mock -CommandName Test-Path -MockWith { $false }
            Mock -CommandName New-Item
            Mock -CommandName Write-AzDoCacheFile

            Export-CacheObject -CacheType 'Project' -Content @()

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 1 -ParameterFilter { $Path -eq $script:expectedDirectory }
            Should -Invoke -CommandName Write-AzDoCacheFile -Exactly 1 -ParameterFilter { $Path -eq $script:expectedFile }
        }

        It "does not restrict the directory again when it already exists" {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName New-Item
            Mock -CommandName Write-AzDoCacheFile

            Export-CacheObject -CacheType 'Project' -Content @()

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 0
            Should -Invoke -CommandName Write-AzDoCacheFile -Exactly 1 -ParameterFilter { $Path -eq $script:expectedFile }
        }

        It "throws when the cache file cannot be written" {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Write-AzDoCacheFile -MockWith { throw 'disk full' }

            { Export-CacheObject -CacheType 'Project' -Content @() } | Should -Throw
        }
    }

    Context "when invalid CacheType is provided" {
        It "should throw an error" {
            { Export-CacheObject -CacheType 'InvalidType' -Content @() } | Should -Throw
        }
    }
}
