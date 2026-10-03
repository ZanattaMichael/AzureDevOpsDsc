$currentFile = $MyInvocation.MyCommand.Path

Describe "Import-CacheObject Tests" -Tag "Unit", "Cache" {

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Import-CacheObject.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')

        # Mock the necessary Commands and Variables
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('Project', 'Team', 'Group', 'SecurityDescriptor') }
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Import-Clixml -MockWith { return @([PSCustomObject]@{ Key = 'Key1'; Value = 'Value1' }, [PSCustomObject]@{ Key = 'Key2'; Value = 'Value2' }) }
        Mock -CommandName Set-Variable
        # A path Join-Path can resolve on any OS ('C:\Cache' has no drive on Linux). Test-Path and
        # Import-Clixml are mocked, so nothing is read from it.
        $ENV:AZDODSC_CACHE_DIRECTORY = $TestDrive

    }

    AfterAll {
        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue
    }

    Context "Valid CacheType parameter" {

        It "Imports the cache object successfully" {
            Import-CacheObject -CacheType 'Project'

            Assert-MockCalled -CommandName Test-Path -Exactly 1
            Assert-MockCalled -CommandName Import-Clixml -Exactly 1
            Assert-MockCalled -CommandName Set-Variable -Exactly 1
        }

        It "Sets the correct variable name and value" {
            Import-CacheObject -CacheType 'Team'

            Assert-MockCalled -CommandName Set-Variable -Exactly 1 -ParameterFilter {
                $Name -eq 'AzDoTeam' -and $Scope -eq 'Global' -and $Force -eq $true
            }
        }
    }

    Context "Cache file not found" {
        BeforeEach {
            Mock -CommandName Test-Path -MockWith { return $false }
            Mock -CommandName Write-Warning
            Mock -CommandName Write-Verbose
        }

        It "Reports the missing file as verbose output, not a warning" {
            Import-CacheObject -CacheType 'Project'

            Assert-MockCalled -CommandName Write-Verbose -Exactly 1 -ParameterFilter {
                $Message -match 'Cache file not found'
            }
            Assert-MockCalled -CommandName Write-Warning -Exactly 0
        }

        It "Sets an empty in-memory cache when the cache file is not found" {
            Mock -CommandName Set-Variable

            Import-CacheObject -CacheType 'Project'

            Assert-MockCalled -CommandName Set-Variable -Exactly 1 -ParameterFilter {
                $Name -eq 'AzDoProject' -and $Scope -eq 'Global' -and $Value.Count -eq 0
            }
        }
    }

    Context "Environment variable not set" {
        BeforeEach {
            $ENV:AZDODSC_CACHE_DIRECTORY = $null
        }

        It "Throws an exception if the environment variable is not set" {
            {
                Import-CacheObject -CacheType 'Project'
            } | Should -Throw
        }
    }

}
