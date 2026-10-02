$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipelineFolderPermission" -Tag "Unit", "PipelineFolder", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineFolderPermission.tests.ps1'
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
        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'build-ns'; name = 'Build' } }
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
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'BuildFolder'; ProjectId = $script:projectId; FolderPath = 'Platform' } },
                    @{ Token = @{ Type = 'Build'; ProjectId = $script:projectId; PipelineId = '123' } }
                )
            }
        }

        It "builds the folder form of the Build token, without the path marker" {
            $result = Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -FolderPath '\Platform' -isInherited $true
            $result.aclToken | Should -Be "$script:projectId/Platform"
        }

        It "compares against the folder's ACL, not a definition's" {
            Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -FolderPath '\Platform' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and $DifferenceACLs[0].Token.Type -eq 'BuildFolder'
            }
        }

        It "formats only this object's ACL, not every ACL in the namespace" {
            # ConvertTo-FormattedACL resolves every ACE through Find-Identity, an API round trip per
            # uncached descriptor, so it is bound once per surviving raw ACL - one, not three.
            Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -FolderPath '\Platform' -isInherited $true
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Exactly -Times 1 -Scope It
        }

        It "passes the marked path to ConvertTo-ACL so a folder is not read as a pipeline" {
            Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -FolderPath 'Platform' -isInherited $true

            Assert-MockCalled -CommandName ConvertTo-ACL -Exactly -Times 1 -ParameterFilter {
                $TokenName -eq 'TestProject/\Platform'
            }
        }
    }

    Context "when no folder path is given" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @() }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(
                    @{ Token = @{ Type = 'Build'; ProjectId = $script:projectId } },
                    @{ Token = @{ Type = 'Build'; ProjectId = $script:projectId; PipelineId = '123' } },
                    @{ Token = @{ Type = 'BuildFolder'; ProjectId = $script:projectId; FolderPath = 'Platform' } }
                )
            }
        }

        It "targets the project build root" {
            $result = Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -isInherited $true
            $result.aclToken | Should -Be $script:projectId
        }

        It "compares against only the root ACL" {
            Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -isInherited $true

            Assert-MockCalled -CommandName Test-ACLListforChanges -Exactly -Times 1 -ParameterFilter {
                $DifferenceACLs.Count -eq 1 -and (-not $DifferenceACLs[0].Token.PipelineId)
            }
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @() }
            Mock -CommandName ConvertTo-FormattedACL -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoPipelineFolderPermission -ProjectName 'TestProject' -FolderPath '\Missing' -isInherited $true
            $result.status | Should -Be 'NotFound'
        }
    }
}
