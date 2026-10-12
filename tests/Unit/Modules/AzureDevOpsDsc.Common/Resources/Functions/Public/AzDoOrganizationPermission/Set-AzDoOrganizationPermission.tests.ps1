$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoOrganizationPermission' -Tag "Unit", "OrganizationPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoOrganizationPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'mock-ns-id' } }
        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return @{ Count = 1; value = @('serialized') } }
        Mock -CommandName Merge-AzDoUnmanagedACE -MockWith { return @{ Count = 1; value = @('merged') } }
        Mock -CommandName Set-AzDoPermission

        $lookup = @{
            aclToken          = 'NAMESPACE:'
            propertiesChanged = @('desired')
            LiveACLs          = @( @{ token = 'NAMESPACE:' } )
        }
    }

    It 'serializes the desired ACL against the resolved token' {
        Set-AzDoOrganizationPermission -GroupName 'G' -LookupResult $lookup
        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Times 1 -ParameterFilter {
            $DescriptorMatchToken -eq '^NAMESPACE:$' -and $ReferenceACLs -contains 'desired'
        }
    }

    It 'carries the unmanaged live ACEs into the body it posts' {
        Set-AzDoOrganizationPermission -GroupName 'G' -LookupResult $lookup
        Assert-MockCalled -CommandName Merge-AzDoUnmanagedACE -Times 1 -ParameterFilter {
            $LiveACLs[0].token -eq 'NAMESPACE:'
        }
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 1 -ParameterFilter {
            $SerializedACLs.value -contains 'merged' -and $SecurityNamespaceID -eq 'mock-ns-id'
        }
    }

    It 'throws, and writes nothing, when Get resolved no token' {
        { Set-AzDoOrganizationPermission -GroupName 'G' -LookupResult @{ reason = 'no root' } } |
            Should -Throw '*no root*'
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 0
    }

    It 'throws, and writes nothing, when the namespace is missing' {
        Mock -CommandName Get-CacheItem -MockWith { return $null }
        { Set-AzDoOrganizationPermission -GroupName 'G' -LookupResult $lookup } | Should -Throw
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 0
    }
}
