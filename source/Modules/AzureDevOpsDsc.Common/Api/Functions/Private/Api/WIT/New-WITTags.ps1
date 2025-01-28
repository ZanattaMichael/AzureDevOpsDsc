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
    $WorkItemType = (List-WITTypes -Organization $Organization -ProjectName $ProjectName)[0].name

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
                "value" = 'DSC Temp Work Item Tag'
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

    return

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
        # Invoke the Azure DevOps REST API to create the project
        return (Invoke-AzDevOpsApiRestMethod @DeleteWIPTagParams)
    }
    catch
    {
        Write-Error "[New-WITTag] Failed to delete Work Item Tags for the Azure DevOps Project $ProjectName. Error: $_"
        return $null
    }

}
