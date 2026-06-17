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

    $Organization =  (Get-AzDoOrganizationName)

    $Result = @{
        #Reasons = $()
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        status = [DSCGetSummaryState]::Unchanged
    }

    # Get the current state of the WIT tags
    $currentList = List-WITTags -Organization $Organization -ProjectName $ProjectName

    # If the currentList is empty and WorkItemTrackingTagList is empty, set the status to Unchanged
    if (($currentList.count -eq 0) -and ($WorkItemTrackingTagList.count -eq 0)) {
        return $Result
    }

    # If the currentList is empty and WorkItemTrackingTagList is not empty, set the difference operation to Add
    if (($currentList.count -eq 0) -and ($WorkItemTrackingTagList.count -ne 0)) {
        $desiredList = $WorkItemTrackingTagList | ForEach-Object {
            @{
                SideIndicator = '<='
                InputObject = $_
            }
        }

    }
    # If the currentList is not empty and WorkItemTrackingTagList is empty, set the difference operation to Delete
    elseif ($currentList.count -ne 0 -and $WorkItemTrackingTagList.count -eq 0) {
        $desiredList = $currentList | ForEach-Object {
            @{
                SideIndicator = '=>'
                InputObject = $_.name
            }
        }
    }
    # else, compare the current state with the desired state
    else {
        $desiredList = Compare-Object -ReferenceObject $WorkItemTrackingTagList -DifferenceObject $currentList.name -IncludeEqual
    }

    if ($Ensure -eq [Ensure]::Absent) {
        # If Absent was specified, test to see if the items already exist. If so, remove them.

        # Items flagged on the right side are items that are missing in the desired state.
        $toDelete = ($desiredList | Where-Object {
            ($_.SideIndicator -eq '==')
        }).InputObject

    } else {
        # Use the standard Side Indicators

        # Items flagged on the left side are items that are missing in the current state.
        $toAdd = ($desiredList | Where-Object { $_.SideIndicator -eq '<=' }).InputObject
        # Items flagged on the right side are items that are missing in the desired state.
        $toDelete = ($desiredList | Where-Object { $_.SideIndicator -eq '=>' }).InputObject
    }

    # If $toDelete and $toAdd is not empty, set the Ensure property to Present.
    if (($toDelete.count -ne 0) -and ($toAdd.count -ne 0)) {
        $Result.status = [DSCGetSummaryState]::Changed
    }
    # If $toDelete is not empty, set the status to NotFound
    elseif ($toDelete.count -ne 0) {
        $Result.status = [DSCGetSummaryState]::Missing
    }
    # If $toAdd is not empty, set the status to Missing
    elseif ($toAdd.count -ne 0) {
        $Result.status = [DSCGetSummaryState]::NotFound
    }

    # If the Ensure property is set to Present, set the Ensure property to Present.
    $Result.propertiesChanged = @{
        toDelete = $currentList | Where-Object { $_.name -in $toDelete }
        toAdd = $toAdd
    }

    return $Result

}
