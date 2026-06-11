$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoPipelineEnvironment Tests' -Tag "Unit", "PipelineEnvironment" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineEnvironment.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

    }

    Context 'When the environment is found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'env-id'; name = 'TestEnv' }
            }
        }

        It 'Should return status Unchanged' {
            $result = Get-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should populate liveCache with the cached item' {
            $result = Get-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'env-id'
        }

        It 'Should call Get-CacheItem with the correct composite key' {
            Get-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'

            Assert-MockCalled -CommandName Get-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestEnv' -and $Type -eq 'LivePipelineEnvironments'
            }
        }

    }

    Context 'When the environment is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should return status NotFound' {
            $result = Get-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'MissingEnv'
            $result.status | Should -Be 'NotFound'
        }

        It 'Should not populate liveCache' {
            $result = Get-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'MissingEnv'
            $result.liveCache | Should -BeNullOrEmpty
        }

        It 'Should return Ensure Absent' {
            $result = Get-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'MissingEnv'
            $result.Ensure | Should -Be 'Absent'
        }

    }

    Context 'When optional Description parameter is supplied' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'env-7'; name = 'ProdEnv' }
            }
        }

        It 'Should still return Unchanged' {
            $result = Get-AzDoPipelineEnvironment -ProjectName 'Proj' -EnvironmentName 'ProdEnv' -Description 'Production environment'
            $result.status | Should -Be 'Unchanged'
        }

    }

}
