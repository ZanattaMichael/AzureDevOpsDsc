$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoExtension" -Tag "Unit", "Extension" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoExtension.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsExtension -MockWith { return @{ publisherId = 'TestPublisher' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    It "calls Set-DevOpsExtension" {
        Set-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
        Assert-MockCalled -CommandName Set-DevOpsExtension -Exactly -Times 1
    }

    It "calls Add-CacheItem to update the cache" {
        Set-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
        Assert-MockCalled -CommandName Add-CacheItem -Times 1
    }
}
