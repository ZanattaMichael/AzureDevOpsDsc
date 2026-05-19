<#
.SYNOPSIS
Removes classification node resources for a specified project.

.DESCRIPTION
The Remove-ClassificationNodeResource function removes classification node resources (either Iterations or Areas) for a specified project in Azure DevOps. It updates the cache and handles reclassification if necessary.

.PARAMETER ProjectName
The name of the project for which the classification node resources are to be removed. This parameter is mandatory.

.PARAMETER NodeType
The type of node to be removed. Valid values are 'Iterations' and 'Areas'. This parameter is mandatory.

.PARAMETER LookupResult
A hashtable containing the lookup results for the nodes to be removed. This parameter is mandatory.

.PARAMETER OrganizationName
A hashtable array containing the organization name. This parameter is mandatory.

.EXAMPLE
Remove-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Iterations" -LookupResult $lookupResult -OrganizationName $organizationName

.EXAMPLE
Remove-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Areas" -LookupResult $lookupResult -OrganizationName $organizationName

.NOTES
This function requires the Azure DevOps module and appropriate permissions to remove classification nodes.

#>
Function Remove-ClassificationNodeResource {
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
        [String]$OrganizationName

    )

    Write-Verbose "[Remove-ClassificationNodeResource] Started processing for Project: $ProjectName."

    $cacheType = $( if ($NodeType -eq 'Iterations') { 'LiveIterations' } else { 'LiveAreaNodes' } )
    $nodePathType = $( if ($NodeType -eq 'Iterations') { 'Iteration' } else { 'Area' } )

    # If the Node type is an area, it's expected to retrive the top-level area path to copy the work items to.
    if ($NodeType -eq 'Areas') {

        $projectAreaId = ($LookupResult.cachedAreaNodes | Where-Object { $_.path -eq "\$ProjectName\Area" }).id

        Write-Verbose "[Remove-ClassificationNodeResource] Retrieved top-level area node for Project: $ProjectName."
        Write-Verbose "[Remove-ClassificationNodeResource] Project ID: $($projectAreaId)"

        # If the ProjectAreaId is missing, log an error and stop.
        if ($null -eq $projectAreaId) {
            Write-Error "[Remove-ClassificationNodeResource] Stopping. Cannot Enumerate ProjectAreaId for \$ProjectName\Area"
            return
        }

    }

    Write-Verbose "[Remove-ClassificationNodeResource] Cache type set to: $cacheType."
    Write-Verbose "[Remove-ClassificationNodeResource] Node path type identified as: $nodePathType."

    # Iterate through each of the LookupResult nodes and remove them
    ForEach($node in (@($LookupResult.propertiesChanged.ToRemove) | Sort-Object -Descending -Property Path)) {

        # Reformat the Path
        $reformat = $node.path.Replace('\', '/')
        $Path = $reformat.Replace("/$ProjectName/$nodePathType/", '')

        Write-Verbose "[Remove-ClassificationNodeResource] Attempting to remove $nodePathType Node: $($node.path)."
        Write-Verbose "[Remove-ClassificationNodeResource] Formatted Path: $Path"

        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = $NodeType
            Path                = $Path
        }

        # If the NodeType is an area, add the ReclassificationId
        if ($NodeType -eq 'Areas') { $params.ReclassificationId = $projectAreaId }

        Write-Verbose "[Remove-ClassificationNodeResource] Parameters prepared for node removal."

        Remove-ClassificationNode @params

        Write-Verbose "[Remove-ClassificationNodeResource] Key To Remove: $($node.path)"
        Remove-CacheItem -Key $node.path -Type $cacheType

        Write-Verbose "[Remove-ClassificationNodeResource] Successfully removed $nodePathType Node: $($node.path)."

    }

    Write-Verbose "[Remove-ClassificationNodeResource] Writing to the updated cache."

    # Write the updated cache to the global cache and export to the cache file.
    Set-CacheObject -Content (Get-Variable -Name "AzDo$cacheType" -Scope Global -ValueOnly) -CacheType $cacheType
    Refresh-CacheObject -CacheType $cacheType

    Write-Verbose "[Remove-ClassificationNodeResource] Function execution completed for Project: $ProjectName."

}
