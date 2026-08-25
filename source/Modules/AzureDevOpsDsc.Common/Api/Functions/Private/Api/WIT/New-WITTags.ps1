Function New-WITTags {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        # The name of the Azure DevOps organization.
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        # The name of the Azure DevOps project.
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        # The ID of the Tag to delete.
        [Parameter(Mandatory = $true)]
        [Alias('WITTagId')]
        [System.String[]]$WorkItemTrackingNames,

        # Get the latest API version. 7.1 is not supported by the API endpoint.
        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion | Where-Object { $_ -eq '7.1' } | Select-Object -Last 1)
    )

    # Get the Work Item Type Tag ID
    $witTypes = List-WITTypes -Organization $Organization -ProjectName $ProjectName
    if ($null -eq $witTypes -or $witTypes.Count -eq 0)
    {
        Write-Error "[New-WITTag] Failed to retrieve Work Item Types for project '$ProjectName'. Check authentication token and organization settings."
        return $null
    }
    $WorkItemType = $witTypes[0].name

    # Validate the parameters
    $NewWIPTagParams = @{
        # https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/${type}?api-version=7.1
        Uri              = 'https://dev.azure.com/{0}/{1}/_apis/wit/workitems/${2}?api-version={3}' -f $Organization, $ProjectName, $WorkItemType, $ApiVersion
        HttpContentType  =  "application/json-patch+json"
        Method           =  "POST"
        Body             = @(
            @{
                "op" = "add"
                "path" = "/fields/System.Title"
                "from" = $null
                "value" = 'System - POWERSHELL DSC - Temp Work Item for Tag Creation'
            },
            @{
                "op" = "add"
                "path" = "/fields/System.Tags"
                "value" = $WorkItemTrackingNames -join '; '
            }
        ) | ConvertTo-Json
    }

    #
    # Create the Work Item Tag

    try
    {
        # Invoke the Azure DevOps REST API to create the project]
        $createdWorkItem = Invoke-AzDevOpsApiRestMethod @NewWIPTagParams
    }
    catch
    {
        Write-Error "[New-WITTag] Failed to create Work Item Tags for the Azure DevOps Project $ProjectName. Error: $_"
        return $null
    }

    # Validate the parameters
    $DeleteWIPTagParams = @{
        # https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/{id}?api-version=7.1
        Uri              = 'https://dev.azure.com/{0}/{1}/_apis/wit/workitems/{2}?api-version={3}' -f $Organization, $ProjectName, $createdWorkItem.Id, $ApiVersion
        Method           = "DELETE"
    }

    #
    # Delete the Work Item Tag

    try
    {
        # Invoke the Azure DevOps REST API to delete the temporary work item (the tags it
        # created persist project-wide).
        $deleteResult = Invoke-AzDevOpsApiRestMethod @DeleteWIPTagParams
    }
    catch
    {
        Write-Error "[New-WITTag] Failed to delete Work Item Tags for the Azure DevOps Project $ProjectName. Error: $_"
        return $null
    }

    # Azure DevOps has no create-tag API; tags are created only as a side effect of the
    # work item above, and the /wit/tags collection is eventually consistent. Without
    # waiting for the new tags to become listable, a Set that has returned can be followed
    # immediately by a Test that still reads a stale, partial list and reports
    # not-in-desired-state - which is intermittent for a single tag and reliable for
    # several at once. Confirm the tags are observable before returning, with a small,
    # time-boxed retry so a genuinely failed creation still surfaces quickly.
    $deadline = (Get-Date).AddSeconds(30)
    $missing = @($WorkItemTrackingNames)
    do
    {
        $listedNames = @((List-WITTags -Organization $Organization -ProjectName $ProjectName).name)
        $missing = @($WorkItemTrackingNames | Where-Object { $_ -notin $listedNames })
        if ($missing.Count -eq 0) { break }
        Start-Sleep -Seconds 2
    }
    while ((Get-Date) -lt $deadline)

    if ($missing.Count -ne 0)
    {
        Write-Warning "[New-WITTag] Tags not visible via the tags API within the timeout for project '$ProjectName': $($missing -join ', ')"
    }

    return $deleteResult

}
