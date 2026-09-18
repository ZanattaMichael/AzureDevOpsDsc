$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-CacheItem' -Tag "Unit", "Cache" {

    AfterAll {
        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue
    }

    BeforeAll {

        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-CacheItem.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')

        Mock -CommandName Get-CacheObject -MockWith {
            param ([string]$CacheType)

            $list = [System.Collections.Generic.List[CacheItem]]::New()

            switch ($CacheType)
            {
                "Project"   {
                    $list.Add([CacheItem]::New("myKey", "someValue"))
                }
                "Group"     {
                    $list.Add([CacheItem]::New("anotherKey", "anotherValue"))
                }
                default     {
                    throw "Invalid CacheType"
                }
            }

            return $list

        }

        Mock -CommandName Set-Variable -MockWith {}

    }

    It 'Removes item from Project cache when key matches' {
        $cache = Get-CacheObject -CacheType "Project"
        Remove-CacheItem -Key "myKey" -Type "Project"
        $global:AzDoProject | Should -BeNullOrEmpty
    }

    It 'Removes item from Group cache when key matches' {
        $cache = Get-CacheObject -CacheType "Group"
        Remove-CacheItem -Key "anotherKey" -Type "Group"
        $global:AzDoGroup | Should -BeNullOrEmpty
    }

    It 'Handles non-matching key correctly' {
        $cache = Get-CacheObject -CacheType "Group"
        Remove-CacheItem -Key "nonMatchingKey" -Type "Group"
        $global:AzDoGroup | Should -Be $null
    }

    It 'Validates Type parameter against cache objects' {
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('Project', 'Group', 'Team', 'SecurityDescriptor') }
        { Remove-CacheItem -Key "sampleKey" -Type "InvalidType" } | Should -Throw
    }

    Context 'A cache that is absent, empty, or has more than one item' {

        # The tests above only ever exercise the Count -eq 1 fast path, which is why three bugs
        # in the removal loop survived. All three surfaced on the live integration run as
        # "Cannot index into a null array" from AzDoSecureFile's Remove.

        BeforeEach {
            $script:testList  = [System.Collections.Generic.List[CacheItem]]::New()
            $script:persisted = $null

            Mock -CommandName Get-CacheObject -MockWith { return $script:testList }

            # Assert on what gets written back, not on the list handed in. Remove-CacheItem
            # assigns through a [List[CacheItem]] cast, and PowerShell builds a NEW list from
            # the enumerable rather than aliasing it - so the removals land on a copy that only
            # reaches the caller via Set-Variable.
            Mock -CommandName Set-Variable -MockWith { $script:persisted = $Value }
        }


        It 'Does not throw when the cache is absent' {
            # $cache.Count on $null is $null, and '0 .. $null' is 0..0 - so the old loop indexed
            # into a null array.
            Mock -CommandName Get-CacheObject -MockWith { return $null }
            { Remove-CacheItem -Key 'anything' -Type 'Project' } | Should -Not -Throw
        }

        It 'Does not throw when the cache is empty' {
            { Remove-CacheItem -Key 'anything' -Type 'Project' } | Should -Not -Throw
        }

        It 'Removes the last item of several without indexing past the end' {
            # '0 .. $cache.Count' is inclusive, so it addressed one element beyond the list.
            'a', 'b', 'c' | ForEach-Object { $script:testList.Add([CacheItem]::New($_, $_)) }

            { Remove-CacheItem -Key 'c' -Type 'Project' } | Should -Not -Throw
            @($script:persisted | ForEach-Object { $_.Key }) | Should -Be @('a', 'b')
        }

        It 'Removes an item from the middle and leaves the rest intact' {
            'a', 'b', 'c' | ForEach-Object { $script:testList.Add([CacheItem]::New($_, $_)) }

            Remove-CacheItem -Key 'b' -Type 'Project'
            @($script:persisted | ForEach-Object { $_.Key }) | Should -Be @('a', 'c')
        }

        It 'Removes every matching entry when a key appears more than once' {
            # Removing by ascending index shifted the entries still to be examined, so a second
            # match was missed or the wrong element was dropped.
            'a', 'dup', 'dup', 'b' | ForEach-Object { $script:testList.Add([CacheItem]::New($_, $_)) }

            Remove-CacheItem -Key 'dup' -Type 'Project'
            @($script:persisted | ForEach-Object { $_.Key }) | Should -Be @('a', 'b')
        }

        It 'Leaves the cache untouched when no key matches' {
            'a', 'b' | ForEach-Object { $script:testList.Add([CacheItem]::New($_, $_)) }

            Remove-CacheItem -Key 'absent' -Type 'Project'
            @($script:persisted | ForEach-Object { $_.Key }) | Should -Be @('a', 'b')
        }
    }
}
