<#
.SYNOPSIS


.DESCRIPTION

.NOTES
    Author: Michael Zanatta
    Date:

.LINK


.PARAMETER ProjectName

.PARAMETER WorkItemTrackingTagList

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE

#>

[DscResource()]
class AzDoWIPTags : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [Alias('WITTagList')]
    [System.String[]]$WorkItemTrackingTagList

    AzDoWIPTags()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoWIPTags] Get()
    {
        return [AzDoWIPTags]$($this.GetDscCurrentStateProperties())
    }


    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName                 = $CurrentResourceObject.ProjectName
        $properties.WorkItemTrackingTagList     = $CurrentResourceObject.WorkItemTrackingTagList
        $properties.LookupResult                = $CurrentResourceObject.LookupResult
        $properties.Ensure                      = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoWIPTags] Current state properties: $($properties | Out-String)"

        return $properties

    }

}
