$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoGitRepository' -Tag "Unit", "GitRepository" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoGitRepository.tests.ps1'
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

        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ Name = $ProjectName; id = 'project-id' } }
        Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'repo-id'; name = $RepositoryName } }
        Mock -CommandName List-DevOpsGitRepository -MockWith { return $null }
        Mock -CommandName Set-GitRepository -MockWith { return @{ id = 'repo-id'; name = $Repository.name; isDisabled = $IsDisabled } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject

        $params = @{
            ProjectName    = 'TestProject'
            RepositoryName = 'TestRepository'
            IsDisabled     = $true
        }
    }

    It 'Calls Resolve-AzDoProject with the project name' {
        Set-AzDoGitRepository @params

        Assert-MockCalled -CommandName Resolve-AzDoProject -Exactly 1 -ParameterFilter { $ProjectName -eq 'TestProject' }
    }

    It 'Calls Get-CacheItem for the repository' {
        Set-AzDoGitRepository @params

        Assert-MockCalled -CommandName Get-CacheItem -Exactly 1 -ParameterFilter {
            $Key -eq 'TestProject\TestRepository' -and $Type -eq 'LiveRepositories'
        }
    }

    It 'Calls Set-GitRepository with the desired IsDisabled value' {
        Set-AzDoGitRepository @params

        Assert-MockCalled -CommandName Set-GitRepository -Exactly 1 -ParameterFilter { $IsDisabled -eq $true }
    }

    It 'Updates the LiveRepositories cache' {
        Set-AzDoGitRepository @params

        Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
            $Key -eq 'TestProject\TestRepository' -and $Type -eq 'LiveRepositories'
        }
        Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter { $CacheType -eq 'LiveRepositories' }
        Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter { $CacheType -eq 'LiveRepositories' }
    }

    It 'Fails and skips the change if the project cannot be resolved' {
        Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
        Mock -CommandName Write-Error -Verifiable

        Set-AzDoGitRepository @params

        Assert-VerifiableMock
        Assert-MockCalled -CommandName Set-GitRepository -Exactly 0
    }

    It 'Falls back to a live lookup and fails if the repository cannot be found anywhere' {
        Mock -CommandName Get-CacheItem -MockWith { return $null }
        Mock -CommandName List-DevOpsGitRepository -MockWith { return @() }
        Mock -CommandName Write-Error -Verifiable

        Set-AzDoGitRepository @params

        Assert-VerifiableMock
        Assert-MockCalled -CommandName Set-GitRepository -Exactly 0
    }

    It 'Resolves the repository via a live lookup when it is not in the cache' {
        Mock -CommandName Get-CacheItem -MockWith { return $null }
        Mock -CommandName List-DevOpsGitRepository -MockWith { return @(@{ id = 'repo-id'; name = 'TestRepository' }) }

        Set-AzDoGitRepository @params

        Assert-MockCalled -CommandName Set-GitRepository -Exactly 1 -ParameterFilter { $Repository.id -eq 'repo-id' }
    }
}
