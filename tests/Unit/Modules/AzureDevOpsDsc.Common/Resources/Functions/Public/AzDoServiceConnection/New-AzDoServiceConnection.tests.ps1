$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoServiceConnection Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName    -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsServiceConnection -MockWith { return @{ id = 'new-sc-id'; name = 'TestSC' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error

    }

    Context 'When the project exists in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'proj-id'; name = 'TestProject' }
            }
        }

        It 'Should call New-DevOpsServiceConnection with required parameters' {
            New-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName New-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and
                $ServiceConnectionName -eq 'TestSC' -and
                $ServiceConnectionType -eq 'Generic'
            }
        }

        It 'Should call Add-CacheItem with the composite key' {
            New-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestSC' -and $Type -eq 'LiveServiceConnections'
            }
        }

        It 'Should call Export-CacheObject for LiveServiceConnections' {
            New-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveServiceConnections'
            }
        }

        It 'Should call Refresh-CacheObject for LiveServiceConnections' {
            New-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveServiceConnections'
            }
        }

    }

    Context 'When the project is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should write an error and not call New-DevOpsServiceConnection' {
            New-AzDoServiceConnection -ProjectName 'MissingProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName New-DevOpsServiceConnection -Exactly 0
        }

        It 'Should not update the cache when project is missing' {
            New-AzDoServiceConnection -ProjectName 'MissingProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 0
        }

    }

}
