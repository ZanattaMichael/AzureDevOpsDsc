Function Set-AzDoWIPTags
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [Alias('WITTagList')]
        [System.String[]]$WorkItemTrackingTagList,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $Organization =  (Get-AzDoOrganizationName)

    if ($null -eq $LookupResult) {
        Throw "The parameter 'LookupResult' cannot be null."
    }

    if ($LookupResult.propertiesChanged.ToAdd.Count -ne 0) {
        # Create the WIT tags
        New-WITTags -Organization $Organization -ProjectName $ProjectName -WorkItemTrackingNames $LookupResult.propertiesChanged.ToAdd
    }

    if ($LookupResult.propertiesChanged.ToDelete.Count -ne 0) {
        # Delete the WIT tags
        Remove-WITTags -Organization $Organization -ProjectName $ProjectName -WorkItemTrackingTagId $LookupResult.propertiesChanged.ToDelete.id
    }

}
