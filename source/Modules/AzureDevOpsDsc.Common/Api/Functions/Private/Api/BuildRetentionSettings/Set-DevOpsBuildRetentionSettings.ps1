<#
.SYNOPSIS
Updates the build (run/artifact) retention settings for an Azure DevOps project.

.DESCRIPTION
Patches the project's retention settings via the Build REST API
(PATCH https://dev.azure.com/{org}/{project}/_apis/build/retention). Only the supplied settings are
changed; the endpoint merges them with the existing settings.

The update contract names the settings differently from the read shape: the GET returns
'purgeRuns', 'purgeArtifacts', 'purgePullRequestRuns' and 'retainRunsPerProtectedBranch', while the
PATCH takes 'runRetention', 'artifactsRetention', 'pullRequestRunRetention' and
'retainRunsPerProtectedBranch', each as '{ "<setting>": { "value": n } }'. The endpoint answers 200
and ignores a field it does not know, so sending the read-side names changes nothing. This function
takes the read-side names and translates them, and throws on a name it cannot translate rather than
send a PATCH that would be silently ignored.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name (or id) of the project.

.PARAMETER Settings
A hashtable of the settings to change, keyed by the read-side field names the GET returns (e.g.
'purgeRuns'), each mapped to the new integer value.

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

    # The GET and the PATCH name the settings differently; translate from the read-side names.
    $updateFieldNames = @{
        purgeRuns                    = 'runRetention'
        purgeArtifacts               = 'artifactsRetention'
        purgePullRequestRuns         = 'pullRequestRunRetention'
        retainRunsPerProtectedBranch = 'retainRunsPerProtectedBranch'
    }

    # Build the '{ "<setting>": { "value": n } }' PATCH body the API expects.
    $body = [ordered]@{}
    foreach ($key in $Settings.Keys)
    {
        if (-not $updateFieldNames.ContainsKey($key))
        {
            throw "[Set-DevOpsBuildRetentionSettings] Unknown retention setting '$key'. Expected one of: $(($updateFieldNames.Keys | Sort-Object) -join ', ')."
        }
        $body[$updateFieldNames[$key]] = @{ value = $Settings[$key] }
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
