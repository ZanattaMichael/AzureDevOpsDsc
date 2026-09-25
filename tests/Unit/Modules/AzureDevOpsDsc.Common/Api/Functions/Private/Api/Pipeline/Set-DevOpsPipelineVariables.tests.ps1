$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsPipelineVariables' -Tag "Unit", "Pipeline", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsPipelineVariables.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Set-DevOpsBuildDefinition -MockWith { param($ApiUri, $ProjectName, $DefinitionId, $Definition) return $Definition }
    }

    Context 'when the build definition has no existing variables' {
        BeforeEach {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return [PSCustomObject]@{ id = 42; revision = 3; name = 'CI' }
            }
        }

        It 'adds each supplied variable onto a freshly-created variables map' {
            $result = Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            $result.variables.Environment.value | Should -Be 'Prod'
            $result.variables.Environment.isSecret | Should -BeFalse
            $result.variables.Environment.allowOverride | Should -BeFalse
        }

        It 'defaults IsSecret and AllowOverride to false when not supplied' {
            $result = Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            $result.variables.Environment.isSecret | Should -BeFalse
        }

        It 'leaves every other field on the definition untouched' {
            $result = Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            $result.name | Should -Be 'CI'
            $result.revision | Should -Be 3
        }
    }

    Context 'when the build definition already has variables' {
        BeforeEach {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                $variables = [PSCustomObject]@{}
                $variables | Add-Member -MemberType NoteProperty -Name 'Existing' -Value ([PSCustomObject]@{ value = 'unchanged'; isSecret = $false; allowOverride = $false })
                $variables | Add-Member -MemberType NoteProperty -Name 'ApiKey' -Value ([PSCustomObject]@{ isSecret = $true; allowOverride = $false })
                return [PSCustomObject]@{ id = 42; revision = 3; variables = $variables }
            }
        }

        It 'replaces only the named variable and leaves the rest of the map untouched' {
            $result = Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'Existing'; Value = 'changed' })
            $result.variables.Existing.value | Should -Be 'changed'
            $result.variables.ApiKey.isSecret | Should -BeTrue
        }

        It 'writes a secret variable value every call, since the API never returns one to compare against' {
            $result = Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'ApiKey'; Value = 'newSecretValue'; IsSecret = $true })
            $result.variables.ApiKey.value | Should -Be 'newSecretValue'
            $result.variables.ApiKey.isSecret | Should -BeTrue
        }

        It 'adds a new variable alongside existing ones' {
            $result = Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'New'; Value = 'value' })
            $result.variables.New.value | Should -Be 'value'
            $result.variables.Existing.value | Should -Be 'unchanged'
        }
    }

    Context 'when the build definition cannot be read' {
        BeforeEach {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return $null }
        }

        It 'throws' {
            { Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -DefinitionId 42 `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' }) } | Should -Throw
        }
    }
}
