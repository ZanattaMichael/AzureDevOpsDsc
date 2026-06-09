$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoExtension" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoExtension.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsExtension -MockWith { return @{ publisherId = 'TestPublisher'; extensionId = 'TestExt' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when installing an extension" {
        It "calls New-DevOpsExtension" {
            New-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
            Assert-MockCalled -CommandName New-DevOpsExtension -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveExtensions" {
            New-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveExtensions'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }
}
