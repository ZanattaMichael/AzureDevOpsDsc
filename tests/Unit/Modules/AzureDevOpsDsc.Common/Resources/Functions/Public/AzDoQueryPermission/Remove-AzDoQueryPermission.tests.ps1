$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoQueryPermission" -Tag "Unit", "WorkItemQuery", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoQueryPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName

        $script:projectId = '11111111-1111-1111-1111-111111111111'
        $script:folderId  = '22222222-2222-2222-2222-222222222222'
        $script:token     = "`$/$script:projectId/$script:folderId"

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = $script:projectId } }
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Remove-AzDoPermission
    }

    Context "when an ACL exists for the folder" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith {
                return @{ namespaceId = 'ns-id-001'; name = 'WorkItemQueryFolders' }
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveACLList' } -MockWith {
                return @(@{ token = $script:token }, @{ token = "`$/$script:projectId/99999999-9999-9999-9999-999999999999" })
            }
        }

        It "removes it" {
            $lookup = @{ aclToken = $script:token }
            Remove-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 1
        }

        It "removes only this folder's token" {
            $lookup = @{ aclToken = $script:token }
            Remove-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $TokenName -eq $script:token
            }
        }

        It "invalidates the ACL cache" {
            $lookup = @{ aclToken = $script:token }
            Remove-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1
        }
    }

    Context "when no ACL exists for the folder" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith {
                return @{ namespaceId = 'ns-id-001' }
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveACLList' } -MockWith {
                return @(@{ token = "`$/$script:projectId/99999999-9999-9999-9999-999999999999" })
            }
        }

        It "is a no-op rather than an error" {
            $lookup = @{ aclToken = $script:token }
            Remove-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }

    Context "when targeting the project query root" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'ns-id-001' } }
        }

        It "refuses, because the root has no parent to inherit from" {
            $lookup = @{ aclToken = "`$/$script:projectId" }
            Remove-AzDoQueryPermission -ProjectName 'TestProject' -isInherited $true -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Warning -Times 2
        }
    }
}
