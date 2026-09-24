$currentFile = $MyInvocation.MyCommand.Path

Describe 'ConvertTo-AzDoPipelineSettingsLiveState' -Tag "Unit", "PipelineSettings" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-AzDoPipelineSettingsLiveState.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Get-AzDoPipelineSettingsMap.ps1').FullName

        $script:map = Get-AzDoPipelineSettingsMap
    }

    It 'maps a plain boolean field to true/false strings' {
        $live = @{ enforceJobAuthScope = $true; statusBadgesArePrivate = $false }
        $state = ConvertTo-AzDoPipelineSettingsLiveState -Live $live -SettingMap $script:map
        $state.EnforceJobAuthScope    | Should -Be 'true'
        $state.StatusBadgesArePrivate | Should -Be 'false'
    }

    It 'derives DisableClassicPipelineCreation from both aggregate fields (both true)' {
        $live = @{ disableClassicBuildPipelineCreation = $true; disableClassicReleasePipelineCreation = $true }
        $state = ConvertTo-AzDoPipelineSettingsLiveState -Live $live -SettingMap $script:map
        $state.DisableClassicPipelineCreation | Should -Be 'true'
    }

    It 'derives DisableClassicPipelineCreation as false when only one aggregate field is true' {
        $live = @{ disableClassicBuildPipelineCreation = $true; disableClassicReleasePipelineCreation = $false }
        $state = ConvertTo-AzDoPipelineSettingsLiveState -Live $live -SettingMap $script:map
        $state.DisableClassicPipelineCreation | Should -Be 'false'
    }
}
