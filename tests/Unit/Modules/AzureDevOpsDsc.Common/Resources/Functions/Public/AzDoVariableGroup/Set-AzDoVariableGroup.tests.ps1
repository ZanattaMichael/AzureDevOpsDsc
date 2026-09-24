$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoVariableGroup Tests' -Tag "Unit", "VariableGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsVariableGroup   -MockWith { return @{ id = 'vg-id'; name = 'TestVG' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        Mock -CommandName Resolve-AzDoSharedProjectReferences
        Mock -CommandName Remove-DevOpsVariableGroup

    }

    Context 'When the variable group exists in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'vg-id'; name = 'TestVG' }
            }
        }

        It 'Should call Set-DevOpsVariableGroup with the group id' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $VariableGroupId -eq 'vg-id' -and $ProjectName -eq 'TestProject'
            }
        }

        It 'Should update the cache via Add-CacheItem after setting' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Export-CacheObject for LiveVariableGroups' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Refresh-CacheObject for LiveVariableGroups' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

    }

    Context 'When the variable group is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should write an error and not call Set-DevOpsVariableGroup' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 0
        }

        It 'Should not update the cache when group is missing' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 0
        }

    }

    Context 'When SharedWithProjects removes a previously shared project' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                              = 'vg-id'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestVG' },
                        @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'TestVG' }
                    )
                }
            }
            Mock -CommandName Resolve-AzDoSharedProjectReferences -MockWith {
                @( @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestVG' } )
            }
        }

        It 'Should call Remove-DevOpsVariableGroup to unshare the dropped project' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @()

            Assert-MockCalled -CommandName Remove-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $ProjectId -eq 'fab-id' -and $VariableGroupId -eq 'vg-id'
            }
        }

        It 'Should pass the resolved project references to Set-DevOpsVariableGroup' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @()

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $ProjectReferences.Count -eq 1
            }
        }

    }

    Context 'When SharedWithProjects is not specified' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
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

        It 'Should not touch sharing at all' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Resolve-AzDoSharedProjectReferences -Exactly 0
            Assert-MockCalled -CommandName Remove-DevOpsVariableGroup -Exactly 0
        }

    }

}
