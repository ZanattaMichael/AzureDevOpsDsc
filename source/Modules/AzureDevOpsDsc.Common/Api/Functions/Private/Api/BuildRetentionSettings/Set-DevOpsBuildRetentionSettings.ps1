<#
.SYNOPSIS
Updates the build (run/artifact) retention settings for an Azure DevOps project.

.DESCRIPTION
Patches the project's retention settings via the Build REST API
(PATCH https://dev.azure.com/{org}/{project}/_apis/build/retention). Only the supplied settings are
changed; the endpoint merges them with the existing settings. Each setting is sent as
'{ "<setting>": { "value": n } }' per the Retention - Update API contract.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name (or id) of the project.

.PARAMETER Settings
A hashtable of the settings to change (API field names, e.g. 'purgeRuns', mapped to the new integer
value for each).

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ purgeRuns = 45 }
#>
function Set-DevOpsBuildRetentionSettings
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    if ($Settings.Count -eq 0)
    {
        Write-Verbose '[Set-DevOpsBuildRetentionSettings] No settings supplied; nothing to do.'
        return
    }

    # Build the '{ "<setting>": { "value": n } }' PATCH body the API expects.
    $body = [ordered]@{}
    foreach ($key in $Settings.Keys)
    {
        $body[$key] = @{ value = $Settings[$key] }
    }

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/build/retention?api-version={2}' -f $Organization, $ProjectName, $ApiVersion
        Method = 'PATCH'
        Body   = $body | ConvertTo-Json -Depth 4
    }

    if (-not $PSCmdlet.ShouldProcess($ProjectName, 'Update build retention settings'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Set-DevOpsBuildRetentionSettings] Failed to update retention settings for '$ProjectName' in '$Organization': $_"
    }
}
