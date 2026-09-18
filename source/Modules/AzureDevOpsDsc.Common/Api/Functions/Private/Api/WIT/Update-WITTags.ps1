<#
.SYNOPSIS
Renames a work item tag, merging it into an existing tag when the target name is already taken.

.DESCRIPTION
PATCHes a tag in the Azure DevOps work item tracking API. Renaming a tag to a name that already
exists merges the two: Azure DevOps re-tags every work item that carried the old tag and the old
tag ceases to exist.

That merge-on-rename behaviour is what makes tag correction cheap. The alternative - querying
every work item carrying the bad tag with WIQL and patching System.Tags on each one - is slower,
non-atomic, and bounded by work item count rather than tag count.

It is also irreversible. There is no undo for a merge, so callers are expected to have applied
their own safety checks before calling this.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TagId
The id of the tag to rename. The API also accepts a tag name here, but ids are preferred because
a name that has just been merged away no longer resolves.

.PARAMETER NewName
The name to rename the tag to. If a tag with this name already exists, the two are merged.

.EXAMPLE
Update-WITTags -Organization 'myorg' -ProjectName 'MyProject' -TagId $tag.id -NewName 'Bug'
#>
Function Update-WITTags
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$TagId,

        [Parameter(Mandatory = $true)]
        [System.String]$NewName,

        [Parameter()]
        [String]$ApiVersion = $(Get-AzDevOpsApiVersion | Where-Object { $_ -eq '7.1' } | Select-Object -Last 1)
    )

    $params = @{
        Uri             = 'https://dev.azure.com/{0}/{1}/_apis/wit/tags/{2}?api-version={3}' -f
                            $Organization, $ProjectName, $TagId, $ApiVersion
        Method          = 'PATCH'
        HttpContentType = 'application/json'
        Body            = @{ name = $NewName } | ConvertTo-Json
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod @params)
    }
    catch
    {
        Write-Error "[Update-WITTags] Failed to rename tag '$TagId' to '$NewName' in project '$ProjectName'. Error: $_"
        return $null
    }
}
