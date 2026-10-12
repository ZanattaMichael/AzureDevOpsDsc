$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoOrganizationPermission' -Tag "Unit", "OrganizationPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoOrganizationPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'mock-ns-id' } }
        Mock -CommandName Clear-AzDoACE
        Mock -CommandName Remove-AzDoPermission

        $managedAce = @{ Identity = @{ value = @{ ACLIdentity = @{ descriptor = 'desc-managed' } } } }
        $lookup = @{
            aclToken      = 'NAMESPACE:'
            ReferenceACLs = @( @{ aces = @($managedAce) } )
        }
    }

    It 'clears only the managed identities on the root token' {
        Remove-AzDoOrganizationPermission -GroupName 'G' -LookupResult $lookup
        Assert-MockCalled -CommandName Clear-AzDoACE -Times 1 -ParameterFilter {
            $DifferenceACLs[0].token._token -eq 'NAMESPACE:' -and
            @($DifferenceACLs[0].aces).Count -eq 1 -and
            $DifferenceACLs[0].aces[0].Identity.value.ACLIdentity.descriptor -eq 'desc-managed'
        }
    }

    It 'never deletes the organization ACL' {
        Remove-AzDoOrganizationPermission -GroupName 'G' -LookupResult $lookup
        Assert-MockCalled -CommandName Remove-AzDoPermission -Times 0
    }

    It 'does nothing when no managed identity resolved' {
        Remove-AzDoOrganizationPermission -GroupName 'G' -LookupResult @{ aclToken = 'NAMESPACE:'; ReferenceACLs = @( @{ aces = @() } ) }
        Assert-MockCalled -CommandName Clear-AzDoACE -Times 0
    }

    It 'throws, and clears nothing, when Get resolved no token' {
        { Remove-AzDoOrganizationPermission -GroupName 'G' -LookupResult @{ reason = 'no root' } } | Should -Throw '*no root*'
        Assert-MockCalled -CommandName Clear-AzDoACE -Times 0
    }
}
