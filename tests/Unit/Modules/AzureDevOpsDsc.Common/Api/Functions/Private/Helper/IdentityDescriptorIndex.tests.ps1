$currentFile = $MyInvocation.MyCommand.Path

Describe "IdentityDescriptorIndex" -Tag "Unit", "Helper" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'IdentityDescriptorIndex.tests.ps1'
        }

        # Load the function-under-test tree and the CacheItem class the index synthesises on read.
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # The six index functions live one-per-file; dot-source them all so cross-calls resolve.
        ForEach ($fn in 'Get-IdentityDescriptorIndexPath', 'Get-IdentityDescriptorIndex',
                        'Save-IdentityDescriptorIndex', 'Clear-IdentityDescriptorIndex',
                        'Add-IdentityDescriptorIndexItem', 'Get-IdentityDescriptorIndexItem')
        {
            . (Get-FunctionItem "$fn.ps1")
        }

        . (Get-ClassFilePath '000.CacheItem')

        # Use an isolated, real cache directory so persist/reload actually touches disk.
        $script:OriginalCacheDir = $ENV:AZDODSC_CACHE_DIRECTORY
        $script:TestCacheDir = Join-Path -Path $TestDrive -ChildPath 'IdxTestCache'
        $ENV:AZDODSC_CACHE_DIRECTORY = $script:TestCacheDir

        # Helper to add a representative entry.
        function Script:Add-Sample
        {
            param([string]$Descriptor = 'aclDesc-1', [switch]$Persist)
            $p = @{
                AclDescriptor     = $Descriptor
                PrincipalName     = '[org]\Group A'
                OriginId          = 'origin-1'
                GraphDescriptor   = 'graph-1'
                AclId             = 'aclid-1'
                SubjectDescriptor = 'subject-1'
            }
            if ($Persist) { $p.Persist = $true }
            Add-IdentityDescriptorIndexItem @p
        }
    }

    AfterAll {
        $ENV:AZDODSC_CACHE_DIRECTORY = $script:OriginalCacheDir
        Remove-Variable -Name AzDoIdentityDescriptorIndex -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeEach {
        # Reset both the in-memory global and any persisted file so each test is isolated.
        $ENV:AZDODSC_CACHE_DIRECTORY = $script:TestCacheDir
        Remove-Variable -Name AzDoIdentityDescriptorIndex -Scope Global -ErrorAction SilentlyContinue
        $idxFile = Join-Path -Path $script:TestCacheDir -ChildPath 'Cache\IdentityDescriptorIndex.clixml'
        if (Test-Path $idxFile) { Remove-Item $idxFile -Force }
    }

    Context "Get-IdentityDescriptorIndexPath" {

        It "returns the cache-relative clixml path when the cache directory is set" {
            $expected = Join-Path -Path $script:TestCacheDir -ChildPath 'Cache\IdentityDescriptorIndex.clixml'
            Get-IdentityDescriptorIndexPath | Should -Be $expected
        }

        It "returns null when the cache directory is not set" {
            $ENV:AZDODSC_CACHE_DIRECTORY = $null
            Get-IdentityDescriptorIndexPath | Should -BeNullOrEmpty
        }
    }

    Context "Add-IdentityDescriptorIndexItem / Get-IdentityDescriptorIndexItem (in memory)" {

        It "stores an entry retrievable by its ACL descriptor" {
            Add-Sample -Descriptor 'aclDesc-1'
            (Get-IdentityDescriptorIndex).Count | Should -Be 1
        }

        It "synthesises a CacheItem in the shape callers expect" {
            Add-Sample -Descriptor 'aclDesc-1'
            $hit = Get-IdentityDescriptorIndexItem -AclDescriptor 'aclDesc-1'

            $hit                              | Should -Not -BeNullOrEmpty
            $hit                              | Should -BeOfType ([CacheItem])
            $hit.Key                          | Should -Be '[org]\Group A'
            $hit.Value.principalName          | Should -Be '[org]\Group A'
            $hit.Value.originId               | Should -Be 'origin-1'
            $hit.Value.descriptor             | Should -Be 'graph-1'
            $hit.Value.ACLIdentity.id         | Should -Be 'aclid-1'
            $hit.Value.ACLIdentity.descriptor | Should -Be 'aclDesc-1'
            $hit.Value.ACLIdentity.subjectDescriptor | Should -Be 'subject-1'
        }

        It "returns null for an unknown descriptor" {
            Add-Sample -Descriptor 'aclDesc-1'
            Get-IdentityDescriptorIndexItem -AclDescriptor 'does-not-exist' | Should -BeNullOrEmpty
        }

        It "is a no-op when the ACL descriptor is empty" {
            Add-IdentityDescriptorIndexItem -AclDescriptor '' -PrincipalName 'X'
            (Get-IdentityDescriptorIndex).Count | Should -Be 0
        }

        It "overwrites an existing entry for the same descriptor" {
            Add-Sample -Descriptor 'aclDesc-1'
            Add-IdentityDescriptorIndexItem -AclDescriptor 'aclDesc-1' -PrincipalName 'Group B' -OriginId 'origin-2'
            (Get-IdentityDescriptorIndex).Count | Should -Be 1
            (Get-IdentityDescriptorIndexItem -AclDescriptor 'aclDesc-1').Value.principalName | Should -Be 'Group B'
        }
    }

    Context "persistence round-trip (survives a fresh runspace)" {

        It "writes the index file when -Persist is supplied" {
            Add-Sample -Descriptor 'aclDesc-1' -Persist
            Test-Path (Get-IdentityDescriptorIndexPath) | Should -BeTrue
        }

        It "rehydrates a persisted entry after the in-memory global is dropped" {
            Add-Sample -Descriptor 'aclDesc-1' -Persist

            # Simulate a fresh DSC runspace: discard the in-memory global so the read must hit disk.
            Remove-Variable -Name AzDoIdentityDescriptorIndex -Scope Global -ErrorAction SilentlyContinue

            $hit = Get-IdentityDescriptorIndexItem -AclDescriptor 'aclDesc-1'
            $hit                     | Should -Not -BeNullOrEmpty
            $hit.Value.principalName | Should -Be '[org]\Group A'
        }

        It "does not persist without -Persist" {
            Add-Sample -Descriptor 'aclDesc-1'
            Test-Path (Get-IdentityDescriptorIndexPath) | Should -BeFalse
        }
    }

    Context "Save-IdentityDescriptorIndex" {

        It "persists the current in-memory index to disk" {
            Add-Sample -Descriptor 'aclDesc-1'
            Save-IdentityDescriptorIndex

            Remove-Variable -Name AzDoIdentityDescriptorIndex -Scope Global -ErrorAction SilentlyContinue
            (Get-IdentityDescriptorIndex).ContainsKey('aclDesc-1') | Should -BeTrue
        }

        It "is a silent no-op when the cache directory is not set" {
            $ENV:AZDODSC_CACHE_DIRECTORY = $null
            Remove-Variable -Name AzDoIdentityDescriptorIndex -Scope Global -ErrorAction SilentlyContinue
            { Save-IdentityDescriptorIndex } | Should -Not -Throw
        }
    }

    Context "Clear-IdentityDescriptorIndex" {

        It "empties the in-memory index and removes the persisted file" {
            Add-Sample -Descriptor 'aclDesc-1' -Persist
            Test-Path (Get-IdentityDescriptorIndexPath) | Should -BeTrue

            Clear-IdentityDescriptorIndex

            (Get-IdentityDescriptorIndex).Count          | Should -Be 0
            Test-Path (Get-IdentityDescriptorIndexPath)  | Should -BeFalse
        }
    }

    Context "Get-IdentityDescriptorIndex (no cache directory)" {

        It "returns an empty hashtable rather than throwing" {
            $ENV:AZDODSC_CACHE_DIRECTORY = $null
            Remove-Variable -Name AzDoIdentityDescriptorIndex -Scope Global -ErrorAction SilentlyContinue
            $idx = Get-IdentityDescriptorIndex
            $idx          | Should -BeOfType ([hashtable])
            $idx.Count    | Should -Be 0
        }
    }
}
