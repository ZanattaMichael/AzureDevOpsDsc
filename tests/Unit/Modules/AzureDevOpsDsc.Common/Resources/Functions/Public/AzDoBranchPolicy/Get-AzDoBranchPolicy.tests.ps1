$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoBranchPolicy" -Tag "Unit", "BranchPolicy" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when the branch policy exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'mock-policy-id'; isEnabled = $true; isBlocking = $true }
            }
        }

        It "returns status Unchanged when properties match" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' -isEnabled $true -isBlocking $true
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when isEnabled differs" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' -isEnabled $false -isBlocking $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'isEnabled'
        }

        It "returns status Changed when isBlocking differs" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' -isEnabled $true -isBlocking $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'isBlocking'
        }

        It "populates liveCache with the cached policy" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }
    }

    Context "when the branch policy does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            $result.status | Should -Be 'NotFound'
        }

        It "returns empty propertiesChanged" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }
}
