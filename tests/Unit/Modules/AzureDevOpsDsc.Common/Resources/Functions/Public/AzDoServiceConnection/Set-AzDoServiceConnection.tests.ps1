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

}
