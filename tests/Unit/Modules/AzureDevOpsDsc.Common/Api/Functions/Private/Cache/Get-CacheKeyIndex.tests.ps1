$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-CacheKeyIndex' -Tag "Unit", "Cache" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-CacheKeyIndex.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-CacheKeyIndex.ps1')

        function New-TestCache {
            param([string[]]$Keys)
            $list = [System.Collections.Generic.List[CacheItem]]::new()
            foreach ($key in $Keys) { $list.Add([CacheItem]::new($key, "value-$key")) }
            return ,$list
        }
    }

    BeforeEach {
        $Global:AzDoCacheKeyIndex = @{}
    }

    AfterAll {
        Remove-Variable -Name AzDoCacheKeyIndex -Scope Global -ErrorAction SilentlyContinue
    }

    It 'Builds an index of every key in the cache' {
        $cache = New-TestCache -Keys 'A', 'B', 'C'

        $index = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        $index.Count | Should -Be 3
        $index['B'].Value | Should -Be 'value-B'
    }

    It 'Looks keys up case-insensitively, like -eq' {
        $cache = New-TestCache -Keys 'MyProject'

        $index = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        $index.ContainsKey('myproject') | Should -BeTrue
    }

    It 'Returns an empty index for an empty cache' {
        $cache = New-TestCache -Keys @()

        $index = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        $null -eq $index | Should -BeFalse
        $index.Count | Should -Be 0
    }

    It 'Reuses the index while the list and its count are unchanged' {
        $cache = New-TestCache -Keys 'A', 'B'

        $first = Get-CacheKeyIndex -Type 'Project' -Cache $cache
        $second = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        [object]::ReferenceEquals($first, $second) | Should -BeTrue
    }

    It 'Rebuilds the index when the list changes behind its back' {
        $cache = New-TestCache -Keys 'A', 'B'
        $first = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        $cache.Add([CacheItem]::new('C', 'value-C'))
        $second = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        [object]::ReferenceEquals($first, $second) | Should -BeFalse
        $second.ContainsKey('C') | Should -BeTrue
    }

    It 'Rebuilds the index when the cache is replaced with a different list' {
        $cache = New-TestCache -Keys 'A', 'B'
        $null = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        $replacement = New-TestCache -Keys 'X', 'Y'
        $index = Get-CacheKeyIndex -Type 'Project' -Cache $replacement

        $index.ContainsKey('A') | Should -BeFalse
        $index.ContainsKey('X') | Should -BeTrue
    }

    It 'Keeps a separate index per cache type' {
        $projects = New-TestCache -Keys 'P1'
        $groups = New-TestCache -Keys 'G1'

        $projectIndex = Get-CacheKeyIndex -Type 'Project' -Cache $projects
        $groupIndex = Get-CacheKeyIndex -Type 'Group' -Cache $groups

        $projectIndex.ContainsKey('G1') | Should -BeFalse
        $groupIndex.ContainsKey('G1') | Should -BeTrue
    }

    It 'Returns $null for a cache holding the same key twice, so callers fall back to scanning' {
        $cache = New-TestCache -Keys 'A', 'a'

        $index = Get-CacheKeyIndex -Type 'Project' -Cache $cache

        $index | Should -BeNullOrEmpty
        $Global:AzDoCacheKeyIndex.ContainsKey('Project') | Should -BeFalse
    }
}
