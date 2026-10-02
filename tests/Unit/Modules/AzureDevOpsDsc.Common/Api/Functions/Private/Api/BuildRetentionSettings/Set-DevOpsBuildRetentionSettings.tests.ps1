$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsBuildRetentionSettings' -Tag "Unit", "BuildRetentionSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsBuildRetentionSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ purgeRuns = @{ value = 45 } } }
    }

    It 'PATCHes the build/retention endpoint with a "value" wrapper per setting' {
        Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ purgeRuns = 45 }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/MyProject/_apis/build/retention*' -and $Method -eq 'PATCH' -and
            ($Body | ConvertFrom-Json).runRetention.value -eq 45
        }
    }

    # The API ignores a field it does not know, so a read-side name in the body is a silent no-op.
    It 'sends <ReadName> as the update field <UpdateName>, not under its read-side name' -TestCases @(
        @{ ReadName = 'purgeRuns';                    UpdateName = 'runRetention' }
        @{ ReadName = 'purgeArtifacts';               UpdateName = 'artifactsRetention' }
        @{ ReadName = 'purgePullRequestRuns';         UpdateName = 'pullRequestRunRetention' }
        @{ ReadName = 'retainRunsPerProtectedBranch'; UpdateName = 'retainRunsPerProtectedBranch' }
    ) {
        param ($ReadName, $UpdateName)

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { $script:sentBody = $HttpBody }
        Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ $ReadName = 7 }

        $sent = $script:sentBody | ConvertFrom-Json
        @($sent.PSObject.Properties.Name) | Should -Be @($UpdateName)
        $sent.$UpdateName.value | Should -Be 7
    }

    It 'sends every supplied setting in one PATCH' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { $script:sentBody = $HttpBody }
        Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{
            purgeRuns = 30; purgeArtifacts = 14; purgePullRequestRuns = 10; retainRunsPerProtectedBranch = 3
        }

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly
        $sent = $script:sentBody | ConvertFrom-Json
        $sent.runRetention.value                 | Should -Be 30
        $sent.artifactsRetention.value           | Should -Be 14
        $sent.pullRequestRunRetention.value      | Should -Be 10
        $sent.retainRunsPerProtectedBranch.value | Should -Be 3
    }

    It 'throws on a setting name it cannot translate, without calling the API' {
        { Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ runRetention = 45 } } |
            Should -Throw "*Unknown retention setting 'runRetention'*"
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
    }

    It 'does nothing when no settings are supplied' {
        Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{}
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'throws a wrapped error' {
            { Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ purgeRuns = 45 } } | Should -Throw '*Failed to update retention settings*'
        }
    }
}
