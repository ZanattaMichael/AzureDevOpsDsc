$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoLockedPipelineSettings' -Tag "Unit", "PipelineSettings" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoLockedPipelineSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It 'flags a setting desired false that the organization forces true' {
        $orgLiveState = @{ StatusBadgesArePrivate = 'true' }
        $bound        = @{ StatusBadgesArePrivate = 'false' }
        $locked = @(Get-AzDoLockedPipelineSettings -OrgLiveState $orgLiveState -BoundParameters $bound -SettingNames @('StatusBadgesArePrivate'))
        $locked | Should -Be @('StatusBadgesArePrivate')
    }

    It 'does not flag a setting the org has not forced on' {
        $orgLiveState = @{ StatusBadgesArePrivate = 'false' }
        $bound        = @{ StatusBadgesArePrivate = 'false' }
        $locked = @(Get-AzDoLockedPipelineSettings -OrgLiveState $orgLiveState -BoundParameters $bound -SettingNames @('StatusBadgesArePrivate'))
        $locked | Should -BeNullOrEmpty
    }

    It 'does not flag a setting that is unmanaged (empty string)' {
        $orgLiveState = @{ StatusBadgesArePrivate = 'true' }
        $bound        = @{ StatusBadgesArePrivate = '' }
        $locked = @(Get-AzDoLockedPipelineSettings -OrgLiveState $orgLiveState -BoundParameters $bound -SettingNames @('StatusBadgesArePrivate'))
        $locked | Should -BeNullOrEmpty
    }

    It 'does not flag a setting desired true even if the org also forces it true' {
        $orgLiveState = @{ StatusBadgesArePrivate = 'true' }
        $bound        = @{ StatusBadgesArePrivate = 'true' }
        $locked = @(Get-AzDoLockedPipelineSettings -OrgLiveState $orgLiveState -BoundParameters $bound -SettingNames @('StatusBadgesArePrivate'))
        $locked | Should -BeNullOrEmpty
    }
}
