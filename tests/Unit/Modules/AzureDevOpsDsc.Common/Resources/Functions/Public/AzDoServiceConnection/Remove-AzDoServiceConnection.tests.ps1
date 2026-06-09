$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoServiceConnection Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoServiceConnection.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName     -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsServiceConnection
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error

    }

    Context 'When the service connection exists in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sc-id'; name = 'TestSC' }
            }
        }

        It 'Should call Remove-DevOpsServiceConnection with the correct id' {
            Remove-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Remove-DevOpsServiceConnection -Exactly 1 -ParameterFilter {
                $ServiceConnectionId -eq 'sc-id' -and $ProjectName -eq 'TestProject'
            }
        }

        It 'Should call Remove-CacheItem with the composite key' {
            Remove-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestSC' -and $Type -eq 'LiveServiceConnections'
            }
        }

        It 'Should call Export-CacheObject for LiveServiceConnections' {
            Remove-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'TestSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveServiceConnections'
            }
        }

    }

    Context 'When the service connection is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should write an error and not call Remove-DevOpsServiceConnection' {
            Remove-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'MissingSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName Remove-DevOpsServiceConnection -Exactly 0
        }

        It 'Should not call Remove-CacheItem when connection is missing' {
            Remove-AzDoServiceConnection -ProjectName 'TestProject' -ConnectionName 'MissingSC' -ConnectionType 'Generic'

            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 0
        }

    }

}
