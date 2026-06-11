$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoVariableGroup Tests' -Tag "Unit", "VariableGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName  -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsVariableGroup
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error

    }

    Context 'When the variable group exists in cache' {

        BeforeEach {
            # The resource resolves the variable group from 'LiveVariableGroups' and the project id
            # from 'LiveProjects', so the mock returns different objects per cache type.
            Mock -CommandName Get-CacheItem -MockWith {
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{ id = 'vg-id'; name = 'TestVG' }
            }
        }

        It 'Should call Remove-DevOpsVariableGroup with the correct id' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Remove-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $VariableGroupId -eq 'vg-id' -and $ProjectId -eq 'proj-id'
            }
        }

        It 'Should call Remove-CacheItem with the composite key' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Export-CacheObject for LiveVariableGroups' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

    }

    Context 'When the variable group is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should write an error and not call Remove-DevOpsVariableGroup' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName Remove-DevOpsVariableGroup -Exactly 0
        }

        It 'Should not call Remove-CacheItem when group is missing' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'

            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 0
        }

    }

}
