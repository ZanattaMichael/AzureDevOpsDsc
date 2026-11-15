$currentFile = $MyInvocation.MyCommand.Path

Describe "Add-CacheItem" -Tag "Unit", "Cache" {

    AfterAll {
        Remove-Variable -Name AzDoProject -ErrorAction SilentlyContinue
    }

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Add-CacheItem.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Get-CacheKeyIndex.ps1')
        . (Get-FunctionItem 'Protect-AzDoCacheSecret.ps1')

        # Mock dependencies
        Mock -CommandName Get-CacheObject -MockWith { return @() }

    }

    Context "when adding a new cache item" {

        BeforeEach {
            $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global
        }

        It "should retrieve the current cache" {
            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project'

            Assert-MockCalled -CommandName Get-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'Project'
            }
        }

        It "should create a new cache if the current cache is empty" {
            Mock -CommandName Get-CacheObject -MockWith { return @() }
            Mock -CommandName Write-Verbose
            Mock -CommandName Set-Variable -Verifiable

            # The messages are only written when verbose output is on.
            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project' -Verbose

            Assert-MockCalled -CommandName Write-Verbose -Exactly 1 -ParameterFilter {
                $Message -eq '[Add-CacheItem] Cache is empty. Creating new cache.'
            }

        }

        It "should add a new cache item with the correct key and value" {
            Mock -CommandName Get-CacheObject -MockWith { return @() }
            Mock -CommandName Write-Verbose

            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project'

            $cache = Get-Variable -Name "AzDoProject" -Scope Global -ValueOnly
            $cache[0].Key | Should -Be 'MyKey'
            $cache[0].Value | Should -Be 'MyValue'
        }
    }

    Context "when the cache already contains the key" {

        BeforeEach {
            Mock -CommandName Get-CacheObject -MockWith {
                return $Global:AzDoProject
            }
        }

        AfterEach {
            Remove-Variable -Name "AzDoProject" -Scope Global
        }

        It "should remove the existing cache item" {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Warning
            Mock -CommandName Remove-CacheItem -Verifiable -MockWith {
                $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global
            }

            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project'
            Add-CacheItem -Key 'MyKey' -Value 'NewValue' -Type 'Project'

            $cache = Get-Variable -Name "AzDoProject" -Scope Global -ValueOnly
            $cache[0].Key | Should -Be 'MyKey'
            $cache[0].Value | Should -Be 'NewValue'

        }

        It "should add the new cache item after removing the old one" {
            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project'

            $cache = Get-Variable -Name "AzDoProject" -Scope Global -ValueOnly
            $cache[0].Key | Should -Be 'MyKey'
            $cache[0].Value | Should -Be 'MyValue'
        }

        It "should suppress the warning if SuppressWarning switch is present" {
            Mock -CommandName Write-Warning
            Mock -CommandName Write-Verbose

            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project' -SuppressWarning -Verbose
            Add-CacheItem -Key 'MyKey' -Value 'NewValue' -Type 'Project' -SuppressWarning -Verbose

            Assert-MockCalled -CommandName Write-Warning -Exactly 0
            Assert-MockCalled -CommandName Write-Verbose -Times 3

        }

        It "should not call Write-Verbose when verbose output is off" {
            Mock -CommandName Write-Verbose

            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project' -SuppressWarning

            Assert-MockCalled -CommandName Write-Verbose -Exactly 0
        }

        It "should still call Write-Verbose when verbose messages are logged to a file" {
            Mock -CommandName Write-Verbose
            $previous = $env:AZDO_VERBOSELOGGING_FILEPATH
            $env:AZDO_VERBOSELOGGING_FILEPATH = Join-Path -Path $TestDrive -ChildPath 'verbose.log'

            try
            {
                Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project' -SuppressWarning
            }
            finally
            {
                $env:AZDO_VERBOSELOGGING_FILEPATH = $previous
            }

            Assert-MockCalled -CommandName Write-Verbose -Times 3
        }

        It "should display a warning if SuppressWarning switch is not present" {
            Mock -CommandName Write-Warning

            Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project'
            Add-CacheItem -Key 'MyKey' -Value 'NewValue' -Type 'Project'

            Assert-MockCalled -CommandName Write-Warning -Exactly 1
        }
    }

    Context "when replacing a key in a live cache" {

        BeforeEach {
            $Global:AzDoCacheKeyIndex = @{}
            $script:liveCache = [System.Collections.Generic.List[CacheItem]]::new()
            $null = Set-Variable -Name "AzDoProject" -Value $script:liveCache -Scope Global
            Mock -CommandName Get-CacheObject -MockWith { return ,$script:liveCache }
            Mock -CommandName Write-Warning
        }

        AfterEach {
            Remove-Variable -Name "AzDoProject" -Scope Global -ErrorAction SilentlyContinue
            $Global:AzDoCacheKeyIndex = @{}
        }

        It "should replace the existing item in place without duplicating the key" {
            Add-CacheItem -Key 'Key1' -Value 'Value1' -Type 'Project'
            Add-CacheItem -Key 'Key2' -Value 'Value2' -Type 'Project'
            Add-CacheItem -Key 'key1' -Value 'Updated' -Type 'Project'

            $cache = Get-Variable -Name "AzDoProject" -Scope Global -ValueOnly
            $cache.Count | Should -Be 2
            @($cache | Where-Object { $_.Key -eq 'Key1' }).Count | Should -Be 1
            ($cache | Where-Object { $_.Key -eq 'Key1' }).Value | Should -Be 'Updated'
            ($cache | Where-Object { $_.Key -eq 'Key2' }).Value | Should -Be 'Value2'
        }

        It "should add to the live list rather than a copy" {
            Add-CacheItem -Key 'Key1' -Value 'Value1' -Type 'Project'

            $script:liveCache.Count | Should -Be 1
        }

        It "should keep the key index in step with the cache" {
            Add-CacheItem -Key 'Key1' -Value 'Value1' -Type 'Project'
            Add-CacheItem -Key 'Key1' -Value 'Value2' -Type 'Project'

            $index = Get-CacheKeyIndex -Type 'Project' -Cache $script:liveCache
            $index.Count | Should -Be 1
            $index['Key1'].Value | Should -Be 'Value2'
        }

        It "should fill a large cache without rescanning it for every key" {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            foreach ($i in 1..2000) {
                Add-CacheItem -Key "Key$i" -Value $i -Type 'Project'
            }
            $timer.Stop()

            $script:liveCache.Count | Should -Be 2000
            # Generous bound: the old linear Where-Object scan took far longer than this.
            $timer.Elapsed.TotalSeconds | Should -BeLessThan 60
        }
    }

    Context "when the value carries a secret" {

        BeforeEach {
            $script:liveCache = [System.Collections.Generic.List[CacheItem]]::new()
            Remove-Variable -Name AzDoCacheKeyIndex -Scope Global -ErrorAction SilentlyContinue
            Mock -CommandName Get-CacheObject -MockWith { return ,$script:liveCache }
        }

        AfterEach {
            Remove-Variable -Name AzDoCacheKeyIndex -Scope Global -ErrorAction SilentlyContinue
        }

        It "should blank a secret variable value before the item is stored" {
            $value = '{"id":1,"variables":{"PLAIN":{"value":"visible"},"API_KEY":{"value":"echoed-secret","isSecret":true}}}' | ConvertFrom-Json

            Add-CacheItem -Key 'Project\Group' -Value $value -Type 'LiveVariableGroups'

            $script:liveCache.Count | Should -Be 1
            $script:liveCache[0].Value.variables.API_KEY.value | Should -BeNullOrEmpty
            $script:liveCache[0].Value.variables.PLAIN.value   | Should -Be 'visible'
        }

        It "should blank a service connection key before the item is stored" {
            $value = '{"id":"e1","authorization":{"parameters":{"tenantid":"tenant","serviceprincipalkey":"echoed-secret"}}}' | ConvertFrom-Json

            Add-CacheItem -Key 'Project\Connection' -Value $value -Type 'LiveServiceConnections'

            $script:liveCache[0].Value.authorization.parameters.serviceprincipalkey | Should -BeNullOrEmpty
            $script:liveCache[0].Value.authorization.parameters.tenantid            | Should -Be 'tenant'
        }

        It "should blank an audit stream key before the item is stored" {
            $value = '{"id":3,"consumerInputs":{"WorkspaceId":"workspace","SharedKey":"echoed-secret"}}' | ConvertFrom-Json

            Add-CacheItem -Key 'Stream' -Value $value -Type 'LiveAuditStreams'

            $script:liveCache[0].Value.consumerInputs.SharedKey   | Should -BeNullOrEmpty
            $script:liveCache[0].Value.consumerInputs.WorkspaceId | Should -Be 'workspace'
        }

        It "should not look for secrets in a cache type that cannot hold one" {
            Mock -CommandName Protect-AzDoCacheSecret

            Add-CacheItem -Key 'Key1' -Value ([PSCustomObject]@{ password = 'not-a-cache-secret' }) -Type 'Project'

            Should -Invoke -CommandName Protect-AzDoCacheSecret -Exactly 0
            $script:liveCache[0].Value.password | Should -Be 'not-a-cache-secret'
        }
    }

}
