<#
.SYNOPSIS
Compares desired pipeline-settings values against live state and returns which managed settings
have drifted.

.DESCRIPTION
Shared by Get-AzDoPipelineSettings and Get-AzDoOrgPipelineSettings. A setting is a tri-state string
('' / 'true' / 'false'); '' means "not managed by this configuration" and is never compared, so an
omitted setting never reports drift. Callers wrap the result in @() - see the single-element-array
gotcha in CLAUDE.md.

.PARAMETER LiveState
A hashtable of DSC property name -> 'true'/'false', from ConvertTo-AzDoPipelineSettingsLiveState.

.PARAMETER BoundParameters
The calling function's $PSBoundParameters (or an equivalent hashtable/dictionary).

.PARAMETER SettingNames
The DSC property names to compare (a subset of $LiveState's keys - callers exclude org-locked
properties by passing a shorter list here).

.OUTPUTS
System.Object[] - the DSC property names whose desired value differs from live state.
#>
function Compare-AzDoPipelineSettingsDrift
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$LiveState,

        [Parameter(Mandatory = $true)]
        $BoundParameters,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.String[]]$SettingNames
    )

    $changed = @()
    foreach ($name in $SettingNames)
    {
        $desired = [string]$BoundParameters[$name]
        if (($desired -ne '') -and ($LiveState[$name] -ne $desired))
        {
            $changed += $name
        }
    }

    return $changed
}
