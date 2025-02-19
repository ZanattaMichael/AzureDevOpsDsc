Function Remove-AzDoAreaNodes
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

    Write-Verbose "[Remove-AzDoAreaNode] ProjectName $($ProjectName)"

    # Get the ID of the top-level area. This is needed to get the id so all the work items can be reassigned to the top level area.
    $projectArea = $LookupResult.cachedAreaNodes | Where-Object { $_.Key -eq "$ProjectName\Area" }
    $OrganizationName = $Global:DSCAZDO_OrganizationName

    Write-Verbose "[Remove-AzDoAreaNode] projectArea $($projectArea | Out-String)"
    Write-Verbose "[Remove-AzDoAreaNode] AreaPaths $($AreaPaths | Out-String)"

    # Iterate through each of the LookupResult nodes and remove them
    ForEach($node in $LookupResult.ToRemove)
    {
        Write-Verbose "[Remove-AzDoAreaNode] Attempting to remove Area Node: $($node)"
        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = 'Area'
            Path                = $node.path -replace '\\', '/'
            ReclassificationId  = $projectArea.value.id
        }

        Remove-ClassificationNode @params
        Remove-CacheItem -Key "$ProjectName\Area\$($node.path)" -Type 'LiveAreaNodes'

    }

    Write-Verbose "[Remove-AzDoAreaNode] Writing to the updated cache"

    # Write the updated cache to the global cache and export to the cache file.
    Set-CacheObject -Content $Global:AzDoGroup -CacheType 'LiveAreaNodes'

}
