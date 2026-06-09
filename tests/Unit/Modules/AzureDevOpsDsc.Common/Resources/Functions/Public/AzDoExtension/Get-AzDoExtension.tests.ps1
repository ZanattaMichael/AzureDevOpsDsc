$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoExtension" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoExtension.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when extension exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ publisherId = 'TestPublisher'; extensionId = 'TestExt'; installState = @{ state = 'installed' } }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
            $result.status | Should -Be 'Unchanged'
        }

        It "queries cache with composite key" {
            Get-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestPublisher\TestExt' -and $Type -eq 'LiveExtensions'
            } -Times 1
        }
    }

    Context "when extension does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'NonExistentExt'
            $result.status | Should -Be 'NotFound'
        }
    }
}
