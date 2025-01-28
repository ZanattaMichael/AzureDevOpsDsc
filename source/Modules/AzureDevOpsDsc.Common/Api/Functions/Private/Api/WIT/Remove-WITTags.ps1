Function Remove-WITTags {
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
        [System.String[]]$WorkItemTrackingTagId,

        # Get the latest API version. 7.1 is not supported by the API endpoint.
        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion | Where-Object { $_ -eq '7.1' } | Select-Object -Last 1)
    )

    # Iterate through each Tag ID and delete it
    ForEach ($TagId in $WorkItemTrackingTagId)
    {
        # Validate the parameters
        $params = @{
            Uri              = 'https://dev.azure.com/{0}/{1}/_apis/wit/tags/{2}?api-version={3}' -f $Organization, $ProjectName, $TagId, $ApiVersion
            Method           = "DELETE"
        }

        try
        {
            # Invoke the Azure DevOps REST API to create the project
            return (Invoke-AzDevOpsApiRestMethod @params)
        }
        catch
        {
            Write-Error "[Delete-WITTags] Failed to delete Work Item Tags for the Azure DevOps Project $ProjectName. Error: $_"
        }
    }

}
