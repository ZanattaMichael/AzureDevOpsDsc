$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoAreaNodes Tests' -Tag "Unit", "AreaNodes" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoAreaNodes.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        # Mocking external functions used within Get-AzDoAreaNodes
        Mock -CommandName Format-AzDoAreaPath -MockWith {
            param (
                [string]$ProjectName,
                [string[]]$AreaPaths
            )
            return $AreaPaths | ForEach-Object { "\$ProjectName\$_" }
        }

        Mock -CommandName Get-AllAzDoClassificationNodePaths -MockWith {
            param (
                [string[]]$Paths
            )
            return $Paths
        }

        Mock -CommandName Get-CacheObject -MockWith {
            param(
                [string]$CacheType
            )
            return @(
                @{
                    Key = "\$ProjectName\Area1"
                    Value = @(
                        @{ Path = "\$ProjectName\Area1" }
                        @{ Path = "\$ProjectName\Area2" }
                    )
                },
                @{
                    Key = "\$ProjectName\Area"
                    Value = @(
                        @{ Path = "\$ProjectName\Area" }
                    )
                }
            )
        }

        # Setting up global variable
        $Global:DSCAZDO_OrganizationName = "SampleOrg"

    }

    AfterAll {
        # Cleanup
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    Context 'When AreaPaths is specified' {

        It 'Should format area paths and retrieve cached nodes' {

            # Arrange
            $projectName = "MyProject"
            $areaPaths = @("Area1", "Area2")

            # Act
            $result = Get-AzDoAreaNodes -ProjectName $projectName -AreaPaths $areaPaths

            # Assert
            Assert-MockCalled -CommandName Format-AzDoAreaPath -Times 1
            Assert-MockCalled -CommandName Get-AllAzDoClassificationNodePaths -Times 1
            Assert-MockCalled -CommandName Get-CacheObject -Times 1

            # Verify result properties
            $result.ProjectName | Should -Be $projectName
            $result.AreaPaths | Should -Contain "\$ProjectName\Area1"
            $result.AreaPaths | Should -Contain "\$ProjectName\Area2"
            $result.Status | Should -Be 'Unchanged'

        }
    }

    Context 'When Ensure is Absent and no AreaPaths are specified' {

        It 'Should set status to NotFound and populate propertiesChanged.toAdd' {
            # Arrange
            $projectName = "MyProject"

            # Act
            $result = Get-AzDoAreaNodes -ProjectName $projectName -Ensure Absent

            # Assert
            $result.Status | Should -Be 'NotFound'
            $result.propertiesChanged.toAdd | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When only top-level node exists' {

        It 'Should identify missing nodes and propose additions or deletions' {
            # Arrange
            $projectName = "MyProject"
            $areaPaths = @("\$ProjectName\Area")

            # Act
            $result = Get-AzDoAreaNodes -ProjectName $projectName -AreaPaths $areaPaths

            # Assert
            $result.Status | Should -Be 'Changed'
            $result.propertiesChanged.toAdd | Should -Not -BeNullOrEmpty
            $result.propertiesChanged.toRemove | Should -Not -BeNullOrEmpty

        }

    }

    Context 'When comparing current and desired states' {

        It 'Should correctly identify changes in area paths' {

            # Arrange
            $projectName = "MyProject"
            $areaPaths = @("Area1", "Area3") # Assume Area3 is new

            # Act
            $result = Get-AzDoAreaNodes -ProjectName $projectName -AreaPaths $areaPaths

            # Assert
            $result.Status | Should -Be Changed
            $result.propertiesChanged.toAdd.Path | Should -Be "\$ProjectName\Area3"
            $result.propertiesChanged.toRemove.Path | Should -Be "\$ProjectName\Area2"

        }

    }

}
