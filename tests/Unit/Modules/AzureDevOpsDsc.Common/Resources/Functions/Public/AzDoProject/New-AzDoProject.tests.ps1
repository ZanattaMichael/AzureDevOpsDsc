$currentFile = $MyInvocation.MyCommand.Path
# Pester tests for New-AzDoProject

Describe "New-AzDoProject" -Tag "Unit", "Project" {


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
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoProject.tests.ps1'
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

        # Define common mock responses
        $mockProcessTemplate = @{
            id = '12345'
            ProcessTemplate = 'Agile'
        }

        $mockProjectJob = @{
            url = 'https://dev.azure.com/TestOrg/_apis/projects/ExistingProject'
        }

        Mock -CommandName Test-AzDevOpsProjectName -MockWith { return $true }
        Mock -CommandName Refresh-AzDoCache

    }

    Context "when parameters are valid" {
        BeforeEach {
            # Mock Get-CacheItem to return a process template
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Agile' -and $Type -eq 'LiveProcesses' } -MockWith { return $mockProcessTemplate }

            # Mock New-DevOpsProject to simulate project creation
            Mock -CommandName New-DevOpsProject -MockWith { return $mockProjectJob }

            # Mock Wait-DevOpsProject to simulate waiting for project creation
            Mock -CommandName Wait-DevOpsProject

            # Mock Refresh-AzDoCache to simulate cache refresh
            Mock -CommandName Refresh-AzDoCache

        }

        It "should create a new project with specified parameters" {
            New-AzDoProject -ProjectName 'NewProject' -ProjectDescription 'New Project Description' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private'

            # Validate that Get-CacheItem was called with correct parameters
            Assert-MockCalled -CommandName Get-CacheItem -Exactly 1 -ParameterFilter { $Key -eq 'Agile' -and $Type -eq 'LiveProcesses' }

            # Validate that New-DevOpsProject was called with correct parameters
            Assert-MockCalled -CommandName New-DevOpsProject -Exactly 1 -ParameterFilter {
                ($organization -eq 'TestOrganization') -and
                ($projectName -eq 'NewProject') -and
                ($description -eq 'New Project Description') -and
                ($sourceControlType -eq 'Git') -and
                ($processTemplateId -eq '12345') -and
                ($visibility -eq 'Private')
            }

            # Validate that Wait-DevOpsProject was called with correct parameters
            Assert-MockCalled -CommandName Wait-DevOpsProject -Exactly 1 -ParameterFilter {
                $ProjectURL -eq 'https://dev.azure.com/TestOrg/_apis/projects/ExistingProject' -and
                $OrganizationName -eq 'TestOrganization'
            }

            # Validate that Refresh-AzDoCache was called with correct parameters
            Assert-MockCalled -CommandName Refresh-AzDoCache -Exactly 1 -ParameterFilter {
                $OrganizationName -eq 'TestOrganization'
            }
        }
    }

    Context "when process template does not exist" {
        BeforeEach {
            # Mock Get-CacheItem to return null for non-existing process template
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'NonExistentTemplate' -and $Type -eq 'LiveProcesses' } -MockWith { return $null }
        }

        It "should throw an error if process template is not found" {
            { New-AzDoProject -ProjectName 'NewProject' -ProjectDescription 'New Project Description' -SourceControlType 'Git' -ProcessTemplate 'NonExistentTemplate' -Visibility 'Private' } | Should -Throw "*Process template 'NonExistentTemplate' not found*"

            # The cache miss is confirmed against the live process list before giving up.
            Assert-MockCalled -CommandName List-DevOpsProcess -Exactly 1 -ParameterFilter { $Organization -eq 'TestOrganization' }
        }
    }

    Context "when the process template was created after the cache was built" {
        BeforeEach {
            # An inherited process created by an AzDoProcess resource earlier in the same
            # configuration is not in the LiveProcesses cache yet.
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'NewInheritedProcess' -and $Type -eq 'LiveProcesses' } -MockWith { return $null }
            Mock -CommandName List-DevOpsProcess -MockWith {
                return @(
                    [PSCustomObject]@{ id = 'agile-id'; name = 'Agile' }
                    [PSCustomObject]@{ id = 'inherited-id'; name = 'NewInheritedProcess' }
                )
            }
            Mock -CommandName Add-CacheItem
            Mock -CommandName New-DevOpsProject -MockWith { return $mockProjectJob }
            Mock -CommandName Wait-DevOpsProject
            Mock -CommandName Refresh-AzDoCache
        }

        It "should resolve the process live and create the project on it" {
            { New-AzDoProject -ProjectName 'NewProject' -ProjectDescription 'New Project Description' -SourceControlType 'Git' -ProcessTemplate 'NewInheritedProcess' -Visibility 'Private' } | Should -Not -Throw

            Assert-MockCalled -CommandName New-DevOpsProject -Exactly 1 -ParameterFilter { $processTemplateId -eq 'inherited-id' }
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter { $Key -eq 'NewInheritedProcess' -and $Type -eq 'LiveProcesses' }
        }
    }

    Context "when force parameter is used" -skip {
        BeforeEach {
            # Mock Get-CacheItem to return a process template
            Mock -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Agile' -and $Type -eq 'LiveProcesses' } -MockWith { return $mockProcessTemplate }

            # Mock New-DevOpsProject to simulate project creation
            Mock -CommandName New-DevOpsProject -MockWith { return $mockProjectJob }

            # Mock Wait-DevOpsProject to simulate waiting for project creation
            Mock -CommandName Wait-DevOpsProject

            # Mock Refresh-AzDoCache to simulate cache refresh
            Mock -CommandName Refresh-AzDoCache
        }

        It "should create a new project even if it already exists when -Force is used" {
            New-AzDoProject -ProjectName 'NewProject' -ProjectDescription 'New Project Description' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private' -Force

            # Validate that New-DevOpsProject was called with correct parameters
            Assert-MockCalled -CommandName New-DevOpsProject -Exactly 1 -ParameterFilter {
                $organization -eq 'TestOrg' -and
                $projectName -eq 'NewProject' -and
                $description -eq 'New Project Description' -and
                $sourceControlType -eq 'Git' -and
                $processTemplateId -eq '12345' -and
                $visibility -eq 'Private'
            }

            # Validate that Wait-DevOpsProject was called with correct parameters
            Assert-MockCalled -CommandName Wait-DevOpsProject -Exactly 1 -ParameterFilter {
                $ProjectURL -eq 'https://dev.azure.com/TestOrg/_apis/projects/ExistingProject' -and
                $OrganizationName -eq 'TestOrg'
            }

            # Validate that Refresh-AzDoCache was called with correct parameters
            Assert-MockCalled -CommandName Refresh-AzDoCache -Exactly 1 -ParameterFilter {
                $OrganizationName -eq 'TestOrg'
            }
        }
    }
}
