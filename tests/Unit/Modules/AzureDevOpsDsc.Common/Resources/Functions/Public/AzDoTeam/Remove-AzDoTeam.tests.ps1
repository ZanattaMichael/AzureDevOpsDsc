$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTeam" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTeam.tests.ps1'
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
            descriptor  = 'vssgp.team-descriptor-001'
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsTeam
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
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

        It "calls Remove-DevOpsTeam" {
            Remove-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Remove-DevOpsTeam -Exactly -Times 1
        }

        It "calls Remove-DevOpsTeam with the correct ProjectId and TeamId" {
            Remove-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Remove-DevOpsTeam -Exactly -Times 1 -ParameterFilter {
                $ProjectId -eq 'project-id-001' -and $TeamId -eq 'team-id-001'
            }
        }

        It "calls Remove-CacheItem with the correct key and type" {
            Remove-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            }
        }

        It "calls Export-CacheObject for LiveTeams" {
            Remove-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
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

        It "writes an error and returns without calling Remove-DevOpsTeam" {
            Remove-AzDoTeam -ProjectName 'NonExistentProject' -TeamName 'TestTeam'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Remove-DevOpsTeam -Exactly -Times 0
        }

        It "does not call Remove-CacheItem" {
            Remove-AzDoTeam -ProjectName 'NonExistentProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 0
        }
    }

    Context "when the team is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $mockProject }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTeams' } -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and returns without calling Remove-DevOpsTeam" {
            Remove-AzDoTeam -ProjectName 'TestProject' -TeamName 'NonExistentTeam'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Remove-DevOpsTeam -Exactly -Times 0
        }
    }
}
