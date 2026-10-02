$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoProject" -Tag "Unit", "Project" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoProject.tests.ps1'
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

        # Resolve-DevOpsProcess runs for real - it wraps the LiveProcesses cache lookup these
        # tests mock - so Find-MockedFunctions never picks it up. Load it explicitly. Its live
        # fallback finds nothing unless a test says otherwise.
        . (Get-FunctionItem 'Resolve-DevOpsProcess.ps1').FullName
        Mock -CommandName List-DevOpsProcess -MockWith { return @() }

        Mock -CommandName Test-AzDevOpsProjectName -MockWith {
            return $true
        }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            if ($Type -eq 'LiveProjects')
            {
                return @{ id = '12345' }
            }
            elseif ($Type -eq 'LiveProcesses')
            {
                return @{ id = '67890' }
            }
        }

        Mock -CommandName Update-DevOpsProject -MockWith {
            return @{ url = "http://devopsprojecturl" }
        }

        Mock -CommandName Wait-DevOpsProject
        Mock -CommandName Refresh-AzDoCache
        Mock -CommandName Move-DevOpsProjectProcess -MockWith { return @{ processId = 'newproc'; projectId = '12345' } }
        Mock -CommandName Write-Error

    }

    Context "When setting a project" {

        It "Should update the project in Azure DevOps and refresh the cache" {
            # Arrange
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            $projectName = "TestProject"
            $projectDescription = "Test Description"
            $sourceControlType = "Git"
            $processTemplate = "Agile"
            $visibility = "Private"

            # Act
            Set-AzDoProject -ProjectName $projectName -ProjectDescription $projectDescription -SourceControlType $sourceControlType -ProcessTemplate $processTemplate -Visibility $visibility

            # Assert
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                ($Key -eq $projectName) -and
                ($Type -eq 'LiveProjects')
            }
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                ($Key -eq $processTemplate) -and
                ($Type -eq 'LiveProcesses')
            }
            Assert-MockCalled -CommandName Update-DevOpsProject -Exactly -Times 1 -ParameterFilter {
                ($organization -eq "TestOrganization") -and
                ($projectId -eq '12345') -and
                ($description -eq $projectDescription)
            }
            Assert-MockCalled -CommandName Wait-DevOpsProject -Exactly -Times 1 -ParameterFilter {
                ($ProjectURL -eq "http://devopsprojecturl") -and
                ($OrganizationName -eq "TestOrganization")
            }
            Assert-MockCalled -CommandName Refresh-AzDoCache -Exactly -Times 1 -ParameterFilter {
                $OrganizationName -eq "TestOrganization"
            }
        }
    }

    Context "When the process template does not exist" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects')
                {
                    return @{ id = '12345' }
                }
                elseif ($Type -eq 'LiveProcesses')
                {
                    return $null
                }
            }
        }

        It "should throw" {
            { Set-AzDoProject -ProjectName 'TestProject' -ProjectDescription 'Test Description' -SourceControlType 'Git' -ProcessTemplate 'NonExistentTemplate' -Visibility 'Private' } | Should -Throw "*Process template 'NonExistentTemplate' not found*"
        }

        It "should resolve a process missing from the cache through the live process list" {
            Mock -CommandName List-DevOpsProcess -MockWith {
                return @([PSCustomObject]@{ id = 'inherited-id'; name = 'NewInheritedProcess' })
            }
            Mock -CommandName Add-CacheItem

            $lookupResult = @{ propertiesChanged = @('ProcessTemplate') }

            Set-AzDoProject -ProjectName 'TestProject' -ProjectDescription 'Test Description' -SourceControlType 'Git' -ProcessTemplate 'NewInheritedProcess' -Visibility 'Private' -LookupResult $lookupResult

            Assert-MockCalled -CommandName Move-DevOpsProjectProcess -Exactly -Times 1 -ParameterFilter {
                ($ProjectId -eq '12345') -and
                ($ProcessTypeId -eq 'inherited-id')
            }
        }
    }

    Context "When Get-AzDoProject reported the process change as incompatible" {

        It "should refuse the change and not call Update-DevOpsProject or Move-DevOpsProjectProcess" {
            $lookupResult = @{ reason = 'ProcessMigrationIncompatible' }

            Set-AzDoProject -ProjectName 'TestProject' -ProjectDescription 'Test Description' -SourceControlType 'Git' -ProcessTemplate 'InheritedProcess' -Visibility 'Private' -LookupResult $lookupResult

            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
            Assert-MockCalled -CommandName Update-DevOpsProject -Exactly -Times 0
            Assert-MockCalled -CommandName Move-DevOpsProjectProcess -Exactly -Times 0
        }
    }

    Context "When Get-AzDoProject reported a supported process change" {

        It "should migrate the project to the desired process" {
            $lookupResult = @{
                propertiesChanged    = @('ProcessTemplate')
                desiredProcessTypeId = 'abcde-desired-id'
            }

            Set-AzDoProject -ProjectName 'TestProject' -ProjectDescription 'Test Description' -SourceControlType 'Git' -ProcessTemplate 'InheritedProcess' -Visibility 'Private' -LookupResult $lookupResult

            Assert-MockCalled -CommandName Move-DevOpsProjectProcess -Exactly -Times 1 -ParameterFilter {
                ($Organization -eq 'TestOrganization') -and
                ($ProjectId -eq '12345') -and
                ($ProcessTypeId -eq 'abcde-desired-id')
            }
        }

        It "should fall back to the resolved process template id when LookupResult has none" {
            $lookupResult = @{
                propertiesChanged = @('ProcessTemplate')
            }

            Set-AzDoProject -ProjectName 'TestProject' -ProjectDescription 'Test Description' -SourceControlType 'Git' -ProcessTemplate 'InheritedProcess' -Visibility 'Private' -LookupResult $lookupResult

            Assert-MockCalled -CommandName Move-DevOpsProjectProcess -Exactly -Times 1 -ParameterFilter {
                ($ProjectId -eq '12345') -and
                ($ProcessTypeId -eq '67890')
            }
        }
    }
}
