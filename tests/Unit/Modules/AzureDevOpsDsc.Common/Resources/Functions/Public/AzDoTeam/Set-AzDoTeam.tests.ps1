$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTeam" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTeam.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockProject = @{
            id   = 'project-id-001'
            name = 'TestProject'
        }

        $mockTeam = @{
            id          = 'team-id-001'
            name        = 'TestTeam'
            description = 'Original description'
        }

        $mockUpdatedTeam = @{
            id          = 'team-id-001'
            name        = 'TestTeam'
            description = 'Updated description'
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsTeam -MockWith { return $mockUpdatedTeam }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when both project and team are found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject' -and $Type -eq 'LiveProjects'
            } -MockWith { return $mockProject }

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            } -MockWith { return $mockTeam }
        }

        It "calls Set-DevOpsTeam" {
            Set-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'Updated description'
            Assert-MockCalled -CommandName Set-DevOpsTeam -Exactly -Times 1
        }

        It "calls Set-DevOpsTeam with the correct ProjectId, TeamId, and TeamName" {
            Set-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'Updated description'
            Assert-MockCalled -CommandName Set-DevOpsTeam -Exactly -Times 1 -ParameterFilter {
                $ProjectId -eq 'project-id-001' -and $TeamId -eq 'team-id-001' -and $TeamName -eq 'TestTeam'
            }
        }

        It "calls Add-CacheItem with the correct key and type" {
            Set-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'Updated description'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            }
        }

        It "calls Export-CacheObject for LiveTeams" {
            Set-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'Updated description'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTeams'
            }
        }

        It "calls Refresh-CacheObject for LiveTeams" {
            Set-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'Updated description'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTeams'
            }
        }
    }

    Context "when the project is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $mockTeam }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and returns without calling Set-DevOpsTeam" {
            Set-AzDoTeam -ProjectName 'NonExistentProject' -TeamName 'TestTeam' -Description 'Updated description'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsTeam -Exactly -Times 0
        }
    }

    Context "when the team is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $mockProject }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and returns without calling Set-DevOpsTeam" {
            Set-AzDoTeam -ProjectName 'TestProject' -TeamName 'NonExistentTeam' -Description 'Updated description'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsTeam -Exactly -Times 0
        }
    }
}
