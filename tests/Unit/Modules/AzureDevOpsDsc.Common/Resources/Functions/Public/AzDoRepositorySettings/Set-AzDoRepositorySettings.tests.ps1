$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoRepositorySettings" -Tag "Unit", "RepositorySettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoRepositorySettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsRepositorySettings
        Mock -CommandName Write-Error
    }

    Context "when repository exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'repo-id'; name = 'TestRepo' } }
        }

        It "calls Set-DevOpsRepositorySettings" {
            Set-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo'
            Assert-MockCalled -CommandName Set-DevOpsRepositorySettings -Exactly -Times 1
        }

        It "passes merge policy flags to Set-DevOpsRepositorySettings" {
            Set-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -AllowSquashMerge $true -AllowRebaseMerge $false
            Assert-MockCalled -CommandName Set-DevOpsRepositorySettings -ParameterFilter {
                $AllowSquashMerge -eq $true -and $AllowRebaseMerge -eq $false
            } -Times 1
        }
    }

    Context "when repository not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsRepositorySettings" {
            Set-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsRepositorySettings -Times 0
        }
    }
}
