$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-CacheObject Tests' -Tag "Unit", "Cache" {

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-CacheObject.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')

        $ENV:AZDODSC_CACHE_DIRECTORY = "C:\MockCacheDirectory"

        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('Project', 'Team', 'Group', 'SecurityDescriptor') }
        Mock -CommandName Import-CacheObject

    }

    AfterAll {

        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue

        if ($originalEnvironment) {
            Set-Variable -Name "ENV" -Value $originalEnvironment -Scope Global
        }
    }

    It 'Should throw error if environment variable is not set' {
        $ENV:AZDODSC_CACHE_DIRECTORY = $null
        { Get-CacheObject -CacheType 'Project' } | Should -Throw "The environment variable 'AZDODSC_CACHE_DIRECTORY' is not set. Please set the variable to the path of the cache directory."
    }

    It 'Should return cache object from memory if available' {
        $env:AZDODSC_CACHE_DIRECTORY = "C:\MockCacheDirectory"
        Set-Variable -Name "AzDoProject" -Value "ProjectCache" -Scope Global
        $result = Get-CacheObject -CacheType 'Project'
        $result | Should -Be "ProjectCache"
        Remove-Variable -Name "AzDoProject" -Scope Global -ErrorAction SilentlyContinue
    }

    It 'Should import cache object if not available in memory' {
        $env:AZDODSC_CACHE_DIRECTORY = "C:\MockCacheDirectory"
        Mock -CommandName Import-CacheObject -MockWith { return "ImportedProjectCache" }

        $result = Get-CacheObject -CacheType 'Project'
        $result | Should -Be "ImportedProjectCache"
    }

    Context 'Live cache reference' {

        BeforeEach {
            $env:AZDODSC_CACHE_DIRECTORY = "C:\MockCacheDirectory"
        }

        AfterEach {
            Remove-Variable -Name "AzDoProject" -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Should return the live list rather than a copy' {
            $list = [System.Collections.Generic.List[CacheItem]]::new()
            $list.Add([CacheItem]::new('Key1', 'Value1'))
            Set-Variable -Name "AzDoProject" -Value $list -Scope Global

            $result = Get-CacheObject -CacheType 'Project'

            [object]::ReferenceEquals($result, $list) | Should -BeTrue
        }

        It 'Should return an empty list, not $null, for an empty cache' {
            $list = [System.Collections.Generic.List[CacheItem]]::new()
            Set-Variable -Name "AzDoProject" -Value $list -Scope Global

            $result = Get-CacheObject -CacheType 'Project'

            $null -eq $result | Should -BeFalse
            $result.Count | Should -Be 0
            [object]::ReferenceEquals($result, $list) | Should -BeTrue
        }

        It 'Should normalize an object array of cache items to a stored List[CacheItem]' {
            $items = @([CacheItem]::new('Key1', 'Value1'), [CacheItem]::new('Key2', 'Value2'))
            Set-Variable -Name "AzDoProject" -Value $items -Scope Global

            $result = Get-CacheObject -CacheType 'Project'

            $result.GetType().FullName | Should -BeLike 'System.Collections.Generic.List*'
            $result.Count | Should -Be 2
            [object]::ReferenceEquals($result, (Get-Variable -Name "AzDoProject" -Scope Global -ValueOnly)) | Should -BeTrue
        }

        It 'Should let a caller see changes made through the returned list' {
            $list = [System.Collections.Generic.List[CacheItem]]::new()
            Set-Variable -Name "AzDoProject" -Value $list -Scope Global

            (Get-CacheObject -CacheType 'Project').Add([CacheItem]::new('Key1', 'Value1'))

            $Global:AzDoProject.Count | Should -Be 1
        }
    }
}
