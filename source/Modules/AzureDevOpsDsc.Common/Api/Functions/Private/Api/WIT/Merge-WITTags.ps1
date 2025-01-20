Function Merge-WITTags {
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

        # Reference Tag Name
        [Parameter(Mandatory = $true)]
        [Alias('WITTagName')]
        [System.String]$ReferenceTagName,

        # Merging Tag Name
        [Parameter(Mandatory = $true)]
        [Alias('WITMergeTagName')]
        [System.String]$MergingTagName,

        # Get the latest API version. 7.1 is not supported by the API endpoint.
        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion | Select-Object -Last 1)
    )




}
