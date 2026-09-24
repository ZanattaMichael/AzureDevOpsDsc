<#
.SYNOPSIS
Converts a live 'generalsettings' API response into the tri-state string form the pipeline-settings
DSC resources compare against.

.DESCRIPTION
Shared by Get-AzDoPipelineSettings and Get-AzDoOrgPipelineSettings. Maps each DSC property in
$SettingMap to its live 'true'/'false' string, applying the one special case both resources share:
the API's own 'disableClassicPipelineCreation' field is a read-only aggregate that never reflects a
PATCH (see Set-AzDoPipelineSettings), so it is derived from the two fields that actually drive it.

.PARAMETER Live
The object returned by Get-DevOpsPipelineSettings / Get-DevOpsOrgPipelineSettings.

.PARAMETER SettingMap
The DSC-name -> API-name map from Get-AzDoPipelineSettingsMap.

.OUTPUTS
System.Collections.Hashtable - DSC property name -> 'true' or 'false'.
#>
function ConvertTo-AzDoPipelineSettingsLiveState
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        $Live,

        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$SettingMap
    )

    $liveState = @{}
    foreach ($dscName in $SettingMap.Keys)
    {
        if ($dscName -eq 'DisableClassicPipelineCreation')
        {
            $liveState[$dscName] = if ([bool]$Live.disableClassicBuildPipelineCreation -and [bool]$Live.disableClassicReleasePipelineCreation) { 'true' } else { 'false' }
        }
        else
        {
            $apiName = $SettingMap[$dscName]
            $liveState[$dscName] = if ([bool]$Live.$apiName) { 'true' } else { 'false' }
        }
    }

    return $liveState
}
