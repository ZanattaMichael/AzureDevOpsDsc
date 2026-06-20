<#
.SYNOPSIS
Updates the pipeline general settings for an Azure DevOps project.

.DESCRIPTION
Patches the project's pipeline general settings via the Build REST API
(PATCH https://dev.azure.com/{org}/{project}/_apis/build/generalsettings). Only the supplied keys are
changed; the endpoint merges them with the existing settings.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name (or id) of the project.

.PARAMETER Settings
A hashtable of the settings to change (API field names mapped to boolean values).

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Set-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ enforceJobAuthScope = $true }
#>
function Set-DevOpsPipelineSettings
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
        Write-Verbose '[Set-DevOpsPipelineSettings] No settings supplied; nothing to do.'
        return
    }

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/build/generalsettings?api-version={2}' -f $Organization, $ProjectName, $ApiVersion
        Method = 'PATCH'
        Body   = $Settings | ConvertTo-Json -Depth 4
    }

    if (-not $PSCmdlet.ShouldProcess($ProjectName, 'Update pipeline general settings'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Set-DevOpsPipelineSettings] Failed to update pipeline settings for '$ProjectName' in '$Organization': $_"
    }
}
