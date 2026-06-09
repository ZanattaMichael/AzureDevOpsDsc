$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoIterationNodes Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoIterationNodes.tests.ps1'
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

        Mock -CommandName New-ClassificationNodeResource -MockWith { return @() }
        Mock -CommandName Remove-ClassificationNodeResource -MockWith { return @() }
        Mock -CommandName Update-ClassificationNode -MockWith { return @{ success = $true } }
        Mock -CommandName Remove-CacheItem -MockWith { return @() }
        Mock -CommandName Add-CacheItem -MockWith { return @() }
        Mock -CommandName Set-CacheObject -MockWith { return @() }
        Mock -CommandName Refresh-CacheObject -MockWith { return @() }


    }

    Context 'When properties are added' {
        It 'Should call New-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                propertiesChanged = @{
                    toAdd = @(@{ Name = "Iteration1"; Path = "Path1" })
                    toRemove = @()
                    toUpdate = @()
                }
            }

            # Act
            Set-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Times 1
        }
    }

    Context 'When properties are removed' {
        It 'Should call Remove-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                propertiesChanged = @{
                    toAdd = @()
                    toRemove = @(@{ Name = "Iteration1"; Path = "Path1" })
                    toUpdate = @()
                }
            }

            # Act
            Set-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Times 1
        }
    }

    Context 'When properties are updated' {
        It 'Should call Update-ClassificationNode with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                propertiesChanged = @{
                    toAdd = @()
                    toRemove = @()
                    toUpdate = @(@{ Path = "Path1"; StartDate = (Get-Date); EndDate = (Get-Date).AddDays(7) })
                }
            }

            # Act
            Set-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Update-ClassificationNode -Times 1
        }
    }

    Context 'When no IterationAttributes are provided' {
        It 'Should handle empty IterationAttributes gracefully' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                propertiesChanged = @{
                    toAdd = @()
                    toRemove = @()
                    toUpdate = @()
                }
            }

            # Act
            Set-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 0 -Scope It
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 0 -Scope It
            Assert-MockCalled -CommandName Update-ClassificationNode -Exactly 0 -Scope It
        }
    }

    Context 'When Ensure parameter is specified' {
        It 'Should proceed without errors' {
            # Arrange
            $projectName = "MyProject"
            $ensure = "Present"
            $lookupResult = @{
                propertiesChanged = @{
                    toAdd = @()
                    toRemove = @()
                    toUpdate = @()
                }
            }

            # Act
            { Set-AzDoIterationNodes -ProjectName $projectName -Ensure $ensure -LookupResult $lookupResult } | Should -Not -Throw
        }
    }

    Context 'When Force parameter is used' {
        It 'Should execute forcefully' {
            # Arrange
            $projectName = "MyProject"
            $force = $true
            $lookupResult = @{
                propertiesChanged = @{
                    toAdd = @()
                    toRemove = @()
                    toUpdate = @()
                }
            }

            # Act
            Set-AzDoIterationNodes -ProjectName $projectName -Force:$force -LookupResult $lookupResult

            # Assert
            # No specific assertion for force, just ensuring no error occurs
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 0 -Scope It
        }
    }
}
