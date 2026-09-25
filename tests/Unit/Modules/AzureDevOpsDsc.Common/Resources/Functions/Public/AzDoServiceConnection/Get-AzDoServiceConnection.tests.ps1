$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoServiceConnection Tests' -Tag "Unit", "ServiceConnection" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Test-AzDoArrayDrift.ps1')

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName List-DevOpsServiceConnections -MockWith { return $null }
    }

    Context 'When the service connection is found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sc-id'; name = 'TestSC' }
            }
        }

        It 'Should return status Unchanged' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should populate liveCache with the cached item' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'sc-id'
        }

        It 'Should call Get-CacheItem with the correct composite key' {
            Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Get-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestSC' -and $Type -eq 'LiveServiceConnections'
            }
        }

    }

    Context 'When the service connection is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should return status NotFound' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'MissingSC' -ConnectionType 'Generic'
            $result.status | Should -Be 'NotFound'
        }

        It 'Should not populate liveCache' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'MissingSC' -ConnectionType 'Generic'
            $result.liveCache | Should -BeNullOrEmpty
        }

        It 'Should return Ensure Absent' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'MissingSC' -ConnectionType 'Generic'
            $result.Ensure | Should -Be 'Absent'
        }

    }

    Context 'When optional parameters are supplied' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sc-99'; name = 'MySC' }
            }
        }

        It 'Should still return Unchanged with Authorization and Data provided' {
            $auth = @{ scheme = 'UsernamePassword' }
            $data = @{ environment = 'Production' }
            $result = Get-AzDoServiceConnection -ProjectName 'Proj' -ConnectionName 'MySC' `
                -ConnectionType 'Generic' -Authorization $auth -Data $data -AllowAllPipelines $true
            $result.status | Should -Be 'Unchanged'
        }

    }

    Context 'When SharedWithProjects is not supplied' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                                = 'sc-1'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'TestSC' }
                    )
                }
            }
        }

        It 'Should leave sharing untouched (Unchanged) even though the live connection is shared' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -Not -Contain 'SharedWithProjects'
        }
    }

    Context 'When SharedWithProjects is supplied and matches the live sharing' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                                = 'sc-1'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'TestSC' }
                    )
                }
            }
        }

        It 'Should return Unchanged' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam')
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context 'When SharedWithProjects drifts from the live sharing' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                                = 'sc-1'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' }
                    )
                }
            }
        }

        It 'Should return Changed with SharedWithProjects flagged when a share is missing' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam')
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'SharedWithProjects'
        }

        It 'Should return Changed with SharedWithProjects flagged when a share should be removed' {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                                = 'sc-1'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'TestSC' }
                    )
                }
            }
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @()
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'SharedWithProjects'
        }
    }

    Context 'When SharedNameOverrides drifts from the live reference name' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id                                = 'sc-1'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'old-name' }
                    )
                }
            }
        }

        It 'Should return Changed with SharedNameOverrides flagged' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' `
                -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'shared-azure-sub' }
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'SharedNameOverrides'
        }

        It 'Should return Unchanged when the override matches the live reference name' {
            $result = Get-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' `
                -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'old-name' }
            $result.status | Should -Be 'Unchanged'
        }
    }

}
