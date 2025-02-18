Function New-AzDoAreaNode
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
    ForEach ($areaPathToAdd in ($LookupResult.ToAdd | Sort-Object)) {

        # Remove the Project and Area prefix from the path
        $removedPrefix = $areaPathToAdd -replace "\\$Project\\Area\\", ''
        # Split the path into an array
        $SplitPath = $removedPrefix -split '\\'

        # Construct the parameters for the New-ClassificationNode function
        $params = @{
            OrganizationName = $OrganizationName
            ProjectName = $ProjectName
            StructureType = 'Area'
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

        Write-Verbose "[New-AzDoAreaNode] Attempting to create Area Node: $($areaPathToAdd)"
        $response = New-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Add-CacheObject -CacheType 'LiveAreaNodes' -Key "$ProjectName\Area\$areaPathToAdd" -Value $response
        }

    }

}
