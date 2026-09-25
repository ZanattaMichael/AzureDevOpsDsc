$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoServiceConnection Tests' -Tag "Unit", "ServiceConnection" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName    -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsServiceConnection -MockWith { return @{ id = 'sc-id'; name = 'TestSC' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        Mock -CommandName Resolve-AzDoSharedProjectReferences
        Mock -CommandName Remove-DevOpsServiceConnection
        Mock -CommandName Add-DevOpsServiceConnectionProjectReferences

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Resolve-AzDoProject -MockWith { Get-CacheItem -Key $ProjectName -Type 'LiveProjects' }
        Mock -CommandName List-DevOpsServiceConnections -MockWith { return $null }
    }

    Context 'When both project and service connection exist in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') {
                    return @{ id = 'proj-id'; name = 'TestProject' }
                }
                return @{ id = 'sc-id'; name = 'TestSC' }
            }
        }

        It 'Should call Set-DevOpsServiceConnection with connection id and project' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ServiceConnectionId -eq 'sc-id' -and $ProjectName -eq 'TestProject'
            }
        }

        It 'Should update the cache via Add-CacheItem after setting' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestSC' -and $Type -eq 'LiveServiceConnections'
            }
        }

        It 'Should call Export-CacheObject for LiveServiceConnections' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveServiceConnections'
            }
        }

        It 'Should call Refresh-CacheObject for LiveServiceConnections' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveServiceConnections'
            }
        }

    }

    Context 'When ConnectionType is not supplied (the DSC base class strips it from Set)' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') {
                    return @{ id = 'proj-id'; name = 'TestProject' }
                }
                return @{ id = 'sc-id'; name = 'TestSC'; type = 'generic' }
            }
        }

        It 'Should not throw a missing mandatory parameter error' {
            { Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' } | Should -Not -Throw
        }

        It 'Should update the connection using the existing connection type' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC'

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ServiceConnectionType -eq 'generic'
            }
        }

        It 'Should prefer an explicitly supplied ConnectionType' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'AzureRM'

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ServiceConnectionType -eq 'AzureRM'
            }
        }

    }

    Context 'When the project is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return $null }
                return @{ id = 'sc-id'; name = 'TestSC' }
            }
        }

        It 'Should write an error and not call Set-DevOpsServiceConnection' {
            Set-AzDoServiceConnection -ProjectName 'MissingProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 0
        }

    }

    Context 'When the service connection is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') {
                    return @{ id = 'proj-id'; name = 'TestProject' }
                }
                return $null
            }
        }

        It 'Should write an error and not call Set-DevOpsServiceConnection' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'MissingSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 0
        }

    }

    Context 'When SharedWithProjects removes a previously shared project' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                                = 'sc-id'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'TestSC' }
                    )
                }
            }
            Mock -CommandName Resolve-AzDoSharedProjectReferences -MockWith {
                @( @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' } )
            }
        }

        It 'Should call Remove-DevOpsServiceConnection to unshare the dropped project' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @()

            Assert-MockCalled -CommandName Remove-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ProjectId -eq 'fab-id' -and $ServiceConnectionId -eq 'sc-id'
            }
        }

        It 'Should pass the resolved project references to Set-DevOpsServiceConnection' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @()

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ProjectReferences.Count -eq 1
            }
        }

    }

    Context 'When SharedWithProjects is not specified' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                                = 'sc-id'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'TestSC' }
                    )
                }
            }
        }

        It 'Should not touch sharing at all' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Resolve-AzDoSharedProjectReferences -Exactly 0
            Assert-MockCalled -CommandName Remove-DevOpsServiceConnection -Exactly 0
            Assert-MockCalled -CommandName Add-DevOpsServiceConnectionProjectReferences -Exactly 0
        }

        It 'Should keep the projects the connection is already shared with in the update' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ProjectReferences.Count -eq 2 -and
                ($ProjectReferences.projectReference.id -contains 'fab-id') -and
                ($ProjectReferences.projectReference.id -contains 'proj-id')
            }
        }

    }

    Context 'When SharedWithProjects is not specified and the connection is not shared' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                                = 'sc-id'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' }
                    )
                }
            }
        }

        It 'Should leave the project references to the default owning reference' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $null -eq $ProjectReferences
            }
        }

    }

    Context 'When the existing connection has a url (issue #79)' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{ id = 'sc-id'; name = 'TestSC'; type = 'generic'; url = 'https://existing.example.com' }
            }
        }

        It 'Should pass the existing url so the update body carries one' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC'

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $Url -eq 'https://existing.example.com'
            }
        }

    }

    Context 'When SharedWithProjects adds a project the connection is not shared with' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                                = 'sc-id'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' }
                    )
                }
            }
            Mock -CommandName Resolve-AzDoSharedProjectReferences -MockWith {
                @(
                    @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' },
                    @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'shared-alias' }
                )
            }
        }

        It 'Should send only the references the connection already has in the update' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam')

            Assert-MockCalled -CommandName Set-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ProjectReferences.Count -eq 1 -and $ProjectReferences[0].projectReference.id -eq 'proj-id'
            }
        }

        It 'Should share with the new project through the dedicated share call, keeping its name override' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam')

            Assert-MockCalled -CommandName Add-DevOpsServiceConnectionProjectReferences -Exactly 1 -ParameterFilter {
                $ServiceConnectionId -eq 'sc-id' -and
                $ProjectReferences.Count -eq 1 -and
                $ProjectReferences[0].projectReference.id -eq 'fab-id' -and
                $ProjectReferences[0].name -eq 'shared-alias'
            }
        }

        It 'Should not unshare anything' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam')

            Assert-MockCalled -CommandName Remove-DevOpsServiceConnection -Exactly 0
        }

        It 'Should cache the full desired reference list' {
            Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam')

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Type -eq 'LiveServiceConnections' -and @($Value.serviceEndpointProjectReferences).Count -eq 2
            }
        }

        It 'Should throw when the share call fails, so a DSC Set() reports the failure instead of silently succeeding' {
            Mock -CommandName Add-DevOpsServiceConnectionProjectReferences -MockWith { throw 'share rejected' }

            { Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam') } |
                Should -Throw "*was updated but could not be shared/unshared*share rejected*"
        }

        It 'Should still cache the update that did succeed when the share call fails' {
            Mock -CommandName Add-DevOpsServiceConnectionProjectReferences -MockWith { throw 'share rejected' }

            { Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @('Fabrikam') } |
                Should -Throw

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestSC' -and $Type -eq 'LiveServiceConnections'
            }
            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1
        }

    }

    Context 'When the unshare call fails' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'proj-id'; name = 'TestProject' } }
                return @{
                    id                                = 'sc-id'
                    name                               = 'TestSC'
                    serviceEndpointProjectReferences = @(
                        @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' },
                        @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'TestSC' }
                    )
                }
            }
            Mock -CommandName Resolve-AzDoSharedProjectReferences -MockWith {
                @( @{ projectReference = @{ id = 'proj-id'; name = 'TestProject' }; name = 'TestSC' } )
            }
            Mock -CommandName Remove-DevOpsServiceConnection -MockWith { throw 'unshare rejected' }
        }

        It 'Should throw naming the project it could not unshare from' {
            { Set-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic' -SharedWithProjects @() } |
                Should -Throw "*unsharing from project 'Fabrikam' failed*unshare rejected*"
        }

    }

}
