$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoPipelineSettingsMap' -Tag "Unit", "PipelineSettings" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineSettingsMap.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It 'maps every shared DSC property to its API field name' {
        $map = Get-AzDoPipelineSettingsMap
        $map.Keys | Should -Be @(
            'EnforceJobAuthScope', 'EnforceJobAuthScopeForReleases', 'EnforceReferencedRepoScopedToken',
            'EnforceSettableVar', 'PublishPipelineMetadata', 'StatusBadgesArePrivate',
            'DisableClassicPipelineCreation', 'DisableImpliedYAMLCiTrigger'
        )
        $map.EnforceJobAuthScope     | Should -Be 'enforceJobAuthScope'
        $map.StatusBadgesArePrivate  | Should -Be 'statusBadgesArePrivate'
    }
}
