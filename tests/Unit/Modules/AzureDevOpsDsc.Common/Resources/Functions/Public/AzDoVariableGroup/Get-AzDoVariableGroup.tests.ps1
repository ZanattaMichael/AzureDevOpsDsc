$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoVariableGroup Tests' -Tag "Unit", "VariableGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Test-AzDoArrayDrift.ps1')

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }
    }

    Context 'When the variable group is found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'mock-vg-id'; name = 'TestVG' }
            }
        }

        It 'Should return status Unchanged' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should populate liveCache with the cached item' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'mock-vg-id'
        }

        It 'Should call Get-CacheItem with the correct composite key' {
            Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }

    }

    Context 'When the variable group is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should return status NotFound' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'
            $result.status | Should -Be 'NotFound'
        }

        It 'Should not populate liveCache' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'
            $result.liveCache | Should -BeNullOrEmpty
        }

        It 'Should return Ensure Absent' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'
            $result.Ensure | Should -Be 'Absent'
        }

    }

    Context 'When optional parameters are supplied' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'vg-42'; name = 'MyVG' }
            }
        }

        It 'Should still return Unchanged with Description and Variables provided' {
            $vars = @{ key1 = 'value1' }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' `
                -Description 'desc' -Variables $vars -AllowAccess $true
            $result.status | Should -Be 'Unchanged'
        }

    }

    Context 'When SharedWithProjects is not supplied' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                              = 'vg-1'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'TestVG' }
                    )
                }
            }
        }

        It 'Should leave sharing untouched (Unchanged) even though the live group is shared' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -Not -Contain 'SharedWithProjects'
        }
    }

    Context 'When SharedWithProjects is supplied and matches the live sharing' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                              = 'vg-1'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'TestVG' }
                    )
                }
            }
        }

        It 'Should return Unchanged' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam')
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context 'When SharedWithProjects drifts from the live sharing' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                              = 'vg-1'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' }
                    )
                }
            }
        }

        It 'Should return Changed with SharedWithProjects flagged when a share is missing' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam')
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'SharedWithProjects'
        }

        It 'Should return Changed with SharedWithProjects flagged when a share should be removed' {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                              = 'vg-1'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'TestVG' }
                    )
                }
            }
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @()
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'SharedWithProjects'
        }
    }

    Context 'When SharedNameOverrides drifts from the live reference name' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                              = 'vg-1'
                    name                             = 'TestVG'
                    variableGroupProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'old-name' }
                    )
                }
            }
        }

        It 'Should return Changed with SharedNameOverrides flagged' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' `
                -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'shared-settings' }
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'SharedNameOverrides'
        }

        It 'Should return Unchanged when the override matches the live reference name' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' `
                -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'old-name' }
            $result.status | Should -Be 'Unchanged'
        }
    }

}
