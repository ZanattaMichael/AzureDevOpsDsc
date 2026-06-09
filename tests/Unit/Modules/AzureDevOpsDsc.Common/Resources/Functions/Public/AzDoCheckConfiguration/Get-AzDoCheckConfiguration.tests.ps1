$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoCheckConfiguration" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoCheckConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when check configuration exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'check-id'; type = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d' } }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            $result.status | Should -Be 'Unchanged'
        }

        It "queries cache with composite key" {
            Get-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\environment\TestEnv\Approval' -and $Type -eq 'LiveCheckConfigurations'
            } -Times 1
        }

        It "populates liveCache" {
            $result = Get-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }
    }

    Context "when check configuration does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            $result.status | Should -Be 'NotFound'
        }
    }
}
