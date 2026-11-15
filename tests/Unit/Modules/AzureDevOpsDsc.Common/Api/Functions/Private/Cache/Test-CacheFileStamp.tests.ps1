$currentFile = $MyInvocation.MyCommand.Path

Describe 'Test-CacheFileStamp' -Tag "Unit", "Cache" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-CacheFileStamp.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Set-CacheFileStamp.ps1')
        . (Get-FunctionItem 'Protect-AzDoCacheSecret.ps1')
        . (Get-FunctionItem 'Export-CacheObject.ps1')
        . (Get-FunctionItem 'Import-CacheObject.ps1')
        . (Get-FunctionItem 'Set-CacheObject.ps1')
        . (Get-FunctionItem 'Refresh-CacheObject.ps1')

        # The real file helpers, so these tests write and read a cache file the way the module
        # does: encrypted with DPAPI on Windows, plain CLIXML elsewhere.
        ForEach ($fn in 'Write-AzDoCacheFile', 'Read-AzDoCacheFile', 'Get-AzDoCacheFileHeader',
                        'Protect-AzDoCacheData', 'Unprotect-AzDoCacheData', 'Test-AzDoIsWindows')
        {
            . (Get-FunctionItem "$fn.ps1")
        }

        Mock -CommandName Protect-AzDoCachePath

        $script:previousCacheDirectory = $ENV:AZDODSC_CACHE_DIRECTORY
        $ENV:AZDODSC_CACHE_DIRECTORY = Join-Path -Path $TestDrive -ChildPath 'stamp'
        $null = New-Item -Path (Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'Cache') -ItemType Directory -Force
        $script:cacheFile = Join-Path -Path (Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'Cache') -ChildPath 'LiveTeams.clixml'

        function New-TestCache {
            param([string[]]$Keys)
            $list = [System.Collections.Generic.List[CacheItem]]::new()
            foreach ($key in $Keys) { $list.Add([CacheItem]::new($key, "value-$key")) }
            return ,$list
        }
    }

    BeforeEach {
        Remove-Variable -Name AzDoCacheFileStamp -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name AzDoLiveTeams -Scope Global -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:cacheFile -Force -ErrorAction SilentlyContinue
    }

    AfterAll {
        $ENV:AZDODSC_CACHE_DIRECTORY = $script:previousCacheDirectory
        Remove-Variable -Name AzDoCacheFileStamp -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name AzDoLiveTeams -Scope Global -ErrorAction SilentlyContinue
    }

    It 'Is false when nothing has been recorded' {
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    It 'Is true after the live cache is exported' {
        $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams

        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeTrue
    }

    It 'Is true after Set-CacheObject and after an import' {
        Set-CacheObject -CacheType 'LiveTeams' -Content (New-TestCache -Keys 'A', 'B')
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeTrue

        Remove-Variable -Name AzDoCacheFileStamp -Scope Global
        $null = Import-CacheObject -CacheType 'LiveTeams'
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeTrue
    }

    It 'Is false when the exported content is not the live cache' {
        $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
        Export-CacheObject -CacheType 'LiveTeams' -Content (New-TestCache -Keys 'A', 'B')

        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    It 'Is false when the content does not hold CacheItem objects' {
        $Global:AzDoLiveTeams = @('raw')
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams

        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    It 'Is false once an item is added to, removed from or replaced in the cache' {
        $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
        $Global:AzDoLiveTeams.Add([CacheItem]::new('C', 'value-C'))
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse

        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
        $Global:AzDoLiveTeams.RemoveAt(0)
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse

        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
        $Global:AzDoLiveTeams[0] = [CacheItem]::new('B', 'other')
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    It 'Is false when the file was written again by something else' {
        $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams

        Export-Clixml -InputObject (New-TestCache -Keys 'A', 'B', 'C').ToArray() -LiteralPath $script:cacheFile
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    It 'Is false when only the last write time of the file changed' {
        $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams

        (Get-Item -LiteralPath $script:cacheFile).LastWriteTimeUtc = [datetime]::UtcNow.AddMinutes(5)
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    It 'Is false when the file has been deleted or the cache unloaded' {
        $Global:AzDoLiveTeams = New-TestCache -Keys 'A'
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams

        Remove-Variable -Name AzDoLiveTeams -Scope Global
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse

        $Global:AzDoLiveTeams = New-TestCache -Keys 'A'
        Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
        Remove-Item -LiteralPath $script:cacheFile -Force
        Test-CacheFileStamp -CacheType 'LiveTeams' -Path $script:cacheFile | Should -BeFalse
    }

    Context 'Refresh-CacheObject' {

        It 'Keeps the cache in memory when it already matches the file' {
            $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
            $before = $Global:AzDoLiveTeams
            Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
            Mock -CommandName Read-AzDoCacheFile

            Refresh-CacheObject -CacheType 'LiveTeams'

            Assert-MockCalled -CommandName Read-AzDoCacheFile -Exactly 0
            [object]::ReferenceEquals($before, $Global:AzDoLiveTeams) | Should -BeTrue
        }

        It 'Leaves a List[CacheItem] behind when the global held an array' {
            Set-CacheObject -CacheType 'LiveTeams' -Content (New-TestCache -Keys 'A', 'B')
            $Global:AzDoLiveTeams -is [System.Collections.Generic.List[CacheItem]] | Should -BeFalse

            Refresh-CacheObject -CacheType 'LiveTeams'

            $Global:AzDoLiveTeams -is [System.Collections.Generic.List[CacheItem]] | Should -BeTrue
            $Global:AzDoLiveTeams.Key | Should -Be @('A', 'B')
        }

        It 'Reloads the file when the cache changed in memory after the export' {
            $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
            Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
            $Global:AzDoLiveTeams.Add([CacheItem]::new('C', 'value-C'))

            Refresh-CacheObject -CacheType 'LiveTeams'

            $Global:AzDoLiveTeams.Key | Should -Be @('A', 'B')
        }

        It 'Reloads the file when another process has written it' {
            $Global:AzDoLiveTeams = New-TestCache -Keys 'A', 'B'
            Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams
            Export-Clixml -InputObject (New-TestCache -Keys 'X', 'Y', 'Z').ToArray() -LiteralPath $script:cacheFile

            Refresh-CacheObject -CacheType 'LiveTeams'

            $Global:AzDoLiveTeams.Key | Should -Be @('X', 'Y', 'Z')
        }

        It 'Does not write to the output stream when the reload is skipped' {
            $Global:AzDoLiveTeams = New-TestCache -Keys 'A'
            Export-CacheObject -CacheType 'LiveTeams' -Content $Global:AzDoLiveTeams

            @(Refresh-CacheObject -CacheType 'LiveTeams').Count | Should -Be 0
        }
    }
}
