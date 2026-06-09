$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoProjectServices" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoProjectServices.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    # New-AzDoProjectServices is a no-op stub (configuration is applied via Set)
    It "does not throw when called with valid parameters" {
        { New-AzDoProjectServices -ProjectName 'TestProject' } | Should -Not -Throw
    }

    It "accepts all service toggle parameters without error" {
        {
            New-AzDoProjectServices -ProjectName 'TestProject' `
                -GitRepositories 'Enabled' `
                -WorkBoards 'Disabled' `
                -BuildPipelines 'Enabled' `
                -TestPlans 'Disabled' `
                -AzureArtifact 'Enabled'
        } | Should -Not -Throw
    }
}
