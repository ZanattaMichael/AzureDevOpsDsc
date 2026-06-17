$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoAreaPermission Tests' -Tag "Unit", "AreaPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoAreaPermission.tests.ps1'
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
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Function Mock-Get-CacheItem {
            param($Key, $Type)
            if ($Type -eq 'SecurityNamespaces') { return @{ namespaceId = 'MockNamespaceId' } }
            if ($Type -eq 'LiveProjects') { return @{ projectId = 'MockProjectId' } }
            if ($Type -eq 'LiveACLList') { return @() }
            return $null
        }

        Mock -CommandName ConvertTo-ACLHashtable {
            param($ReferenceACLs, $DescriptorACLList, $DescriptorMatchToken)
            return @{ SerializedACLs = 'MockSerializedACLs' }
        }

        # Mock external functions used within Get-AzDoAreaPermission
        Mock -CommandName Get-CacheItem -MockWith {
            Mock-Get-CacheItem -Key $Key -Type $Type
        }

        Mock -CommandName Write-Warning
        Mock -CommandName Set-AzDoPermission
        Mock -CommandName Remove-CacheItem

    }

    Context "When Ensure is Present" {

        It "Should proceed and call Set-AzDoPermission when AreaPath is not specified (top-level project area)" {
            # Act
            New-AzDoAreaPermission -ProjectName "TestProject" -isInherited $true -LookupResult @{
                identifiers       = @('guid-1')
                propertiesChanged = @()
            }

            # Assert — function proceeds past the namespace/project lookup
            Assert-MockCalled -CommandName Get-CacheItem -Times 3
            Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
        }

        It "Should return warning when Security Namespace or Project is not found" {
            # Arrange
            Mock -CommandName Get-CacheItem {
                return $null
            }

            # Act
            $result = New-AzDoAreaPermission -ProjectName "NonExistentProject" -AreaPath "TestAreaPath" -isInherited $false

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It "Should set permissions correctly with valid parameters" {
            # Arrange
            Mock -CommandName Get-CacheItem {
                param($Key, $Type)
                if ($Type -eq 'SecurityNamespaces') { return @{ namespaceId = 'MockNamespaceId' } }
                if ($Type -eq 'LiveProjects') { return @{ projectId = 'MockProjectId' } }
                if ($Type -eq 'LiveACLList') { return @{ mock = $true } }
                return $null
            }

            # Act
            $result = New-AzDoAreaPermission -ProjectName "TestProject" -AreaPath "ValidAreaPath" -isInherited $true -LookupResult @{
                identifiers       = @('12345', '67890')
                propertiesChanged = @()
            }

            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
        }
    }
}
