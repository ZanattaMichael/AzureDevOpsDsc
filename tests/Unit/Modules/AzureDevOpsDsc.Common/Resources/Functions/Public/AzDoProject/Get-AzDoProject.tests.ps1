$currentFile = $MyInvocation.MyCommand.Path
# Pester tests for Get-AzDoProject

Describe "Get-AzDoProject" -Tag "Unit", "Project" {

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
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProject.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Not mocked (the family-root comparison tests exercise the real implementation) -
        # so Find-MockedFunctions never picks it up. Load it explicitly.
        . (Get-FunctionItem 'Get-AzDoProcessFamilyRootId.ps1').FullName

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Define common mock responses
        $mockProject = @{
            ProjectName       = 'ExistingProject'
            description       = 'ExistingDescription'
            SourceControlType = 'Git'
            Visibility        = 'Private'
        }

        $mockProcessTemplate = @{
            ProcessTemplate = 'Agile'
        }

        Mock -CommandName Test-AzDevOpsProjectName -MockWith { return $true }
        Mock -CommandName Write-Warning

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when the project exists" {
        BeforeEach {
            # Mock Get-CacheItem to return an existing project
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'ExistingProject' -and $Type -eq 'LiveProjects' } -MockWith { return $mockProject }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Agile' -and $Type -eq 'LiveProcesses' } -MockWith { return $mockProcessTemplate }
        }

        It "should return the project details with status unchanged" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private'
            $result.Status | Should -Be 'Unchanged'
            $result.ProjectName | Should -Be 'ExistingProject'
            $result.ProjectDescription | Should -Be 'ExistingDescription'
        }

        It "should return status changed when descriptions differ" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'NewDescription' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private'
            $result.Status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Description'
        }

        It "should return status changed when visibility differs" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Public'
            $result.Status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Visibility'
        }
    }

    Context "when the project does not exist" {
        BeforeEach {
            # Mock Get-CacheItem to return null for non-existing project
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
        }

        It "should return status NotFound" {
            $result = Get-AzDoProject -ProjectName 'NonExistentProject' -ProjectDescription 'AnyDescription' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private'
            $result.Status | Should -Be 'NotFound'
        }
    }

    Context "when the process template does not exist" {
        BeforeEach {
            # Mock Get-CacheItem to return null for non-existing process template
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'ExistingProject' -and $Type -eq 'LiveProjects' } -MockWith { return $mockProject }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'NonExistentTemplate' -and $Type -eq 'LiveProcesses' } -MockWith { return $null }
        }

        It "should throw an error" {
            { Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'NonExistentTemplate' -Visibility 'Private' } | Should -Throw
        }
    }

    Context "when source control type differs" {
        BeforeEach {
            # Mock Get-CacheItem to return an existing project with different source control type
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'ExistingProject' -and $Type -eq 'LiveProjects' } -MockWith {
                $mockProject.SourceControlType = 'Tfvc'
                return $mockProject
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Agile' -and $Type -eq 'LiveProcesses' } -MockWith { return $mockProcessTemplate }
        }

        It "should warn about source control type conflict" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private'
            $result.Status | Should -Be 'UnChanged'
            $result.ProjectName | Should -Be 'ExistingProject'
            $result.SourceControlType | Should -Be 'Git'
        }
    }

    Context "when the project's process differs and the migration is compatible" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'ExistingProject' -and $Type -eq 'LiveProjects' } -MockWith {
                return @{
                    ProjectName       = 'ExistingProject'
                    description       = 'ExistingDescription'
                    SourceControlType = 'Git'
                    Visibility        = 'Private'
                    id                = 'project-id'
                }
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'InheritedProcess' -and $Type -eq 'LiveProcesses' } -MockWith {
                return @{ ProcessTemplate = 'InheritedProcess'; id = 'desired-process-id' }
            }
            Mock -CommandName Get-DevOpsProjectCapabilities -MockWith {
                return @{ capabilities = @{ processTemplate = @{ templateTypeId = 'current-process-id' } } }
            }
            Mock -CommandName Get-DevOpsProcess -MockWith {
                param($Organization, $ProcessTypeId)
                return @{ typeId = $ProcessTypeId; parentProcessTypeId = 'shared-family-root'; customizationType = 'inherited' }
            }
        }

        It "should return status Changed with ProcessTemplate in propertiesChanged" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'InheritedProcess' -Visibility 'Private'
            $result.Status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'ProcessTemplate'
            $result.currentProcessTypeId | Should -Be 'current-process-id'
            $result.desiredProcessTypeId | Should -Be 'desired-process-id'
        }
    }

    Context "when the project's process differs and the migration is incompatible" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'ExistingProject' -and $Type -eq 'LiveProjects' } -MockWith {
                return @{
                    ProjectName       = 'ExistingProject'
                    description       = 'ExistingDescription'
                    SourceControlType = 'Git'
                    Visibility        = 'Private'
                    id                = 'project-id'
                }
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'UnrelatedProcess' -and $Type -eq 'LiveProcesses' } -MockWith {
                return @{ ProcessTemplate = 'UnrelatedProcess'; id = 'desired-process-id' }
            }
            Mock -CommandName Get-DevOpsProjectCapabilities -MockWith {
                return @{ capabilities = @{ processTemplate = @{ templateTypeId = 'current-process-id' } } }
            }
            Mock -CommandName Get-DevOpsProcess -MockWith {
                param($Organization, $ProcessTypeId)
                if ($ProcessTypeId -eq 'current-process-id')
                {
                    return @{ typeId = 'current-process-id'; parentProcessTypeId = 'family-root-A'; customizationType = 'inherited' }
                }
                return @{ typeId = $ProcessTypeId; parentProcessTypeId = 'family-root-B'; customizationType = 'inherited' }
            }
            Mock -CommandName Write-Error
        }

        It "should return status Error with reason ProcessMigrationIncompatible" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'UnrelatedProcess' -Visibility 'Private'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ProcessMigrationIncompatible'
            $result.propertiesChanged | Should -Not -Contain 'ProcessTemplate'
        }
    }

    Context "when the project's process matches the desired process" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'ExistingProject' -and $Type -eq 'LiveProjects' } -MockWith {
                return @{
                    ProjectName       = 'ExistingProject'
                    description       = 'ExistingDescription'
                    SourceControlType = 'Git'
                    Visibility        = 'Private'
                    id                = 'project-id'
                }
            }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'InheritedProcess' -and $Type -eq 'LiveProcesses' } -MockWith {
                return @{ ProcessTemplate = 'InheritedProcess'; id = 'same-process-id' }
            }
            Mock -CommandName Get-DevOpsProjectCapabilities -MockWith {
                return @{ capabilities = @{ processTemplate = @{ templateTypeId = 'same-process-id' } } }
            }
            Mock -CommandName Get-DevOpsProcess
        }

        It "should return status Unchanged and not need a family-root lookup" {
            $result = Get-AzDoProject -ProjectName 'ExistingProject' -ProjectDescription 'ExistingDescription' -SourceControlType 'Git' -ProcessTemplate 'InheritedProcess' -Visibility 'Private'
            $result.Status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -Not -Contain 'ProcessTemplate'
            Assert-MockCalled -CommandName Get-DevOpsProcess -Exactly -Times 0
        }
    }
}
