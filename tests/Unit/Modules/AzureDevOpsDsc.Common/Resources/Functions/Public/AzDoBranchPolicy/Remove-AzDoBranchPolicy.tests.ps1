$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoBranchPolicy" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsBranchPolicy
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when branch policy exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'existing-policy-id' }
            }
        }

        It "calls Remove-DevOpsBranchPolicy" {
            Remove-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Remove-DevOpsBranchPolicy -Exactly -Times 1
        }

        It "calls Remove-CacheItem" {
            Remove-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1
        }
    }

    Context "when branch policy not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsBranchPolicy" {
            Remove-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsBranchPolicy -Times 0
        }
    }
}
