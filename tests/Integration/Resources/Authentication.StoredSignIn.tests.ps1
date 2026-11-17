Describe "Stored sign-in Integration Tests" -Tag "Integration", "Authentication" {

    # Not a DSC resource: checks that a resource can restore the sign-in the test framework
    # stored in ModuleSettings.clixml. Every resource does this when it is constructed, and a new
    # PowerShell process has nothing else to go on - which is how the LCM, a scheduled task and
    # every DSC v3 'dsc resource' call run. The rest of the suite runs in the session that signed
    # in. Read-only throughout: the project it asks about is never created.
    #
    # It runs under whichever sign-in the suite was started with (TestFrameworkConfiguration.json).
    # With AuthenticationType 'PAT' it is the test that fails when the stored personal access
    # token cannot be read back ("Parameter set cannot be resolved ...").

    BeforeAll {

        $settingsPath = Join-Path -Path $env:AZDODSC_CACHE_DIRECTORY -ChildPath 'ModuleSettings.clixml'
        $script:StoredTokenType = (Import-Clixml -LiteralPath $settingsPath).Token.tokenType.ToString()

        # Runs a script in a new PowerShell process. PSModulePath and AZDODSC_CACHE_DIRECTORY are
        # inherited, so the child finds the same build of the module and the same stored sign-in.
        function Invoke-InNewPowerShellProcess
        {
            param([Parameter(Mandatory)][string]$Script)

            $pwsh    = (Get-Process -Id $PID).Path
            $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Script))
            $output  = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String

            return @{ ExitCode = $LASTEXITCODE; Output = $output }
        }

        $script:ProbeScript = @'
$ErrorActionPreference = 'Stop'
try
{
    $result = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDscNative' -Method Test -Property @{
        ProjectName = 'AZDODSC_STORED_SIGNIN_PROBE_DOES_NOT_EXIST'
    }
    "INDESIREDSTATE=$($result.InDesiredState)"
    exit 0
}
catch
{
    "PROBE-FAILED: $($_.Exception.Message)"
    exit 1
}
'@
    }

    Context "A resource in a new PowerShell process" {

        BeforeAll {
            $script:Probe = Invoke-InNewPowerShellProcess -Script $script:ProbeScript
        }

        It "Restores the stored sign-in without a parameter set error" {
            $script:Probe.Output | Should -Not -Match 'Parameter set cannot be resolved' -Because "the stored '$($script:StoredTokenType)' sign-in has to be restorable"
        }

        It "Runs the resource to completion" {
            $script:Probe.ExitCode | Should -Be 0 -Because $script:Probe.Output
        }

        It "Reaches the organization and reports the missing project as not in the desired state" {
            $script:Probe.Output | Should -Match 'INDESIREDSTATE=False'
        }
    }

    Context "A resource in the session that signed in" {

        # A personal access token is never reused from the session, so this takes the same
        # restore path as a new process; the other sign-in methods reuse their unexpired token.
        It "Constructs and runs after the sign-in is restored" {
            {
                Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDscNative' -Method Test -Property @{
                    ProjectName = 'AZDODSC_STORED_SIGNIN_PROBE_DOES_NOT_EXIST'
                }
            } | Should -Not -Throw
        }
    }
}
