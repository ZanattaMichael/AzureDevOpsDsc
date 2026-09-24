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
        Mock -CommandName Write-Warning

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Resolve-AzDoProject -MockWith { Get-CacheItem -Key $ProjectName -Type 'LiveProjects' }
        Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }
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

    Context 'When the variable group is shared with other projects' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                              = 'vg-id'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestVG' },
                        @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'TestVG' }
                    )
                }
            }
        }

        It 'Should warn that the group is also shared, but still remove it' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Write-Warning -Exactly 1
            Assert-MockCalled -CommandName Remove-DevOpsVariableGroup -Exactly 1
        }

    }

    Context 'When the variable group is not shared with any other project' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                              = 'vg-id'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestVG' }
                    )
                }
            }
        }

        It 'Should not warn' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Write-Warning -Exactly 0
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

    Context 'When SharedWithProjects and SharedNameOverrides are supplied' {

        # Regression test: Invoke-DscResource's GetDesiredStateParameters() splats every DSC
        # property onto Remove-, including these two - a Remove- that does not declare them
        # fails at call time with "A parameter cannot be found that matches parameter name
        # 'SharedNameOverrides'" (or 'SharedWithProjects'), even though this function never acts
        # on their values beyond the sharing warning above.

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{ id = 'vg-id'; name = 'TestVG' }
            }
        }

        It 'Should not throw when both parameters are populated' {
            { Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'shared-settings' } } | Should -Not -Throw
        }

        It 'Should still remove the group normally' {
            Remove-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'shared-settings' }

            Assert-MockCalled -CommandName Remove-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $VariableGroupId -eq 'vg-id' -and $ProjectId -eq 'proj-id'
            }
        }

    }

}
