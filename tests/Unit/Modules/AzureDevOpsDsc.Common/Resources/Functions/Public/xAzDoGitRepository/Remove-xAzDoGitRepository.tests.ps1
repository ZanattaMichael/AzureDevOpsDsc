$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-xAzDoGitRepository' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-xAzDoGitRepository.tests.ps1'
        }

        # Load the functions to test
        $files = Invoke-BeforeEachFunctions (Find-Functions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-CacheItem -MockWith {
            return @{
                Key   = "$ProjectName\"
                Value = "RepositoryValue"
            }
        }

        Mock -CommandName Remove-GitRepository -MockWith {
            return @{
                Name = $RepositoryName
            }
        }

        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject

        $params = @{
            ProjectName     = "TestProject"
            RepositoryName  = "TestRepository"
            Ensure          = "Present"
        }

    }

    It 'Calls Get-CacheItem with appropriate parameters for Project' {
        Remove-xAzDoGitRepository @params

        Assert-MockCalled -CommandName Get-CacheItem -Times 1 -Exactly -ParameterFilter {
            $Key -eq "TestProject" -and $Type -eq "LiveProjects"
        }
    }

    It 'Calls Get-CacheItem with appropriate parameters for Repository' {
        Remove-xAzDoGitRepository @params

        Assert-MockCalled -CommandName Get-CacheItem -Times 1 -Exactly -ParameterFilter {
            $Key -eq "TestProject\TestRepository" -and $Type -eq "LiveRepositories"
        }
    }

    It 'Calls Remove-GitRepository with appropriate parameters' {
        Remove-xAzDoGitRepository @params
        Assert-MockCalled -CommandName Remove-GitRepository -Exactly 1
    }

    It 'Calls Remove-CacheItem with appropriate parameters' {
        Remove-xAzDoGitRepository @params

        Assert-MockCalled -CommandName Remove-CacheItem -Times 1 -Exactly -ParameterFilter {
            $Key -eq "TestProject\TestRepository" -and $Type -eq "LiveRepositories"
        }
    }

    It 'Calls Export-CacheObject with appropriate parameters' {
        Remove-xAzDoGitRepository @params

        Assert-MockCalled -CommandName Export-CacheObject -Times 1 -Exactly -ParameterFilter {
            $CacheType -eq 'LiveRepositories' -and $Content -eq $AzDoLiveRepositories
        }
    }

    It 'Fails if Project does not exist in LiveProjects cache' {

        Mock -CommandName Write-Error -Verifiable
        Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter { $Type -eq 'LiveProjects' }

        Remove-xAzDoGitRepository @params | Should -BeNullOrEmpty
        Assert-VerifiableMock

    }
}
