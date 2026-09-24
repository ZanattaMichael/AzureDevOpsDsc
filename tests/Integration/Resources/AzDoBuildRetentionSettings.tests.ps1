Describe "AzDoBuildRetentionSettings Integration Tests" -Tag "Integration", "BuildRetentionSettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_BUILD_RETENTION_SETTINGS'

        New-TestProject -ProjectName $PROJECTNAME

        $ORG_ = Resolve-TestOrg
        $HDR_ = Resolve-TestAuthHeader

        function Get-TestBuildRetentionSettings
        {
            Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/build/retention?api-version=7.1" -f $ORG_, $PROJECTNAME) -Headers $HDR_
        }

        function Set-TestBuildRetentionSetting
        {
            param([string]$ApiName, [int]$Value)
            $body = @{ $ApiName = @{ value = $Value } } | ConvertTo-Json -Depth 4
            Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/build/retention?api-version=7.1" -f $ORG_, $PROJECTNAME) -Headers $HDR_ -Method Patch -Body $body -ContentType 'application/json'
        }

        # Read the org's live min/max first - never hard-code the allowed range.
        $LIVE = Get-TestBuildRetentionSettings

        # Pick a value that is comfortably inside range but different from the current live value,
        # so applying it always exercises a real change.
        function New-InRangeValue
        {
            param($Setting, $Avoid)
            $candidate = [Math]::Min([int]$Setting.max, [Math]::Max([int]$Setting.min, [int]$Setting.value))
            if ($candidate -eq $Avoid -and $candidate -lt [int]$Setting.max) { return $candidate + 1 }
            if ($candidate -eq $Avoid -and $candidate -gt [int]$Setting.min) { return $candidate - 1 }
            return $candidate
        }

        $RUNS_VALUE      = New-InRangeValue -Setting $LIVE.purgeRuns                    -Avoid $LIVE.purgeRuns.value
        $ARTIFACTS_VALUE = New-InRangeValue -Setting $LIVE.purgeArtifacts               -Avoid $LIVE.purgeArtifacts.value
        $PR_VALUE        = New-InRangeValue -Setting $LIVE.purgePullRequestRuns         -Avoid $LIVE.purgePullRequestRuns.value
        $BRANCH_VALUE    = New-InRangeValue -Setting $LIVE.retainRunsPerProtectedBranch -Avoid $LIVE.retainRunsPerProtectedBranch.value

        $parameters = @{
            Name       = 'AzDoBuildRetentionSettings'
            ModuleName = 'AzureDevOpsDscNative'
        }
    }

    Context "Applying retention settings" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName                    = $PROJECTNAME
                DaysToKeepRuns                 = $RUNS_VALUE
                DaysToKeepArtifacts            = $ARTIFACTS_VALUE
                DaysToKeepPullRequestRuns      = $PR_VALUE
                RunsToRetainPerProtectedBranch = $BRANCH_VALUE
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying (no-drift Test)" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should have written every managed setting via the API" {
            $live = Get-TestBuildRetentionSettings
            $live.purgeRuns.value                    | Should -Be $RUNS_VALUE
            $live.purgeArtifacts.value                | Should -Be $ARTIFACTS_VALUE
            $live.purgePullRequestRuns.value          | Should -Be $PR_VALUE
            $live.retainRunsPerProtectedBranch.value  | Should -Be $BRANCH_VALUE
        }
    }

    Context "An unbound property is never compared or overwritten" {

        BeforeAll {
            # Capture the live value of a setting this Set call does NOT mention.
            $beforeArtifacts = (Get-TestBuildRetentionSettings).purgeArtifacts.value

            # Use a DaysToKeepRuns value that actually differs from the live one, so this Set call
            # really executes (and really PATCHes) rather than being skipped as already-converged.
            $script:RUNS_VALUE_2 = if ($RUNS_VALUE -lt [int]$LIVE.purgeRuns.max) { $RUNS_VALUE + 1 } else { $RUNS_VALUE - 1 }

            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                DaysToKeepRuns = $RUNS_VALUE_2
                # DaysToKeepArtifacts deliberately omitted.
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should have applied the bound setting" {
            (Get-TestBuildRetentionSettings).purgeRuns.value | Should -Be $RUNS_VALUE_2
        }

        It "Should leave the unbound setting untouched, read back directly via REST" {
            $afterArtifacts = (Get-TestBuildRetentionSettings).purgeArtifacts.value
            $afterArtifacts | Should -Be $beforeArtifacts
        }
    }

    Context "Detecting and fixing drift" {

        BeforeAll {
            # Re-establish a known-good, fully managed state.
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName                    = $PROJECTNAME
                DaysToKeepRuns                 = $RUNS_VALUE
                DaysToKeepArtifacts            = $ARTIFACTS_VALUE
                DaysToKeepPullRequestRuns      = $PR_VALUE
                RunsToRetainPerProtectedBranch = $BRANCH_VALUE
            }
            Invoke-DscResource @parameters
            Start-Sleep -Seconds 5

            # Drift a single managed setting directly via REST, bypassing the DSC resource.
            $script:DRIFTED_RUNS_VALUE = New-InRangeValue -Setting $LIVE.purgeRuns -Avoid $RUNS_VALUE
            Set-TestBuildRetentionSetting -ApiName 'purgeRuns' -Value $script:DRIFTED_RUNS_VALUE
        }

        It "Should return False (Test detects the drift)" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                DaysToKeepRuns = $RUNS_VALUE
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

        It "Should fix the drift on Set and return True on the next Test" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue

            (Get-TestBuildRetentionSettings).purgeRuns.value | Should -Be $RUNS_VALUE
        }
    }

    Context "Refusing an out-of-range value" {

        BeforeAll {
            $beforeRuns = (Get-TestBuildRetentionSettings).purgeRuns.value
            $outOfRangeValue = [int]$LIVE.purgeRuns.max + 1000

            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                DaysToKeepRuns = $outOfRangeValue
            }
        }

        It "Should throw instead of silently ignoring the value" {
            { Invoke-DscResource @parameters } | Should -Throw
        }

        It "Should never have PATCHed the out-of-range value" {
            (Get-TestBuildRetentionSettings).purgeRuns.value | Should -Be $beforeRuns
        }
    }
}
