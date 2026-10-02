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
        Assert-MockCalled -CommandName Add-CacheItem
        Assert-MockCalled -CommandName Export-CacheObject
    }

    It "should use OrganizationName parameter if provided" {
        $result = AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg'

        Assert-MockCalled -CommandName Get-CacheObject
        Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentityBatch
        Assert-MockCalled -CommandName Add-CacheItem
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

        Assert-MockCalled -CommandName Add-CacheItem
        Assert-MockCalled -CommandName Export-CacheObject
    }

    It "should add members to each cache object" {

        $mockGroup = @{
            Key = 'mockKey'
            Value = [PSCustomObject]@{
                descriptor = 'mockDescriptorGroup'
            }
        }

        $result = AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName 'testOrg'

        Assert-MockCalled -CommandName Get-DevOpsDescriptorIdentityBatch -ParameterFilter {
            $SubjectDescriptor -contains 'mockDescriptorGroup'
        }

        $cacheItemArgs = @{
            Key = 'mockKey'
            Value = $mockGroup
            Type = 'LiveGroups'
            SuppressWarning = $true
        }

        Assert-MockCalled -CommandName Add-CacheItem -Times 1 -ParameterFilter {
            $Key -eq $cacheItemArgs.Key -and
            $Type -eq $cacheItemArgs.Type -and
            $SuppressWarning -eq $cacheItemArgs.SuppressWarning
        }

    }
}
