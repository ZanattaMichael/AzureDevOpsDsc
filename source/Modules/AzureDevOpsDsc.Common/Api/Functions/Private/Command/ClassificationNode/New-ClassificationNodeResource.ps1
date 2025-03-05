<#
.SYNOPSIS
Creates a new classification node resource in Azure DevOps.

.DESCRIPTION
The New-ClassificationNodeResource function creates a new classification node resource (either Iteration or Area) in Azure DevOps based on the provided parameters. It processes each node in the LookupResult, constructs the necessary parameters, and calls the New-ClassificationNode function to create the node. If the node is successfully created, it updates the live cache and the global cache.

.PARAMETER ProjectName
Specifies the name of the project. This parameter is mandatory.

.PARAMETER NodeType
Specifies the type of node to create. Valid values are 'Iterations' and 'Areas'. This parameter is mandatory.

.PARAMETER LookupResult
Specifies the lookup result containing the nodes to be added. This parameter is mandatory.

.PARAMETER OrganizationName
Specifies the name of the organization. This parameter is mandatory.

.PARAMETER IterationAttributes
Specifies optional attributes for iteration paths. This parameter is optional.

.EXAMPLE
PS> New-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Iterations" -LookupResult $lookupResult -OrganizationName $organizationName

Creates new iteration nodes in the specified project and organization based on the provided lookup result.

.EXAMPLE
PS> New-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Areas" -LookupResult $lookupResult -OrganizationName $organizationName

Creates new area nodes in the specified project and organization based on the provided lookup result.

.NOTES
This function requires the presence of the New-ClassificationNode, Add-CacheItem, Set-CacheObject, and Refresh-CacheObject functions.

#>
Function New-ClassificationNodeResource {
    param(
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory)]
        [ValidateSet('Iterations','Areas')]
        [String]$NodeType,

        [Parameter(Mandatory)]
        [HashTable]$LookupResult,

        [Parameter(Mandatory)]
        [String]$OrganizationName,

        # Optional parameter for specifying iteration paths
        [Parameter()]
        [HashTable[]]$IterationAttributes

    )

    Write-Verbose "[New-ClassificationNodeResource] Started"

    $cacheType = $( if ($NodeType -eq 'Iterations') { 'LiveIterations' } else { 'AzDoLiveAreaNodes' } )
    $nodePathType = $( if ($NodeType -eq 'Iterations') { 'Iteration' } else { 'Area' } )

    $LookupResult.propertiesChanged | Export-CLixml 'C:\Temp\propertiesChanged.clixml'

    # Iterate Through Each of the LookupResult ToAdd Properties
    ForEach ($node in ($LookupResult.propertiesChanged.ToAdd | Sort-Object -Property Path)) {

        # Switch the path slashes
        $areaPath = $node.Path.Replace('\', '/')
        # Remove the Project and Area prefix from the path
        $removedPrefix = $areaPath.Replace("/$ProjectName/$nodePathType/", '')
        # Split the path into an array
        $SplitPath = $removedPrefix.Split('/')

        Write-Verbose "[New-ClassificationNodeResource] Processing node with path: $($node.Path)."
        Write-Verbose "[New-ClassificationNodeResource] Converted area path: $areaPath."
        Write-Verbose "[New-ClassificationNodeResource] Removed prefix path: $removedPrefix."
        Write-Verbose "[New-ClassificationNodeResource] Split path components: $($SplitPath -join ', ')."

        # Define the parameters
        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = $NodeType
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

        Write-Verbose "[New-ClassificationNodeResource] Attempting to create '$NodeType' Node: $($node.Path)."

        # If there is a startdate and endDate update the body.
        if (($NodeType -eq 'Iterations') -and ($node.EndDate -and $node.StartDate)) {
            $params.Body.attributes = @{
                startDate  = (Get-Date $node.StartDate).ToString('yyyy-MM-ddT00:00:00Z')
                finishDate = (Get-Date $node.EndDate).ToString('yyyy-MM-ddT00:00:00Z')
            }

            Write-Verbose "[New-ClassificationNodeResource] startDate: $($params.Body.attributes.startDate)."
            Write-Verbose "[New-ClassificationNodeResource] finishDate: $($params.Body.attributes.finishDate)."
        }

        $response = New-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Write-Verbose "[New-ClassificationNodeResource] Successfully created Iteration Node: $($node.Path), updating live cache."
            Add-CacheItem -Type $cacheType -Key $node.Path -Value $response
        } else {
            Write-Error "[New-ClassificationNodeResource] Failed to create Iteration Node: $($node.Path)."
            # Stop and Return
            return
        }

    }

    # Write the updated cache to the global cache and export to the cache file.
    Write-Verbose "[New-ClassificationNodeResource] Updating global cache for $cacheType."
    Set-CacheObject -Content (Get-Variable -Name "AzDo$cacheType" -Scope Global -ValueOnly) -CacheType $cacheType
    Refresh-CacheObject -CacheType $cacheType

    Write-Verbose "[New-ClassificationNodeResource] Function execution completed for Project: $ProjectName."

}
