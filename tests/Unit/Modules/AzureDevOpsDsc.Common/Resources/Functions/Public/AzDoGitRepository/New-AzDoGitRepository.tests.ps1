$currentFile = $MyInvocation.MyCommand.Path

# Pester tests for New-AzDoGitRepository function
Describe "New-AzDoGitRepository Tests" -Tag "Unit", "GitRepository" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoGitRepository.tests.ps1'
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

        # Mock external cmdlets/functions
        Mock -CommandName Get-CacheItem -MockWith { return @{ Name = "TestProject" } }
        Mock -CommandName New-GitRepository -MockWith { return @{ id = 'repo-id'; Name = $RepositoryName } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }

        # Fork/import routing dependencies (SourceRepository is no longer forwarded directly to
        # New-GitRepository - see New-AzDoGitRepository.ps1).
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ Name = $ProjectName; id = 'source-project-id' } }
        Mock -CommandName List-DevOpsGitRepository -MockWith { return @() }
        Mock -CommandName List-DevOpsServiceConnections -MockWith { return @() }
        Mock -CommandName New-GitImportRequest -MockWith { return @{ importRequestId = 'import-1'; status = 'queued' } }
        Mock -CommandName Wait-DevOpsGitImportRequest -MockWith { return @{ importRequestId = 'import-1'; status = 'completed' } }
        Mock -CommandName Set-GitRepository -MockWith { return @{ id = 'repo-id'; Name = $Repository.Name; isDisabled = $true } }
    }

    Context "When mandatory parameters are provided" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
        }

        It "should call New-GitRepository" {
            $params = @{
                ProjectName     = 'TestProject'
                RepositoryName  = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 1
        }

        It "should call Add-CacheItem" {
            $params = @{
                ProjectName     = 'TestProject'
                RepositoryName  = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1
        }

        It "should call Export-CacheObject" {
            $params = @{
                ProjectName     = 'TestProject'
                RepositoryName  = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1
        }

        It "should call Refresh-CacheObject" {
            $params = @{
                ProjectName     = 'TestProject'
                RepositoryName  = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1
        }

    }

    Context "When optional parameters are provided" {

        It "should handle Force switch parameter" -skip {
            $params = @{
                ProjectName     = 'TestProject'
                RepositoryName  = 'TestRepo'
                Force           = $true
            }
            New-AzDoGitRepository @params

            # Since Force is not used in function logic directly, verifying other aspects
            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 1
        }
    }

    Context "When SourceRepository is not set" {

        It "should create a plain repository and never attempt an import or fork" {
            $params = @{
                ProjectName    = 'TestProject'
                RepositoryName = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 1 -ParameterFilter { $null -eq $ParentRepository }
            Assert-MockCalled -CommandName New-GitImportRequest -Exactly -Times 0
            Assert-MockCalled -CommandName Wait-DevOpsGitImportRequest -Exactly -Times 0
        }
    }

    Context "When SourceRepository is a URL (Import)" {

        It "should create the repository, then start and wait for an import request" {
            $params = @{
                ProjectName      = 'TestProject'
                RepositoryName   = 'TestRepo'
                SourceRepository = 'https://github.com/MyUser/MyRepo.git'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 1 -ParameterFilter { $null -eq $ParentRepository }
            Assert-MockCalled -CommandName New-GitImportRequest -Exactly -Times 1 -ParameterFilter { $SourceUrl -eq 'https://github.com/MyUser/MyRepo.git' -and $null -eq $ServiceEndpointId }
            Assert-MockCalled -CommandName Wait-DevOpsGitImportRequest -Exactly -Times 1 -ParameterFilter { $ImportRequestId -eq 'import-1' }
        }

        It "should treat an SSH remote the same as a URL" {
            $params = @{
                ProjectName      = 'TestProject'
                RepositoryName   = 'TestRepo'
                SourceRepository = 'git@github.com:MyUser/MyRepo.git'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName New-GitImportRequest -Exactly -Times 1 -ParameterFilter { $SourceUrl -eq 'git@github.com:MyUser/MyRepo.git' }
        }

        It "should resolve the named service connection and pass its id to the import request" {
            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveServiceConnections' }
            Mock -CommandName List-DevOpsServiceConnections -MockWith { return @(@{ id = 'sc-id'; name = 'GitHub-Import' }) }

            $params = @{
                ProjectName                 = 'TestProject'
                RepositoryName              = 'TestRepo'
                SourceRepository            = 'https://github.com/MyOrg/PrivateRepo.git'
                ImportServiceConnectionName = 'GitHub-Import'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName New-GitImportRequest -Exactly -Times 1 -ParameterFilter { $ServiceEndpointId -eq 'sc-id' }
        }

        It "should not start an import when the named service connection cannot be found" {
            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveServiceConnections' }
            Mock -CommandName List-DevOpsServiceConnections -MockWith { return @() }
            Mock -CommandName Write-Error -Verifiable

            $params = @{
                ProjectName                 = 'TestProject'
                RepositoryName              = 'TestRepo'
                SourceRepository            = 'https://github.com/MyOrg/PrivateRepo.git'
                ImportServiceConnectionName = 'DoesNotExist'
            }
            New-AzDoGitRepository @params

            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-GitImportRequest -Exactly -Times 0
        }

        It "should surface a failed/timed-out import (via Wait-DevOpsGitImportRequest) rather than leaving the repository silently empty" {
            Mock -CommandName Wait-DevOpsGitImportRequest -MockWith {
                Write-Error "[Wait-DevOpsGitImportRequest] Import request 'import-1' ended with status 'failed'"
                return @{ importRequestId = 'import-1'; status = 'failed' }
            }
            Mock -CommandName Write-Error -Verifiable

            $params = @{
                ProjectName      = 'TestProject'
                RepositoryName   = 'TestRepo'
                SourceRepository = 'https://github.com/MyUser/MyRepo.git'
            }
            New-AzDoGitRepository @params

            Assert-VerifiableMock
        }
    }

    Context "When SourceRepository names an existing repository (Fork)" {

        It "should resolve the source repository in the same project and pass ParentRepository to New-GitRepository" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ Name = 'TestProject'; id = 'source-project-id' } } -ParameterFilter { $Type -eq 'LiveProjects' }
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'source-repo-id' } } -ParameterFilter { $Type -eq 'LiveRepositories' }

            $params = @{
                ProjectName      = 'TestProject'
                RepositoryName   = 'TestRepo'
                SourceRepository = 'TemplateRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 1 -ParameterFilter {
                $ParentRepository.id -eq 'source-repo-id' -and $ParentRepository.project.id -eq 'source-project-id'
            }
            Assert-MockCalled -CommandName New-GitImportRequest -Exactly -Times 0
        }

        It "should resolve a cross-project fork source via Resolve-AzDoProject and List-DevOpsGitRepository" {
            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveRepositories' }
            Mock -CommandName Resolve-AzDoProject -MockWith { return @{ Name = 'UpstreamProject'; id = 'upstream-project-id' } }
            Mock -CommandName List-DevOpsGitRepository -MockWith { return @(@{ id = 'upstream-repo-id'; name = 'UpstreamRepo' }) }

            $params = @{
                ProjectName      = 'TestProject'
                RepositoryName   = 'TestRepo'
                SourceRepository = 'UpstreamProject/UpstreamRepo'
                SourceType       = 'Fork'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName Resolve-AzDoProject -Exactly -Times 1 -ParameterFilter { $ProjectName -eq 'UpstreamProject' }
            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 1 -ParameterFilter {
                $ParentRepository.id -eq 'upstream-repo-id' -and $ParentRepository.project.id -eq 'upstream-project-id'
            }
        }

        It "should error and skip creation when the fork source repository cannot be found" {
            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveRepositories' }
            Mock -CommandName List-DevOpsGitRepository -MockWith { return @() }
            Mock -CommandName Write-Error -Verifiable

            $params = @{
                ProjectName      = 'TestProject'
                RepositoryName   = 'TestRepo'
                SourceRepository = 'DoesNotExist'
            }
            New-AzDoGitRepository @params

            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 0
        }
    }

    Context "When IsDisabled is requested at creation" {

        It "should disable the repository after it (and any import) has been created" {
            $params = @{
                ProjectName    = 'TestProject'
                RepositoryName = 'TestRepo'
                IsDisabled     = $true
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName Set-GitRepository -Exactly -Times 1 -ParameterFilter { $IsDisabled -eq $true }
        }

        It "should not call Set-GitRepository when IsDisabled is not requested" {
            $params = @{
                ProjectName    = 'TestProject'
                RepositoryName = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-MockCalled -CommandName Set-GitRepository -Exactly -Times 0
        }
    }

    Context 'When the cache returns $null' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "should process the repository creation" {

            Mock -CommandName Write-Error -Verifiable
            Mock -CommandName Get-CacheItem -MockWith { return $null }

            $params = @{
                ProjectName     = 'TestProject'
                RepositoryName  = 'TestRepo'
            }
            New-AzDoGitRepository @params

            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-GitRepository -Exactly -Times 0
        }

    }

}
