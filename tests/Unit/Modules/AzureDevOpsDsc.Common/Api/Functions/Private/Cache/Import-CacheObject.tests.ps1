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
        . (Get-FunctionItem 'Set-CacheFileStamp.ps1')
        . (Get-FunctionItem 'Test-CacheFileStamp.ps1')
        . (Get-FunctionItem 'Protect-AzDoCacheSecret.ps1')

        # Mock the necessary Commands and Variables
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('Project', 'Team', 'Group', 'SecurityDescriptor') }
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Read-AzDoCacheFile -MockWith { return @([PSCustomObject]@{ Key = 'Key1'; Value = 'Value1' }, [PSCustomObject]@{ Key = 'Key2'; Value = 'Value2' }) }
        Mock -CommandName Set-Variable
        # A path Join-Path can resolve on any OS ('C:\Cache' has no drive on Linux). Test-Path and
        # Read-AzDoCacheFile are mocked, so nothing is read from it.
        $ENV:AZDODSC_CACHE_DIRECTORY = $TestDrive

    }

    AfterAll {
        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue
    }

    Context "Valid CacheType parameter" {

        It "Imports the cache object successfully" {
            Import-CacheObject -CacheType 'Project'

            Assert-MockCalled -CommandName Test-Path -Exactly 1
            Assert-MockCalled -CommandName Read-AzDoCacheFile -Exactly 1
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

    Context "A cache file that holds a secret written by an earlier version" {
        BeforeEach {
            Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('LiveVariableGroups') }
            Mock -CommandName Read-AzDoCacheFile -MockWith {
                return , @([PSCustomObject]@{
                    Key   = 'Project\Group'
                    Value = '{"id":1,"variables":{"PLAIN":{"value":"visible"},"API_KEY":{"value":"echoed-secret","isSecret":true}}}' | ConvertFrom-Json
                })
            }
            Mock -CommandName Export-CacheObject
            Mock -CommandName Write-Warning
        }

        It "Blanks the secret in the cache it returns" {
            $cache = Import-CacheObject -CacheType 'LiveVariableGroups'

            $cache[0].Value.variables.API_KEY.value | Should -BeNullOrEmpty
            $cache[0].Value.variables.PLAIN.value   | Should -Be 'visible'
        }

        It "Rewrites the file without the secret and warns" {
            $null = Import-CacheObject -CacheType 'LiveVariableGroups'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups' -and $null -eq $Content[0].Value.variables.API_KEY.value
            }
            Assert-MockCalled -CommandName Write-Warning -Exactly 1 -ParameterFilter { $Message -match 'secret value' }
        }

        It "Still returns the cache, with a warning, when the file cannot be rewritten" {
            Mock -CommandName Export-CacheObject -MockWith { throw 'read-only' }

            $cache = Import-CacheObject -CacheType 'LiveVariableGroups'

            $cache.Count | Should -Be 1
            Assert-MockCalled -CommandName Write-Warning -Exactly 1 -ParameterFilter { $Message -match 'Could not rewrite' }
        }

        It "Does not rewrite a file that holds no secret" {
            Mock -CommandName Read-AzDoCacheFile -MockWith {
                return , @([PSCustomObject]@{ Key = 'Project\Group'; Value = '{"id":1,"variables":{"API_KEY":{"value":null,"isSecret":true}}}' | ConvertFrom-Json })
            }

            $null = Import-CacheObject -CacheType 'LiveVariableGroups'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 0
            Assert-MockCalled -CommandName Write-Warning -Exactly 0
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
