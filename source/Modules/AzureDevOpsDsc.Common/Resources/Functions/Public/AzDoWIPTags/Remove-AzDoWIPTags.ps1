Function Remove-AzDoWIPTags
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

    $Organization =  $Global:DSCAZDO_OrganizationName

    # Create the WIT tags
    Remove-WITTags -Organization $Organization -ProjectName $ProjectName -WorkItemTrackingTagId $LookupResult.propertiesChanged.ToDelete.id

}
