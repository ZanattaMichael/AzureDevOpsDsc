$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoReleaseFolderPermission" -Tag "Unit", "ReleaseFolder", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoReleaseFolderPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        $script:projectId = 'proj-id-1'

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = $script:projectId } }
        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'release-ns'; name = 'ReleaseManagement' } }
        # Get-DevOpsACL returns the API's RAW ACL objects: token is a plain wire-format string,
        # and the parsed .Token shape only exists after ConvertTo-FormattedACL. Get- filters on the
        # raw token before formatting - formatting resolves every ACE through Find-Identity - so the
        # fixture carries real tokens, with a decoy for another object to exercise that filter.
        Mock -CommandName Get-DevOpsACL -MockWith {
            return @(
                @{ token = $script:projectId }
                @{ token = ('{0}/Platform' -f $script:projectId) }
                @{ token = ('{0}/123' -f $script:projectId) }
            )
        }
        Mock -CommandName ConvertTo-ACL -MockWith { return @(@{ token = @{ _token = 'ref' } }) }
        Mock -CommandName Test-ACLListforChanges -MockWith { return @{ status = 'Unchanged'; propertiesChanged = @(); reason = $null } }
    }

    Context "when the folder exists" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'ReleaseFolder'; ProjectId = $script:projectId; FolderPath = 'Platform' } },
                    @{ Token = @{ Type = 'ReleaseDefinition'; ProjectId = $script:projectId; DefinitionId = '123' } }
                )
            }
        }

        It "builds the folder form of the ReleaseManagement token" {
            $result = Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -FolderPath '\Platform' -isInherited $true
            $result.aclToken | Should -Be "$script:projectId/Platform"
        }

        It "compares against the folder's ACL, not a definition's" {
            Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -FolderPath '\Platform' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and $DifferenceACLs[0].Token.Type -eq 'ReleaseFolder'
            }
        }

        It "formats only this object's ACL, not every ACL in the namespace" {
            Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -FolderPath '\Platform' -isInherited $true
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Exactly -Times 1 -Scope It
        }

        It "passes the marked path to ConvertTo-ACL so a folder is not read as a definition" {
            Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -FolderPath 'Platform' -isInherited $true

            Assert-MockCalled -CommandName ConvertTo-ACL -Exactly -Times 1 -ParameterFilter {
                $TokenName -eq 'TestProject/\Platform'
            }
        }
    }

    Context "when no folder path is given" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @() }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'ReleaseRoot'; ProjectId = $script:projectId } },
                    @{ Token = @{ Type = 'ReleaseDefinition'; ProjectId = $script:projectId; DefinitionId = '123' } },
                    @{ Token = @{ Type = 'ReleaseFolder'; ProjectId = $script:projectId; FolderPath = 'Platform' } }
                )
            }
        }

        It "targets the project release root" {
            $result = Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -isInherited $true
            $result.aclToken | Should -Be $script:projectId
        }

        It "compares against only the root ACL" {
            Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and $DifferenceACLs[0].Token.Type -eq 'ReleaseRoot'
            }
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @() }
            Mock -CommandName ConvertTo-FormattedACL -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoReleaseFolderPermission -ProjectName 'TestProject' -FolderPath '\Missing' -isInherited $true
            $result.status | Should -Be 'NotFound'
        }
    }
}
