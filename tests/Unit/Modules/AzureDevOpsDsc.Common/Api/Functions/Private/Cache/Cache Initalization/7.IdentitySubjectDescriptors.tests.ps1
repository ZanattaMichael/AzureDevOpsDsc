$currentFile = $MyInvocation.MyCommand.Path

Describe "AzDoAPI_7_IdentitySubjectDescriptors" -Tag "Unit", "Cache Initalization", "Cache" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath '7.IdentitySubjectDescriptors.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoCacheObjects -MockWith {
            @('LiveGroups', 'LiveUsers', 'LiveServicePrinciples')
        }

        Mock -CommandName Get-CacheObject -MockWith {

            switch ($CacheType)
            {
                'LiveGroups' {
                    return (
                        [PSCustomObject]@{
                            Key = 'mockKey'
                            Value = @{
                                descriptor = 'mockDescriptorGroup'
                            }
                        }
                    )
                }
                'LiveUsers' {
                    return (
                        [PSCustomObject]@{
                            Key = 'mockKey'
                            Value = @{
                                descriptor = 'mockDescriptorUser'
                            }
                        }
                    )
                }
                'LiveServicePrinciples' {
                    return (
                        [PSCustomObject]@{
                            Key = 'mockKey'
                            Value = @{
                                descriptor = 'mockDescriptorServicePrinciple'
                            }
                        }
                    )
                 }
            }
        }

        # The initializer resolves every descriptor in one batched pass, so what it calls is
        # the batch function and what it gets back is a descriptor-keyed lookup.
        Mock -CommandName Get-DevOpsDescriptorIdentityBatch -MockWith {
            $lookup = @{}

            foreach ($descriptor in $SubjectDescriptor)
            {
                $lookup[$descriptor] = @{
                    id = 'mockId'
                    descriptor = 'mockDescriptor'
                    subjectDescriptor = 'mockSubjectDescriptor'
                    providerDisplayName = 'mockProvider'
                    isActive = $true
                    isContainer = $false
                }
            }

            return $lookup
        }

        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject

        # Descriptor index helpers invoked during the rebuild; no-op them in unit scope.
        Mock -CommandName Clear-IdentityDescriptorIndex
        Mock -CommandName Add-IdentityDescriptorIndexItem
        Mock -CommandName Save-IdentityDescriptorIndex

    }

    BeforeEach {
        $Global:DSCAZDO_OrganizationName = 'mockOrg'
    }

    It "should use a global variable if OrganizationName parameter is not provided" {


        $result = AzDoAPI_7_IdentitySubjectDescriptors

        Assert-MockCalled -CommandName Get-CacheObject
        Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentityBatch
        Assert-MockCalled -CommandName Add-CacheItem -Times 0 -Exactly
        Assert-MockCalled -CommandName Export-CacheObject
    }

    It "should use OrganizationName parameter if provided" {
        $result = AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg'

        Assert-MockCalled -CommandName Get-CacheObject
        Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentityBatch
        Assert-MockCalled -CommandName Add-CacheItem -Times 0 -Exactly
        Assert-MockCalled -CommandName Export-CacheObject
    }

    It "should call Get-CacheObject for each cache type" {
        $result = AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg'
        Assert-MockCalled -CommandName Get-CacheObject -Times 3
    }

    It "should resolve every descriptor in a single batched request" {
        $result = AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg'

        # The point of batching: one call covering all three caches, not one call per identity.
        Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentityBatch -Exactly -Times 1 -ParameterFilter {
            ($SubjectDescriptor -contains 'mockDescriptorGroup') -and
            ($SubjectDescriptor -contains 'mockDescriptorUser') -and
            ($SubjectDescriptor -contains 'mockDescriptorServicePrinciple')
        }
    }

    It "should leave an empty identity for a descriptor the API did not answer for" {
        Mock -CommandName Get-DevOpsDescriptorIdentityBatch -MockWith { @{} }

        # An unresolved descriptor must not abort the refresh - Find-Identity backfills it
        # lazily on first use, so the cache is still written.
        { AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg' } | Should -Not -Throw

        Assert-MockCalled -CommandName Add-CacheItem -Times 0 -Exactly
        Assert-MockCalled -CommandName Export-CacheObject
    }

    It "should stamp ACLIdentity onto the cached item in place, without re-adding it" {

        # Get-CacheObject returns the live list, so the item the initializer enumerates is the
        # cached item itself. Re-adding it used to store the whole item as the value of a new one,
        # which left .value.ACLIdentity $null for every identity.
        $script:liveGroup = [PSCustomObject]@{
            Key = 'mockKey'
            Value = [PSCustomObject]@{
                descriptor = 'mockDescriptorGroup'
            }
        }

        Mock -CommandName Get-CacheObject -ParameterFilter { $CacheType -eq 'LiveGroups' } -MockWith {
            return ,@($script:liveGroup)
        }

        $result = AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg'

        Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentityBatch -ParameterFilter {
            $SubjectDescriptor -contains 'mockDescriptorGroup'
        }

        Assert-MockCalled -CommandName Add-CacheItem -Times 0 -Exactly

        $script:liveGroup.Value.ACLIdentity | Should -Not -BeNullOrEmpty
        $script:liveGroup.Value.ACLIdentity.id | Should -Be 'mockId'
        $script:liveGroup.Value.ACLIdentity.descriptor | Should -Be 'mockDescriptor'
        $script:liveGroup.Value.descriptor | Should -Be 'mockDescriptorGroup'

        Assert-MockCalled -CommandName Export-CacheObject -ParameterFilter {
            $CacheType -eq 'LiveGroups' -and @($Content)[0].Value.ACLIdentity.id -eq 'mockId'
        }

    }
}
