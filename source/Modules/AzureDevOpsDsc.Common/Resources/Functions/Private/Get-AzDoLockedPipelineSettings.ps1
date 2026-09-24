<#
.SYNOPSIS
Finds which managed pipeline settings are forced ON and locked by an organization-level policy.

.DESCRIPTION
When a pipeline settings switch is enabled at organization level, Azure DevOps forces it on and
locks it in every project; a project-level PATCH turning it back off is rejected or silently ignored.
Get-AzDoPipelineSettings calls this after reading both the project's and the organization's live
settings so it can exclude a locked property from drift instead of reporting drift it can never fix.

.PARAMETER OrgLiveState
The organization's live settings, as a hashtable of DSC property name -> 'true'/'false', from
ConvertTo-AzDoPipelineSettingsLiveState.

.PARAMETER BoundParameters
The calling function's $PSBoundParameters (or an equivalent hashtable/dictionary).

.PARAMETER SettingNames
The DSC property names to check.

.OUTPUTS
System.Object[] - the DSC property names that are desired 'false' but forced 'true' at organization
level. Callers wrap the result in @() - see the single-element-array gotcha in CLAUDE.md.
#>
function Get-AzDoLockedPipelineSettings
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$OrgLiveState,

        [Parameter(Mandatory = $true)]
        $BoundParameters,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.String[]]$SettingNames
    )

    $locked = @()
    foreach ($name in $SettingNames)
    {
        $desired = [string]$BoundParameters[$name]
        if (($desired -eq 'false') -and ($OrgLiveState[$name] -eq 'true'))
        {
            $locked += $name
        }
    }

    return $locked
}
