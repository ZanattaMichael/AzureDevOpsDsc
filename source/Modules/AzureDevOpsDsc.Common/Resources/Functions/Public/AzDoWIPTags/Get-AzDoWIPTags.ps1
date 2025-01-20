Function Get-AzDoWIPTags
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

    # Get the current state of the WIT tags

    # Match the current state of the WIT tags with the desired state.

    # Items that are missing in the current state, check if it has been misspelled or had additional whitespaces.
    # Also recheck to see if there are other items that are missing that also matches the misspelled or additional whitespaces.
    # - These tags will be


    # If the current state does not match the desired state, return the current state and the desired state.

}
