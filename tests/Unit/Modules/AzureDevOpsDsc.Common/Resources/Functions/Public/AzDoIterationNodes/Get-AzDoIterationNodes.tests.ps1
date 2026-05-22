$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoIterationNodes Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoIterationNodes.tests.ps1'
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

        # Mock external dependencies used within Get-AzDoIterationNodes
        Mock -CommandName Format-AzDoIterationNodes -MockWith {
            return $IterationAttributes
        }

        Mock -CommandName Get-CacheObject -MockWith {
            return @{
                Key = "\$ProjectName\Iteration1"
                Value = @(
                    @{ Path = "\$ProjectName\Iteration1"; StartDate = "2023-01-01"; EndDate = "2023-01-31" }
                )
            }
        }

        Mock -CommandName Compare-HashtableProperties -MockWith {
            return $true
        }

        Mock -CommandName Format-Date -MockWith {
            param([Object]$object)
            return (Get-Date -Date $object)
        }

    }

    Context 'When ProjectName is specified with IterationAttributes' {

        It 'Should process iteration nodes correctly' {
            # Arrange
            $projectName = "MyProject"
            $iterationAttributes = @(
                @{
                    Path = "\$ProjectName\Iteration1"
                    StartDate = "01-01-2023"
                    EndDate = "31-01-2023"
                }
            )

            # Act
            $result = Get-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be Unchanged
        }
    }

    Context 'When Ensure is Absent and no IterationAttributes are provided' {

        It 'Should mark nodes for removal' {
            # Arrange
            $projectName = "MyProject"

            # Act
            $result = Get-AzDoIterationNodes -ProjectName $projectName -Ensure Absent

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be NotFound
            $result.propertiesChanged.toAdd | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When cached nodes do not exist' {

        It 'Should indicate nodes are missing' {
            # Arrange
            Mock -CommandName Get-CacheObject -MockWith {
                return @{
                    Key = "\$ProjectName\Iteration"
                    Value = @()
                }
            }
            $projectName = "MyProject"
            $iterationAttributes = @(
                @{ Path = "\$ProjectName\Iteration1"; StartDate = "2023-01-01"; EndDate = "2023-01-31" }
            )

            # Act
            $result = Get-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be ([DSCGetSummaryState]::NotFound)
            $result.propertiesChanged.toAdd | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When there are differences in iteration node properties' {

        It 'Should update nodes with different properties' {
            # Arrange
            Mock -CommandName Compare-HashtableProperties -MockWith {
                return $false
            }
            $projectName = "MyProject"
            $iterationAttributes = @(
                @{ Path = "\$ProjectName\Iteration1"; StartDate = "2023-02-01"; EndDate = "2023-02-28" }
            )

            # Act
            $result = Get-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be ([DSCGetSummaryState]::Changed)
            $result.propertiesChanged.ToUpdate | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When Force parameter is used' {

        It 'Should force execution without errors' {
            # Arrange
            $projectName = "MyProject"
            $force = $true
            $iterationAttributes = @(
                @{ Path = "\$ProjectName\Iteration1"; StartDate = "2023-01-01"; EndDate = "2023-01-31" }
            )

            # Act
            $result = Get-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes -Force:$force

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be ([DSCGetSummaryState]::Unchanged)
        }
    }

}
