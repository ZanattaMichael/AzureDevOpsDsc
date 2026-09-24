$currentFile = $MyInvocation.MyCommand.Path

Describe 'Compare-AzDoPipelineSettingsDrift' -Tag "Unit", "PipelineSettings" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Compare-AzDoPipelineSettingsDrift.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It 'reports drift only for managed settings that differ from live state' {
        $liveState = @{ EnforceJobAuthScope = 'true'; StatusBadgesArePrivate = 'false' }
        $bound     = @{ EnforceJobAuthScope = 'true'; StatusBadgesArePrivate = 'true' }
        $changed = @(Compare-AzDoPipelineSettingsDrift -LiveState $liveState -BoundParameters $bound -SettingNames @('EnforceJobAuthScope', 'StatusBadgesArePrivate'))
        $changed | Should -Be @('StatusBadgesArePrivate')
    }

    It 'ignores an unmanaged (empty string) setting' {
        $liveState = @{ StatusBadgesArePrivate = 'false' }
        $bound     = @{ StatusBadgesArePrivate = '' }
        $changed = @(Compare-AzDoPipelineSettingsDrift -LiveState $liveState -BoundParameters $bound -SettingNames @('StatusBadgesArePrivate'))
        $changed | Should -BeNullOrEmpty
    }

    It 'excludes a setting not passed in SettingNames even if it differs' {
        $liveState = @{ StatusBadgesArePrivate = 'false' }
        $bound     = @{ StatusBadgesArePrivate = 'true' }
        $changed = @(Compare-AzDoPipelineSettingsDrift -LiveState $liveState -BoundParameters $bound -SettingNames @())
        $changed | Should -BeNullOrEmpty
    }
}
