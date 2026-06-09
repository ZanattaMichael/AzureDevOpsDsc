$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoDeploymentGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoDeploymentGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when deployment group exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 5; name = 'TestDG' }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache" {
            $result = Get-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }

        It "queries cache with correct composite key" {
            Get-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestDG' -and $Type -eq 'LiveDeploymentGroups'
            } -Times 1
        }
    }

    Context "when deployment group does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'NonExistent'
            $result.status | Should -Be 'NotFound'
        }
    }
}
