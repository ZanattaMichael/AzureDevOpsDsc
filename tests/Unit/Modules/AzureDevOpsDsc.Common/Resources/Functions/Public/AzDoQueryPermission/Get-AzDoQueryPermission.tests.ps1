$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoQueryPermission" -Tag "Unit", "WorkItemQuery", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoQueryPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        $script:projectId = '11111111-1111-1111-1111-111111111111'
        $script:folderId  = '22222222-2222-2222-2222-222222222222'

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = $script:projectId; name = 'TestProject' } }
        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'ns-id-001'; name = 'WorkItemQueryFolders' } }
        Mock -CommandName Get-DevOpsACL -MockWith { return @(@{ token = 'acl' }) }
        Mock -CommandName Test-ACLListforChanges -MockWith { return @{ status = 'Unchanged'; propertiesChanged = @(); reason = $null } }
        Mock -CommandName ConvertTo-ACL -MockWith { return @(@{ token = @{ _token = 'ref' } }) }
    }

    Context "when the query folder resolves" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoQueryPath -MockWith {
                return @{
                    Path     = 'Shared Queries/Platform'
                    Item     = @{ id = $script:folderId; isFolder = $true }
                    IdChain  = @($script:folderId)
                    Resolved = 2
                    Segments = @('Shared Queries', 'Platform')
                    Exists   = $true
                }
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'QueryPermission'; Identifiers = @(@{ identifier = $script:folderId }) } }
                )
            }
        }

        It "builds the ACL token from the project id and the folder id chain" {
            $result = Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true
            $result.aclToken | Should -Be "`$/$script:projectId/$script:folderId"
        }

        It "returns the resolved folder identifiers" {
            $result = Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true
            $result.identifiers | Should -Be @($script:folderId)
        }

        It "returns the status from the ACL comparison" {
            $result = Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true
            $result.status | Should -Be 'Unchanged'
        }

        It "passes the built token to ConvertTo-ACL so both sides compare the same folder" {
            Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true
            Assert-MockCalled -CommandName ConvertTo-ACL -Exactly -Times 1 -ParameterFilter {
                $TokenName -eq "`$/$script:projectId/$script:folderId" -and $SecurityNamespace -eq 'WorkItemQueryFolders'
            }
        }

        It "scopes the ACL fetch to the token rather than reading the whole namespace" {
            Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 1 -ParameterFilter {
                $Token -eq "`$/$script:projectId/$script:folderId"
            }
        }
    }

    Context "when no query path is given" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoQueryPath -MockWith { throw "should not be called" }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(@{ Token = @{ Type = 'QueryPermission'; Identifiers = @() } })
            }
        }

        It "targets the project query root" {
            $result = Get-AzDoQueryPermission -ProjectName 'TestProject' -isInherited $true
            $result.aclToken | Should -Be "`$/$script:projectId"
        }

        It "does not attempt to resolve a folder path" {
            Get-AzDoQueryPermission -ProjectName 'TestProject' -isInherited $true
            Assert-MockCalled -CommandName Resolve-AzDoQueryPath -Exactly -Times 0
        }
    }

    Context "when the query folder does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoQueryPath -MockWith {
                return @{
                    Path     = 'Shared Queries/Missing/Deep'
                    Item     = $null
                    IdChain  = @()
                    Resolved = 1
                    Segments = @('Shared Queries', 'Missing', 'Deep')
                    Exists   = $false
                }
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Missing/Deep' -isInherited $true
            $result.status | Should -Be 'NotFound'
        }

        It "names the segment where resolution stopped" {
            Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Missing/Deep' -isInherited $true
            Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                $Message -like "*Shared Queries/Missing*"
            }
        }
    }

    Context "when the path points at a query rather than a folder" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoQueryPath -MockWith {
                return @{
                    Path     = 'Shared Queries/Active Bugs'
                    Item     = @{ id = $script:folderId; isFolder = $false }
                    IdChain  = @($script:folderId)
                    Resolved = 2
                    Segments = @('Shared Queries', 'Active Bugs')
                    Exists   = $true
                }
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith { return @() }
        }

        It "returns status Error, because this namespace secures folders" {
            $result = Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Active Bugs' -isInherited $true
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'PathIsNotAFolder'
        }
    }

    Context "when the project cannot be resolved" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
        }

        It "returns status Error" {
            $result = Get-AzDoQueryPermission -ProjectName 'MissingProject' -QueryPath 'Shared Queries/Platform' -isInherited $true
            $result.status | Should -Be 'Error'
        }
    }

    Context "when ACLs exist for other folders in the namespace" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoQueryPath -MockWith {
                return @{
                    Path     = 'Shared Queries/Platform'
                    Item     = @{ id = $script:folderId; isFolder = $true }
                    IdChain  = @($script:folderId)
                    Resolved = 2
                    Segments = @('Shared Queries', 'Platform')
                    Exists   = $true
                }
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'QueryPermission'; Identifiers = @(@{ identifier = '33333333-3333-3333-3333-333333333333' }) } },
                    @{ Token = @{ Type = 'QueryPermission'; Identifiers = @(@{ identifier = $script:folderId }) } },
                    @{ Token = @{ Type = 'AreaPathPermission'; Identifiers = @(@{ identifier = $script:folderId }) } }
                )
            }
        }

        It "compares against only this folder's ACL" {
            Get-AzDoQueryPermission -ProjectName 'TestProject' -QueryPath 'Shared Queries/Platform' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and
                $DifferenceACLs[0].Token.Identifiers[0].identifier -eq $script:folderId
            }
        }
    }
}
