<#
.SYNOPSIS
Builds the PATCH body for the Build 'generalsettings' API from desired pipeline-settings values.

.DESCRIPTION
Shared by Set-AzDoPipelineSettings and Set-AzDoOrgPipelineSettings. Only settings the caller is
managing (set to 'true'/'false'; '' means "leave untouched") are included. Applies the same
DisableClassicPipelineCreation special case as ConvertTo-AzDoPipelineSettingsLiveState: the API's own
'disableClassicPipelineCreation' field is a read-only aggregate - PATCHing it returns 200 OK but the
live value never changes (a known platform bug - see
https://github.com/microsoft/azure-devops-go-api/issues/133) - so the two fields it aggregates,
which ARE independently settable, are patched instead.

.PARAMETER BoundParameters
The calling function's $PSBoundParameters (or an equivalent hashtable/dictionary). Callers that need
to withhold an org-locked property pass a copy with that key removed or blanked.

.PARAMETER SettingMap
The DSC-name -> API-name map from Get-AzDoPipelineSettingsMap.

.OUTPUTS
System.Collections.Hashtable - API field name -> [bool], ready to PATCH.
#>
function ConvertTo-AzDoPipelineSettingsPatch
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        $BoundParameters,

        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$SettingMap
    )

    $patch = @{}
    foreach ($dscName in $SettingMap.Keys)
    {
        $desired = [string]$BoundParameters[$dscName]
        if ($desired -ne '')
        {
            $boolValue = ($desired -eq 'true')
            if ($dscName -eq 'DisableClassicPipelineCreation')
            {
                $patch['disableClassicBuildPipelineCreation']   = $boolValue
                $patch['disableClassicReleasePipelineCreation'] = $boolValue
            }
            else
            {
                $patch[$SettingMap[$dscName]] = $boolValue
            }
        }
    }

    return $patch
}
