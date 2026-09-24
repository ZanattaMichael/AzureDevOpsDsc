$currentFile = $MyInvocation.MyCommand.Path

Describe 'ConvertTo-AzDoPipelineSettingsPatch' -Tag "Unit", "PipelineSettings" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-AzDoPipelineSettingsPatch.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Get-AzDoPipelineSettingsMap.ps1').FullName

        $script:map = Get-AzDoPipelineSettingsMap
    }

    It 'includes only managed (non-empty) settings, mapped and boolean' {
        $bound = @{ EnforceJobAuthScope = 'true'; StatusBadgesArePrivate = 'false'; EnforceSettableVar = '' }
        $patch = ConvertTo-AzDoPipelineSettingsPatch -BoundParameters $bound -SettingMap $script:map
        $patch['enforceJobAuthScope']    | Should -Be $true
        $patch['statusBadgesArePrivate'] | Should -Be $false
        $patch.ContainsKey('enforceSettableVar') | Should -BeFalse
    }

    It 'expands DisableClassicPipelineCreation into both independently-settable aggregate fields' {
        $bound = @{ DisableClassicPipelineCreation = 'true' }
        $patch = ConvertTo-AzDoPipelineSettingsPatch -BoundParameters $bound -SettingMap $script:map
        $patch['disableClassicBuildPipelineCreation']   | Should -Be $true
        $patch['disableClassicReleasePipelineCreation'] | Should -Be $true
        $patch.ContainsKey('disableClassicPipelineCreation') | Should -BeFalse
    }

    It 'returns an empty hashtable when nothing is managed' {
        $patch = ConvertTo-AzDoPipelineSettingsPatch -BoundParameters @{} -SettingMap $script:map
        $patch.Count | Should -Be 0
    }
}
