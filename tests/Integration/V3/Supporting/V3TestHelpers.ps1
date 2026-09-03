#
# DSC v3 helper functions for integration tests.
# Dot-sourced by Invoke-V3Tests.ps1 and available to all V3 test files.
#
# Requires: DSC v3 CLI ('dsc') on $env:PATH and the AzureDevOpsDscNative module
# in $env:PSModulePath (built via build.ps1 and added by the CI workflow).
#

function Assert-DscV3Available
{
    $cmd = Get-Command dsc -CommandType Application -ErrorAction SilentlyContinue
    if (-not $cmd)
    {
        throw "DSC v3 CLI ('dsc') not found on PATH. " +
              "Install from https://github.com/PowerShell/DSC/releases and ensure it is on PATH."
    }
    $ver = (dsc --version 2>&1) -replace '^v', ''
    Write-Host "[V3] DSC CLI version: $ver"

    # Resolve (and report) the adapter now, so a CLI without a usable PowerShell adapter
    # fails during setup rather than inside the first test.
    Resolve-DscV3PowerShellAdapter | Out-Null
}

# Resource type of the PowerShell adapter, resolved once per session by
# Resolve-DscV3PowerShellAdapter below.
$script:DscV3AdapterType = $null

function Resolve-DscV3PowerShellAdapter
{
    <#
    .SYNOPSIS
        Returns the resource type of the PowerShell adapter this dsc CLI provides.

    .DESCRIPTION
        DSC 3.2.0 renamed the adapter from 'Microsoft.DSC/PowerShell' to
        'Microsoft.Adapter/PowerShell', keeping the old name as a deprecated alias that
        is removed in 4.0.0. CI installs whatever the latest release is, so neither name
        can be hard-coded: probe for the current one and fall back to the legacy name on
        an older CLI. Set $env:DSC_V3_ADAPTER to pin a specific adapter type.
    #>
    if ($script:DscV3AdapterType)
    {
        return $script:DscV3AdapterType
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DSC_V3_ADAPTER))
    {
        $script:DscV3AdapterType = $env:DSC_V3_ADAPTER
        Write-Host "[V3] PowerShell adapter (from DSC_V3_ADAPTER): $script:DscV3AdapterType"
        return $script:DscV3AdapterType
    }

    # A non-zero exit here is an expected 'not this one' answer, not a terminating error.
    $PSNativeCommandUseErrorActionPreference = $false

    $types = Get-DscV3ResourceType

    foreach ($candidate in 'Microsoft.Adapter/PowerShell', 'Microsoft.DSC/PowerShell')
    {
        if ($types -contains $candidate)
        {
            $script:DscV3AdapterType = $candidate
            Write-Host "[V3] PowerShell adapter: $candidate"
            return $candidate
        }
    }

    # Last resort before failing: the CLI printed a listing that nothing above could read.
    # Its text still names the adapter when the adapter is installed, and matching on that
    # beats failing the suite over an output shape.
    if ($script:LastDscV3Listing)
    {
        foreach ($candidate in 'Microsoft.Adapter/PowerShell', 'Microsoft.DSC/PowerShell')
        {
            if ($script:LastDscV3Listing -like "*$candidate*")
            {
                $script:DscV3AdapterType = $candidate
                Write-Host "[V3] PowerShell adapter named in the unparsed listing: $candidate"
                return $candidate
            }
        }
    }

    # Report what the CLI does expose. An incomplete install - the executable without the
    # adapter manifests that sit beside it in the release archive - satisfies
    # 'dsc --version' and then lists nothing, which is otherwise indistinguishable here
    # from a CLI that simply predates both adapter names.
    $availableText = if ($types) { ($types | Sort-Object -Unique) -join ', ' } else { '(none)' }

    # Include the unparsed listing text. A type count on its own cannot tell "the CLI
    # listed nothing" apart from "the listing was not parsed", and those need opposite fixes.
    $rawText = if ($script:LastDscV3Listing)
    {
        "`nUnparsed listing output: " + $script:LastDscV3Listing.Substring(0, [Math]::Min(2000, $script:LastDscV3Listing.Length))
    }
    else { '' }

    throw ("Neither 'Microsoft.Adapter/PowerShell' nor 'Microsoft.DSC/PowerShell' is listed by the " +
           "dsc CLI ($(dsc --version 2>&1)). The PowerShell adapter is required to invoke this " +
           "module's class-based resources.`nResource types the CLI can see: " + $availableText + $rawText)
}

# Raw text of the last resource listing that produced no types, kept so a failure can
# report what the CLI actually said rather than only how many types were read out of it.
$script:LastDscV3Listing = ''

function ConvertFrom-DscV3ResourceListing
{
    <#
    .SYNOPSIS
        Reads the resource types out of the text 'dsc resource list' printed.

    .DESCRIPTION
        Tries the whole of the text as one JSON document first, then falls back to one
        document per line. Both shapes occur: under --output-format json the listing is a
        single JSON array (pretty-printed across lines), so a line-by-line read of it
        finds nothing at all, while the plain listing emits one document per line.
    #>
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text))
    {
        return @()
    }

    try
    {
        $types = @(ConvertFrom-Json -InputObject $Text |
            ForEach-Object { $_.type } |
            Where-Object { $_ })

        if ($types.Count -gt 0)
        {
            return $types
        }
    }
    catch
    {
        # Not a single document - fall through to the per-line read below.
    }

    # A malformed line is skipped rather than failing the enumeration, so one bad
    # manifest does not hide every good one.
    return @(
        foreach ($line in ($Text -split "`r?`n"))
        {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            try { (ConvertFrom-Json -InputObject $line).type } catch { }
        }
    )
}

# How this dsc is asked for JSON, resolved once by Resolve-DscV3JsonForm below.
$script:DscV3JsonForm = $null

function Resolve-DscV3JsonForm
{
    <#
    .SYNOPSIS
        Returns how to ask this dsc CLI for JSON, as @{ Global = @(); Sub = @() }.

    .DESCRIPTION
        Where --output-format goes - or whether it exists at all - differs between
        releases, so it is probed rather than assumed. dsc 3.2.3 rejects it globally
        outright ("unexpected argument '--output-format' ... a similar argument exists:
        '--trace-format'") and prints JSON from 'resource list' without being asked. A
        hard-coded 'dsc --output-format json ...' therefore fails on that CLI, and every
        such call returned nothing at all rather than an error the caller could read.

        'resource list' is read-only, so it is the safe command to probe with; the form
        it settles on is reused for the get/set/test calls.
    #>
    if ($script:DscV3JsonForm)
    {
        return $script:DscV3JsonForm
    }

    # A non-zero exit is an answer to read, not a terminating error.
    $PSNativeCommandUseErrorActionPreference = $false

    # The unary comma matters: entries written on their own lines inside @() are
    # enumerated, so without it the hashtables would be fine but any array would flatten.
    foreach ($form in @(
            , @{ Global = @('--output-format', 'json'); Sub = @() }
            , @{ Global = @();                          Sub = @('--output-format', 'json') }
            , @{ Global = @();                          Sub = @() }))
    {
        $dscArgs = @($form.Global) + @('resource', 'list') + @($form.Sub)
        $raw = (@(& dsc @dscArgs 2>$null) -join "`n")

        if (@(ConvertFrom-DscV3ResourceListing -Text $raw).Count -gt 0)
        {
            $script:DscV3JsonForm = $form
            return $form
        }

        if (-not [string]::IsNullOrWhiteSpace($raw))
        {
            $script:LastDscV3Listing = $raw
        }
    }

    # Nothing answered. Settle on the plain form rather than throwing here: the callers
    # report the output they actually got, which says more than a failure raised at the
    # probe would.
    $script:DscV3JsonForm = @{ Global = @(); Sub = @() }
    return $script:DscV3JsonForm
}

function Get-DscV3ResourceType
{
    <#
    .SYNOPSIS
        Returns the resource types the dsc CLI lists, as a string array.

    .DESCRIPTION
        Enumerates without a type filter and matches in PowerShell. Passing the type name
        positionally to 'dsc resource list' looks like the cheaper probe, but it is not a
        reliable one: on dsc 3.2.3 'resource list Microsoft.Adapter/PowerShell' came back
        empty on the very CLI whose unfiltered listing names that adapter, which read as
        "no adapter installed" and failed the suite during setup.

    .PARAMETER Adapter
        Adapter to enumerate adapted resources from. Adapted resources - this module's
        class-based resources among them - are only listed when an adapter is named, so
        an unfiltered listing shows the built-in resources alone.
    #>
    param(
        [string]$Adapter
    )

    # A non-zero exit is an answer to read, not a terminating error.
    $PSNativeCommandUseErrorActionPreference = $false

    $form = Resolve-DscV3JsonForm
    $adapterArgs = if ([string]::IsNullOrWhiteSpace($Adapter)) { @() } else { @('--adapter', $Adapter) }

    $dscArgs = @($form.Global) + @('resource', 'list') + $adapterArgs + @($form.Sub)
    $raw = (@(& dsc @dscArgs 2>$null) -join "`n")

    $types = @(ConvertFrom-DscV3ResourceListing -Text $raw)

    if ($types.Count -eq 0 -and -not [string]::IsNullOrWhiteSpace($raw))
    {
        $script:LastDscV3Listing = $raw
    }

    return $types
}

function Invoke-DscV3Resource
{
    <#
    .SYNOPSIS
        Thin wrapper around 'dsc resource <method>' using the PowerShell adapter
        (Microsoft.Adapter/PowerShell, or Microsoft.DSC/PowerShell on a pre-3.2 CLI).

    .PARAMETER ResourceName
        PowerShell DSC class resource name (e.g. AzDoProject).

    .PARAMETER ModuleName
        Module that exports the resource (default: AzureDevOpsDscNative).

    .PARAMETER Method
        Get | Set | Test

    .PARAMETER Property
        Hashtable of resource properties.

    .OUTPUTS
        PSCustomObject - parsed JSON output from the dsc CLI.
    #>
    param(
        [Parameter(Mandatory)][string]$ResourceName,
        [string]$ModuleName  = 'AzureDevOpsDscNative',
        [Parameter(Mandatory)][ValidateSet('Get','Set','Test')][string]$Method,
        [Parameter(Mandatory)][hashtable]$Property
    )

    # 'dsc resource get|set|test' takes the bare properties object on stdin, not a
    # configuration document. A '{ resources: [...] }' wrapper is rejected with
    # 'Desired input is empty' (set) and 'Expected input is required' (test) - the
    # config document shape belongs to 'dsc config', not to 'dsc resource'.
    $payload = ConvertTo-Json -InputObject $Property -Depth 10 -Compress

    # A non-zero exit from dsc is handled below with the stderr text attached. Without
    # this the caller's $ErrorActionPreference='Stop' (PowerShell 7.4 applies it to
    # native commands) turns the exit code into a bare NativeCommandExitException and
    # the diagnostic assembled here is never seen.
    $PSNativeCommandUseErrorActionPreference = $false

    # Ask for JSON on stdout in whichever form this CLI accepts (see Resolve-DscV3JsonForm)
    # and keep progress/trace on stderr so it never contaminates the parsed document.
    # Redirect stderr to a temp file rather than merging with 2>&1, so a failure can still
    # surface the diagnostic text.
    $dscMethod  = $Method.ToLower()
    $form       = Resolve-DscV3JsonForm

    # --resource names the *adapted* resource type, not the adapter that hosts it.
    # Passing the adapter itself fails with exit 2 'Can not perform this operation on
    # the adapter itself'. Resolving the adapter is still worthwhile: it fails early
    # and with a clear message when the PowerShell adapter is missing entirely.
    $null       = Resolve-DscV3PowerShellAdapter
    $resourceType = "$ModuleName/$ResourceName"
    $dscArgs    = @($form.Global) + @('resource', $dscMethod, '--resource', $resourceType) + @($form.Sub)
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try
    {
        $rawOutput  = $payload | & dsc @dscArgs 2>$stderrPath
        $exitCode   = $LASTEXITCODE
        $stderrText = (Get-Content -Path $stderrPath -Raw)
    }
    finally
    {
        Remove-Item -Path $stderrPath -Force -ErrorAction SilentlyContinue
    }

    if ($exitCode -ne 0)
    {
        throw ("dsc $($dscArgs -join ' ') returned exit code $exitCode." +
               "`nStderr: $stderrText`nStdout: $rawOutput")
    }

    # For get/set/test the whole of stdout is a single JSON document (possibly
    # pretty-printed across lines), so parse it as one - no line-by-line extraction.
    $jsonText = ($rawOutput -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($jsonText))
    {
        throw "dsc resource $Method produced no output.`nStderr: $stderrText"
    }

    return $jsonText | ConvertFrom-Json
}

function Test-DscV3InDesiredState
{
    <#
    .SYNOPSIS
        Runs 'dsc resource test' and returns the boolean in-desired-state verdict.

    .DESCRIPTION
        Throws rather than returning $false when the verdict cannot be read out of the
        dsc output. A missing 'inDesiredState' means the shape of the result changed or
        the adapter failed - reporting that as "not in desired state" would turn a
        broken harness into a plain assertion failure and hide the real cause.
    #>
    param(
        [Parameter(Mandatory)][string]$ResourceName,
        [string]$ModuleName = 'AzureDevOpsDscNative',
        [Parameter(Mandatory)][hashtable]$Property
    )

    $result = Invoke-DscV3Resource -ResourceName $ResourceName -ModuleName $ModuleName `
                                   -Method Test -Property $Property

    # DSC v3 test output: { "desiredState": {}, "actualState": {}, "inDesiredState": true }
    # The PowerShell adapter wraps this inside a "results" array from the group resource.
    $testResult = if ($result.results) { $result.results[0] } else { $result }

    $verdict = $testResult.inDesiredState

    if ($null -eq $verdict)
    {
        # Fall back to the adapter's per-resource verdict before giving up.
        $verdict = $testResult.actualState.result[0].properties.InDesiredState
    }

    if ($null -eq $verdict)
    {
        throw ("dsc resource Test for $ResourceName returned no 'inDesiredState' verdict. " +
               "Raw result: " + ($result | ConvertTo-Json -Depth 10 -Compress))
    }

    return [bool]$verdict
}
