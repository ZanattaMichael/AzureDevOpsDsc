$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoExtension" -Tag "Unit", "Extension" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoExtension.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsExtension
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
    }

    It "calls Remove-DevOpsExtension" {
        Remove-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
        Assert-MockCalled -CommandName Remove-DevOpsExtension -Exactly -Times 1
    }

    It "calls Remove-CacheItem with LiveExtensions" {
        Remove-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
        Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
            $Type -eq 'LiveExtensions'
        } -Times 1
    }

    It "calls Export-CacheObject" {
        Remove-AzDoExtension -PublisherId 'TestPublisher' -ExtensionId 'TestExt'
        Assert-MockCalled -CommandName Export-CacheObject -Times 1
    }
}
