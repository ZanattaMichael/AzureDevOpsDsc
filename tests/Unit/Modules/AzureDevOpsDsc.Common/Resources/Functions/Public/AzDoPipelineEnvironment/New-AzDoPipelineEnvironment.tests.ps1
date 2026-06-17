$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoPipelineEnvironment Tests' -Tag "Unit", "PipelineEnvironment" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoPipelineEnvironment.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName        -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsPipelineEnvironment   -MockWith { return @{ id = 'new-env-id'; name = 'TestEnv' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject

    }

    Context 'When creating a new pipeline environment successfully' {

        It 'Should call New-DevOpsPipelineEnvironment with required parameters' {
            New-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'

            Assert-MockCalled -CommandName New-DevOpsPipelineEnvironment -Exactly 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $EnvironmentName -eq 'TestEnv'
            }
        }

        It 'Should call Add-CacheItem with the composite key' {
            New-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestEnv' -and $Type -eq 'LivePipelineEnvironments'
            }
        }

        It 'Should call Export-CacheObject for LivePipelineEnvironments' {
            New-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LivePipelineEnvironments'
            }
        }

        It 'Should call Refresh-CacheObject for LivePipelineEnvironments' {
            New-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LivePipelineEnvironments'
            }
        }

    }

    Context 'When a Description is provided' {

        It 'Should forward the description to New-DevOpsPipelineEnvironment' {
            New-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv' -Description 'My environment'

            Assert-MockCalled -CommandName New-DevOpsPipelineEnvironment -Exactly 1 -ParameterFilter {
                $Description -eq 'My environment'
            }
        }

    }

}
