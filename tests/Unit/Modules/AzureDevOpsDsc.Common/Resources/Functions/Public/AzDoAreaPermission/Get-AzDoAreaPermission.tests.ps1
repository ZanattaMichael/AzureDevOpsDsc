$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoAreaPermission Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoAreaPermission.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Function Mock-Get-CacheItem {
            param (
                [string]$Key,
                [string]$Type
            )
            switch ($Type, $Key) {
                'LiveRepositories' {
                    return @{ id = 123; Name = "TestRepository" }
                }
                'SecurityNamespaces' {
                    return @{ namespaceId = "TestNamespaceId" }
                }
                'LiveProjects' {
                    return @{ id = 123; Name = "TestProject" }
                }
                'LiveAreaNodes' {
                    return @{ identifier = "MockIdentifier"; name = $Key }
                }
                default { return $null }
            }
        }


        # Mock external functions used within Get-AzDoAreaPermission
        Mock -CommandName Get-CacheItem -MockWith {
            Mock-Get-CacheItem -Key $Key -Type $Type
        }

        Mock -CommandName Format-AzDoAreaPath {
            return @("FormattedPath")
        }

        Mock -CommandName Get-AllAzDoClassificationNodePaths {
            return @( "PrimaryAreaPath", "SecondaryAreaPath" )
        }

        Mock -CommandName Get-DevOpsACL {
            return @(
                @{ Token = @{ Type = 'AreaPathPermission'; Identifiers = @('MockIdentifier') } }
            )
        }

        Mock -CommandName ConvertTo-FormattedACL {
            param($SecurityNamespace, $OrganizationName)
            return @(
                @{ Token = @{ Type = 'AreaPathPermission'; Identifiers = @(
                    @{ identifier = 'MockIdentifier'},
                    @{ identifier = 'MockIdentifier'}
                )}}
            )
        }

        Mock -CommandName ConvertTo-ACL {
            param($Permissions, $SecurityNamespace, $isInherited, $OrganizationName, $TokenName)
            return @{ ReferenceACLs = 'MockReferenceACL' }
        }

        Mock -CommandName Test-ACLListforChanges {
            param($ReferenceACLs, $DifferenceACLs)
            return @{
                propertiesChanged = @()
                status = 'Unchanged'
                reason = 'No changes detected'
            }
        }

        Mock -CommandName Write-Warning

    }

    Context "When Ensure is Present" {

        It "Should return error when project is not found" {
            # Arrange
            Mock -CommandName Get-CacheItem {
                return $null
            }

            # Act
            $result = Get-AzDoAreaPermission -ProjectName "NonExistentProject" -isInherited $false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be ([DSCGetSummaryState]::Error)
            $result.reason | Should -Be "Project not found: NonExistentProject"
        }

        It "Should return correct results when area path is specified" {
            # Arrange

            <#
            Mock -CommandName Get-CacheItem {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ identifier = 'MockProjectIdentifier' } }
                if ($Type -eq 'LiveAreaNodes') { return @{ identifier = 'MockIdentifier' } }
            }
            #>

            # Act
            $result = Get-AzDoAreaPermission -ProjectName "TestProject" -AreaPath "PrimaryAreaPath\SecondaryAreaPath" -isInherited $true

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "Unchanged"
            $result.identifiers | Should -Contain 'MockIdentifier'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It "Should handle missing area paths correctly" {
            # Act
            $result = Get-AzDoAreaPermission -ProjectName "TestProject" -isInherited $false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.areaPath | Should -BeNullOrEmpty
        }
    }

}
