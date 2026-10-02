$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoSecureFilePermission" -Tag "Unit", "SecureFile", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoSecureFilePermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName

        $script:projectId = 'proj-id-1'

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = $script:projectId } }
        Mock -CommandName Add-CacheItem
        # Get-DevOpsACL returns the API's RAW ACL objects: token is a plain wire-format string,
        # and the parsed .Token shape only exists after ConvertTo-FormattedACL. Get- filters on the
        # raw token before formatting - formatting resolves every ACE through Find-Identity - so the
        # fixture carries real tokens, with a decoy for another object to exercise that filter.
        Mock -CommandName Get-DevOpsACL -MockWith {
            return @(
                @{ token = ('Library/Project/{0}' -f $script:projectId) }
                @{ token = ('Library/Project/{0}/SecureFile/sf-id-1' -f $script:projectId) }
                @{ token = ('Library/Project/{0}/VariableGroup/1' -f $script:projectId) }
            )
        }
        Mock -CommandName ConvertTo-ACL -MockWith { return @(@{ token = @{ _token = 'ref' } }) }
        Mock -CommandName Test-ACLListforChanges -MockWith { return @{ status = 'Unchanged'; propertiesChanged = @(); reason = $null } }
    }

    Context "when the secure file exists" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith {
                return @{ namespaceId = 'lib-ns'; name = 'Library' }
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveSecureFiles' } -MockWith {
                return @{ id = 'sf-id-1'; name = 'signing.pfx' }
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'Library'; ProjectId = $script:projectId; SecureFileId = 'sf-id-1' } },
                    @{ Token = @{ Type = 'Library'; ProjectId = $script:projectId; VariableGroupId = 'vg-1' } }
                )
            }
        }

        It "builds the SecureFile form of the Library token" {
            $result = Get-AzDoSecureFilePermission -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -isInherited $true
            $result.aclToken | Should -Be "Library/Project/$script:projectId/SecureFile/sf-id-1"
        }

        It "compares against the secure file's ACL, not the variable group's" {
            # Both live in the Library namespace, so the filter has to distinguish them.
            Get-AzDoSecureFilePermission -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and $DifferenceACLs[0].Token.SecureFileId -eq 'sf-id-1'
            }
        }

        It "formats only this object's ACL, not every ACL in the namespace" {
            # ConvertTo-FormattedACL resolves every ACE through Find-Identity, an API round trip per
            # uncached descriptor, so it is bound once per surviving raw ACL - one, not three.
            Get-AzDoSecureFilePermission -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -isInherited $true
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Exactly -Times 1 -Scope It
        }
    }

    Context "when no secure file name is given" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith {
                return @{ namespaceId = 'lib-ns' }
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'Library'; ProjectId = $script:projectId } },
                    @{ Token = @{ Type = 'Library'; ProjectId = $script:projectId; SecureFileId = 'sf-id-1' } },
                    @{ Token = @{ Type = 'Library'; ProjectId = $script:projectId; VariableGroupId = 'vg-1' } }
                )
            }
        }

        It "targets the project Library root" {
            $result = Get-AzDoSecureFilePermission -ProjectName 'TestProject' -isInherited $true
            $result.aclToken | Should -Be "Library/Project/$script:projectId"
        }

        It "excludes both secure file and variable group ACLs from the root comparison" {
            Get-AzDoSecureFilePermission -ProjectName 'TestProject' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and
                (-not $DifferenceACLs[0].Token.SecureFileId) -and
                (-not $DifferenceACLs[0].Token.VariableGroupId)
            }
        }
    }

    Context "when the secure file does not exist" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsSecureFiles -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoSecureFilePermission -ProjectName 'TestProject' -SecureFileName 'missing.pfx' -isInherited $true
            $result.status | Should -Be 'NotFound'
        }
    }
}
