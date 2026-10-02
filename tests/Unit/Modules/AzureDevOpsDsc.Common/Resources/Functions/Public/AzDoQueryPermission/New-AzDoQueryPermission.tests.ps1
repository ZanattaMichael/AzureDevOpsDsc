$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoQueryPermission" -Tag "Unit", "WorkItemQuery", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoQueryPermission.tests.ps1'
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
        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return @{ serialized = $true } }
        Mock -CommandName Set-AzDoPermission
        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'ns-id-001'; name = 'WorkItemQueryFolders' } }
    }

    Context "when a folder ACL token was resolved" {

        It "writes the permissions" {
            $lookup = @{ aclToken = $script:token; propertiesChanged = @(); DifferenceACLs = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1
        }

        It "addresses the ACL to the token Get resolved, rather than recomputing it" {
            $lookup = @{ aclToken = $script:token; propertiesChanged = @(); DifferenceACLs = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly -Times 1 -ParameterFilter {
                $DescriptorMatchToken -eq $script:token
            }
        }

        It "does not merge in the namespace-wide ACL cache" {
            # Merging it would grow the request body with every other folder's ACL.
            $lookup = @{ aclToken = $script:token; propertiesChanged = @(); DifferenceACLs = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly -Times 1 -ParameterFilter {
                $DescriptorACLList.Count -eq 0
            }
        }

        It "does not clear ACEs for a folder, since it inherits from its parent" {
            $lookup = @{ aclToken = $script:token; propertiesChanged = @(); DifferenceACLs = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('ClearACEs')
            }
        }

        It "invalidates the ACL cache so the next Get re-reads from the API" {
            $lookup = @{ aclToken = $script:token; propertiesChanged = @(); DifferenceACLs = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1
        }
    }

    Context "when targeting the project query root" {

        It "clears ACEs, because the root has no parent to inherit from" {
            $lookup = @{ aclToken = "`$/$script:projectId"; propertiesChanged = @(); DifferenceACLs = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -ParameterFilter {
                $ClearACEs -eq $true
            }
        }
    }

    Context "when no ACL token was resolved" {

        It "makes no change and reports why" {
            $lookup = @{ aclToken = $null; propertiesChanged = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the security namespace is missing" {

        It "makes no change" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            $lookup = @{ aclToken = $script:token; propertiesChanged = @() }
            New-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true -LookupResult $lookup
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 0
        }
    }
}
