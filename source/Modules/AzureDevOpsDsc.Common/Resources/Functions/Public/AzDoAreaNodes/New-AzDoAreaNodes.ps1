Function New-AzDoAreaNodes
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

    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Iterate through the LookupResult hashtable and process the values.
    # Sort the values to ensure that the parent nodes are created before the child nodes.
    ForEach ($areaPathToAdd in (@($LookupResult.propertiesChanged.ToAdd) | Sort-Object)) {

        Write-Verbose "[New-AzDoAreaNodes] Adding: $($areaPathToAdd)"

        # Switch the path slashes
        $formattedAreaPathToAdd = $areaPathToAdd.Replace('\', '/')

        # Remove the Project and Area prefix from the path
        $removedPrefix = $formattedAreaPathToAdd.Replace("/$ProjectName/Area/", '')
        # Split the path into an array
        $SplitPath = $removedPrefix.Split('/')

        # Construct the parameters for the New-ClassificationNode function
        $params = @{
            OrganizationName = $OrganizationName
            ProjectName = $ProjectName
            StructureType = 'Areas'
            Path = $(
                if ($SplitPath.Count -eq 1) {
                    $null
                }
                else {
                    $SplitPath[0..($SplitPath.Length - 2)] -join '/'
                }
            )
            Body = @{
                name = $SplitPath[-1]
            }
        }

        Write-Verbose "[New-AzDoAreaNodes] Attempting to create Area Node: $($areaPathToAdd)."
        $response = New-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Write-Verbose "[New-AzDoAreaNodes] Successfully created Area Node: $($areaPathToAdd), updating live cache."
            Add-CacheItem -Type 'LiveAreaNodes' -Key $areaPathToAdd -Value $response
        } else {
            Write-Error "[New-AzDoAreaNodes] Failed to create Area Node: $($areaPathToAdd)."
            # Stop and Return
            return
        }

    }

    # Write the updated cache to the global cache and export to the cache file.
    Write-Verbose "[New-AzDoAreaNodes] Updating global cache for LiveAreaNodes."
    Set-CacheObject -Content $Global:AzDoLiveAreaNodes -CacheType 'LiveAreaNodes'
    Refresh-CacheObject -CacheType 'LiveAreaNodes'

    Write-Verbose "[New-AzDoAreaNodes] Function execution completed for Project: $ProjectName."

}
