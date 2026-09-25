$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoReleaseDefinitionPermission" -Tag "Unit", "ReleaseDefinition", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoReleaseDefinitionPermission.tests.ps1'
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
        Mock -CommandName Get-CacheItem -MockWith {
            param($Key, $Type)
            if ($Type -eq 'SecurityNamespaces') { return @{ namespaceId = 'release-ns'; name = 'ReleaseManagement' } }
            return $null
        }
        Mock -CommandName Add-CacheItem
        Mock -CommandName ConvertTo-ACL -MockWith { return @(@{ token = @{ _token = 'ref' } }) }
        Mock -CommandName Test-ACLListforChanges -MockWith { return @{ status = 'Unchanged'; propertiesChanged = @(); reason = $null } }
    }

    Context "when the definition exists at the release root" {

        BeforeEach {
            Mock -CommandName Find-DevOpsReleaseDefinition -MockWith { return @{ id = 123; path = '\' } }
            Mock -CommandName Get-DevOpsACL -MockWith { return @(@{ token = ('{0}/123' -f $script:projectId) }) }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(@{ Token = @{ Type = 'ReleaseDefinition'; ProjectId = $script:projectId; DefinitionId = '123' } })
            }
        }

        It "builds the root form of the definition token" {
            $result = Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true
            $result.aclToken | Should -Be "$script:projectId/123"
        }

        It "passes the marked definition tokenName to ConvertTo-ACL" {
            Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true

            Assert-MockCalled -CommandName ConvertTo-ACL -Exactly -Times 1 -ParameterFilter {
                $TokenName -eq 'TestProject/@MyRelease'
            }
        }

        It "caches the resolved definition for New-ACLToken to reuse" {
            Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true

            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\MyRelease' -and $Type -eq 'LiveReleaseDefinitions'
            }
        }
    }

    Context "when the definition lives in a folder" {

        BeforeEach {
            Mock -CommandName Find-DevOpsReleaseDefinition -MockWith { return @{ id = 456; path = '\Platform' } }
            Mock -CommandName Get-DevOpsACL -MockWith { return @(@{ token = ('{0}/Platform/456' -f $script:projectId) }) }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @(@{ Token = @{ Type = 'ReleaseDefinition'; ProjectId = $script:projectId; DefinitionId = '456' } })
            }
        }

        It "builds the folder-aware form of the definition token" {
            $result = Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -FolderPath '\Platform' -isInherited $true
            $result.aclToken | Should -Be "$script:projectId/Platform/456"
        }

        It "marks the folder segment in the resource-side tokenName" {
            Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -FolderPath '\Platform' -isInherited $true

            Assert-MockCalled -CommandName ConvertTo-ACL -Exactly -Times 1 -ParameterFilter {
                $TokenName -eq 'TestProject/\Platform\@MyRelease'
            }
        }
    }

    Context "when the definition does not exist" {

        BeforeEach {
            Mock -CommandName Find-DevOpsReleaseDefinition -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'Missing' -isInherited $true
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the definition is already cached" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'SecurityNamespaces') { return @{ namespaceId = 'release-ns'; name = 'ReleaseManagement' } }
                if ($Type -eq 'LiveReleaseDefinitions') { return @{ id = 789; path = '\' } }
                return $null
            }
            Mock -CommandName Find-DevOpsReleaseDefinition
            Mock -CommandName Get-DevOpsACL -MockWith { return @() }
            Mock -CommandName ConvertTo-FormattedACL -MockWith { return @() }
        }

        It "does not call the live search endpoint again" {
            Get-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true
            Assert-MockCalled -CommandName Find-DevOpsReleaseDefinition -Exactly -Times 0
        }
    }
}
