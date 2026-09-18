<#
.SYNOPSIS
Maps a set of changed repository paths to the integration test files that need to run.

.DESCRIPTION
The integration suite takes the better part of two hours against a live organization,
and most pull requests touch a handful of resources. This function decides which
Resources\*.tests.ps1 files a given change actually needs, so a narrow change pays for a
narrow run.

It is deliberately biased towards running too much rather than too little: a change it
cannot confidently attribute to specific resources selects the whole suite. Silently
skipping a test that would have caught a regression is far more expensive than running
one that was not needed.

Classification of each changed path:

  - tests\Integration\Resources\<Name>.tests.ps1
        Selects that file directly.

  - source\Classes\<NNN>.<Name>.ps1
        Attributed to resource <Name>. Note that the numbered class files include the
        base classes and the token classes, which are NOT DSC resources - those have no
        matching test file, fall through to the shared bucket, and correctly select the
        whole suite, since every resource inherits from them.

  - source\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\<Name>\...
        Attributed to resource <Name>.

  - The harness itself (Invoke-Tests.ps1, Supporting\, the integration workflow)
        Selects the whole suite - a change to how the suite runs has to be exercised by
        the suite.

  - Anything else under source\
        Shared code (the private API layer, enums, localized data, the manifest). Any
        resource can depend on it, so this selects the whole suite.

  - Documentation, examples, changelog, other workflows
        No runtime effect on the resources. Contributes nothing, and does not by itself
        force a full run.

A resource name is matched to test files whose base name is exactly that name or begins
with that name followed by a dot. The dot matters: 'AzDoProject' has to pick up
AzDoProject.Description and AzDoProject.NoDescription without also dragging in
AzDoProjectGroup, AzDoProjectPermission and AzDoProjectServices.

.PARAMETER ChangedPath
Repository-relative paths that the change touches, in either slash style. May be empty.

.PARAMETER IntegrationTestRoot
Path to tests\Integration. Its Resources folder is enumerated to resolve resource names
to real files, so a resource with no integration coverage yields no files rather than a
guess.

.PARAMETER NarrowSharedChanges
Do not let a shared-code change widen the run to the whole suite; select only the
resources the change attributes to.

This is for pull requests, where the point is fast feedback on what changed. A release is
gated differently: a tag push runs publish.yml, which calls this workflow with a non
pull_request event, and every non pull_request event runs the full suite regardless of
what changed. So anything a narrowed pull request run skips is still covered before
anything ships.

Narrowing is refused - RunAll comes back - when the change attributes to no resource at
all, because "just the affected resources" would then be nothing, and a run that tests
nothing must not report success.

.OUTPUTS
A hashtable with:
  RunAll  - [bool]     whether the whole suite should run.
  Path    - [string[]] the selected test file paths (empty when RunAll is true).
  Reason  - [string]   a human-readable explanation, logged by the caller.

.EXAMPLE
Get-AffectedIntegrationTest -ChangedPath 'source/Classes/102.AzDoWorkItemQuery.ps1' -IntegrationTestRoot .\tests\Integration
Selects only AzDoWorkItemQuery.tests.ps1.

.EXAMPLE
Get-AffectedIntegrationTest -ChangedPath 'source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Helper/New-ACLToken.ps1' -IntegrationTestRoot .\tests\Integration
Shared code - selects the whole suite.
#>
function Get-AffectedIntegrationTest
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [String[]]
        $ChangedPath,

        [Parameter(Mandatory = $true)]
        [String]
        $IntegrationTestRoot,

        [Parameter()]
        [Switch]
        $NarrowSharedChanges
    )

    $resourcesRoot = Join-Path -Path $IntegrationTestRoot -ChildPath 'Resources'

    $testFiles = @(
        Get-ChildItem -Path $resourcesRoot -Filter '*.tests.ps1' -File -ErrorAction SilentlyContinue
    )

    if ($testFiles.Count -eq 0)
    {
        # Nothing to select from. Say so rather than reporting an empty selection that a
        # caller could read as "no tests needed".
        return @{
            RunAll = $true
            Path   = @()
            Reason = "No test files found under '$resourcesRoot' - falling back to the full suite."
        }
    }

    # 'AzDoProject.Description.tests.ps1' -> 'AzDoProject.Description'
    $testNameOf = {
        param($File)
        $File.Name -replace '\.tests\.ps1$', ''
    }

    $selected  = [System.Collections.Generic.List[String]]::new()
    $resources = [System.Collections.Generic.List[String]]::new()
    $shared    = [System.Collections.Generic.List[String]]::new()

    foreach ($rawPath in $ChangedPath)
    {
        if ([String]::IsNullOrWhiteSpace($rawPath))
        {
            continue
        }

        # Normalise to forward slashes so the same rules work against git output and
        # Windows paths alike.
        $path = $rawPath.Trim().Replace('\', '/')

        switch -Regex ($path)
        {
            # A test file names itself.
            '^tests/Integration/Resources/(?<name>.+)\.tests\.ps1$'
            {
                $named = @($testFiles | Where-Object { (& $testNameOf $_) -eq $Matches['name'] })
                $named | ForEach-Object { $selected.Add($_.FullName) }
                break
            }

            # The harness itself.
            '^tests/Integration/(Invoke-Tests\.ps1|Supporting/|TestFrameworkConfiguration\.json)'
            {
                $shared.Add($path)
                break
            }

            '^\.github/workflows/integration-tests.*\.yml$'
            {
                $shared.Add($path)
                break
            }

            # A numbered class file. Only counts as a resource if a test file matches;
            # base and token classes fall through to $shared below.
            '^source/Classes/\d+[a-z]?\.(?<name>[^/]+)\.ps1$'
            {
                $name = $Matches['name']
                if ($testFiles | Where-Object { (& $testNameOf $_) -eq $name -or (& $testNameOf $_).StartsWith("$name.") })
                {
                    $resources.Add($name)
                }
                else
                {
                    $shared.Add($path)
                }
                break
            }

            # A resource's public functions.
            '^source/Modules/AzureDevOpsDsc\.Common/Resources/Functions/Public/(?<name>[^/]+)/'
            {
                $resources.Add($Matches['name'])
                break
            }

            # Documentation and examples have no runtime effect on the resources.
            '^(source/Examples/|docs/|README\.md$|CHANGELOG\.md$|CLAUDE\.md$)'
            {
                break
            }

            # Any other source change is shared code that anything may depend on.
            '^source/'
            {
                $shared.Add($path)
                break
            }

            # Unit tests, other workflows, repo tooling: no effect on the integration run.
            default
            {
                break
            }
        }
    }

    foreach ($name in ($resources | Select-Object -Unique))
    {
        # Not named $matches: that is PowerShell's automatic variable for the last -match
        # result, and the switch above depends on it.
        $matchingFiles = @($testFiles | Where-Object {
            $testName = & $testNameOf $_
            $testName -eq $name -or $testName.StartsWith("$name.")
        })

        $matchingFiles | ForEach-Object { $selected.Add($_.FullName) }
    }

    $unique = @($selected | Select-Object -Unique)

    if ($shared.Count -gt 0)
    {
        $sample = @($shared | Select-Object -Unique -First 5)
        $suffix = if ($shared.Count -gt $sample.Count) { " (+$($shared.Count - $sample.Count) more)" } else { '' }

        # Narrowing is refused when there is nothing to narrow to. A change that touches only
        # shared code attributes to no resource, so selecting "just the affected resources"
        # would select nothing and pass having tested nothing.
        if (-not $NarrowSharedChanges -or $unique.Count -eq 0)
        {
            return @{
                RunAll = $true
                Path   = @()
                Reason = "Shared code or the test harness changed, so any resource could be affected: $($sample -join ', ')$suffix"
            }
        }

        $names = @($unique | ForEach-Object { (Split-Path -Path $_ -Leaf) -replace '\.tests\.ps1$', '' } | Sort-Object)

        return @{
            RunAll = $false
            Path   = $unique
            Reason = ("Narrowed to the $($unique.Count) changed resource(s) of $($testFiles.Count): $($names -join ', '). " +
                      "Shared code also changed ($($sample -join ', ')$suffix); on a pull request that does not widen the " +
                      'run, and the release gate gives it full coverage.')
        }
    }

    if ($unique.Count -eq 0)
    {
        return @{
            RunAll = $false
            Path   = @()
            Reason = 'No integration-relevant changes - nothing under source/ or tests/Integration/ that maps to a resource with integration coverage.'
        }
    }

    $names = @($unique | ForEach-Object { (Split-Path -Path $_ -Leaf) -replace '\.tests\.ps1$', '' } | Sort-Object)

    return @{
        RunAll = $false
        Path   = $unique
        Reason = "Selected $($unique.Count) of $($testFiles.Count) test file(s): $($names -join ', ')"
    }
}
