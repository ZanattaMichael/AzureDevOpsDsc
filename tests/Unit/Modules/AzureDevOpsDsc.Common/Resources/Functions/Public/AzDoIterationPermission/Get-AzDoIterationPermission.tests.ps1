$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoIterationPermission Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoIterationPermission.tests.ps1'
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
                'LiveIterations' {
                    return @{ identifier = "MockIdentifier"; name = $Key }
                }
                default { return $null }
            }
        }


        # Mock external functions used within Get-AzDoIterationPermission
        Mock -CommandName Get-CacheItem -MockWith {
            Mock-Get-CacheItem -Key $Key -Type $Type
        }

        Mock -CommandName Format-AzDoIterationPath {
            return @("FormattedPath")
        }

        Mock -CommandName Get-AllAzDoClassificationNodePaths {
            return @( "PrimaryIterationPath", "SecondaryIterationPath" )
        }

        Mock -CommandName Get-DevOpsACL {
            return @(
                @{ Token = @{ Type = 'IterationPathPermission'; Identifiers = @('MockIdentifier') } }
            )
        }

        Mock -CommandName ConvertTo-FormattedACL {
            param($SecurityNamespace, $OrganizationName)
            return @(
                @{ Token = @{ Type = 'IterationPathPermission'; Identifiers = @(
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
            $result = Get-AzDoIterationPermission -ProjectName "NonExistentProject" -isInherited $false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be ([DSCGetSummaryState]::Error)
            $result.reason | Should -Be "Project not found: NonExistentProject"
        }

        It "Should return correct results when Iteration path is specified" {
            # Arrange

            <#
            Mock -CommandName Get-CacheItem {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ identifier = 'MockProjectIdentifier' } }
                if ($Type -eq 'LiveIterationNodes') { return @{ identifier = 'MockIdentifier' } }
            }
            #>

            # Act
            $result = Get-AzDoIterationPermission -ProjectName "TestProject" -IterationPath "PrimaryIterationPath\SecondaryIterationPath" -isInherited $true

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "Unchanged"
            $result.identifiers | Should -Contain 'MockIdentifier'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It "Should handle missing Iteration paths correctly" {
            # Act
            $result = Get-AzDoIterationPermission -ProjectName "TestProject" -isInherited $false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IterationPath | Should -BeNullOrEmpty
        }
    }

}
