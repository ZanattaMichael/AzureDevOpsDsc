$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTeam" -Tag "Unit", "Team" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTeam.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockTeam = @{
            id          = 'team-id-001'
            name        = 'TestTeam'
            description = 'A test team'
            descriptor  = 'vssgp.team-descriptor-001'
        }

        Mock -CommandName Write-Verbose
    }

    Context "when the team is found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            } -MockWith { return $mockTeam }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache with the cached team object" {
            $result = Get-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'team-id-001'
        }

        It "calls Get-CacheItem with the correct key and type" {
            Get-AzDoTeam -ProjectName 'TestProject' -TeamName 'TestTeam'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTeam' -and $Type -eq 'LiveTeams'
            }
        }
    }

    Context "when the team is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTeam -ProjectName 'TestProject' -TeamName 'NonExistentTeam'
            $result.status | Should -Be 'NotFound'
        }

        It "does not populate liveCache" {
            $result = Get-AzDoTeam -ProjectName 'TestProject' -TeamName 'NonExistentTeam'
            $result.liveCache | Should -BeNullOrEmpty
        }
    }
}
