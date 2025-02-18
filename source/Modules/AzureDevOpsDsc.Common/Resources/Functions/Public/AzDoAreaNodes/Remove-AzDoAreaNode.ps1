Function Remove-AzDoAreaNode
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [System.String[]]$AreaPaths,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    # Get the ID of the top-level area. This is needed to get the id so all the work items can be reassigned to the top level area.
    $projectArea = $LookupResult.cachedAreaNodes | Where-Object { $_.Key -eq "$ProjectName\Area" }

    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Iterate through each of the LookupResult nodes and remove them
    ForEach($node in $LookupResult.ToRemove)
    {
        Write-Verbose "[Remove-AzDoAreaNode] Attempting to remove Area Node: $($node)"
        $params = @{
            OrganizationName = $OrganizationName
            ProjectName
            StructureType = 'Area'
            Path = $node
            ReclassificationId = $projectArea.value.id
        }

        Remove-ClassificationNode @params

        # Remove the node from the live cache
        Remove-CacheObject -CacheType 'LiveAreaNodes' -Key "$ProjectName\Area\$node"
    }



}
