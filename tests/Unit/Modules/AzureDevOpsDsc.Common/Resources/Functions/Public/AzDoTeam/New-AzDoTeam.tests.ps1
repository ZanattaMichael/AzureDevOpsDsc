$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTeam" -Tag "Unit", "Team" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTeam.tests.ps1'
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
            description = 'A test team'
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsTeam -MockWith { return $mockTeam }
        Mock -CommandName Get-DevOpsSecurityDescriptor -MockWith { return 'vssgp.team-descriptor-001' }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when parameters are valid and project exists in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject' -and $Type -eq 'LiveProjects'
            } -MockWith { return $mockProject }
        }

        It "calls New-DevOpsTeam" {
            New-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'A test team'
            Assert-MockCalled -CommandName New-DevOpsTeam -Exactly -Times 1
        }

        It "calls New-DevOpsTeam with the correct ProjectId and TeamName" {
            New-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam' -Description 'A test team'
            Assert-MockCalled -CommandName New-DevOpsTeam -Exactly -Times 1 -ParameterFilter {
                $ProjectId -eq 'project-id-001' -and $TeamName -eq 'TestTeam'
            }
        }

        It "calls Add-CacheItem with the correct key and type" {
            New-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            }
        }

        It "calls Export-CacheObject for LiveTeams" {
            New-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTeams'
            }
        }

        It "calls Refresh-CacheObject for LiveTeams" {
            New-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTeams'
            }
        }
    }

    Context "when the project is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and returns without calling New-DevOpsTeam" {
            New-AzDoTeam -ProjectName 'NonExistentProject' -TeamName 'TestTeam'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-DevOpsTeam -Exactly -Times 0
        }

        It "does not call Add-CacheItem" {
            New-AzDoTeam -ProjectName 'NonExistentProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 0
        }
    }
}
