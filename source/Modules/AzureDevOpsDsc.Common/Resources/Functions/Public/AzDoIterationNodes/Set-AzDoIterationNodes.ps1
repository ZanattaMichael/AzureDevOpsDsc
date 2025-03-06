<#
.SYNOPSIS
    Sets Azure DevOps Iteration Nodes for a specified project.

.DESCRIPTION
    The Set-AzDoIterationNodes function manages Azure DevOps Iteration Nodes by adding, removing, or updating them based on the provided parameters. It ensures the state of iteration nodes in a project.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER IterationAttributes
    A hashtable array specifying the attributes of the iteration nodes. This parameter is optional.

.PARAMETER LookupResult
    A hashtable containing the lookup results for properties to add, remove, or update. This parameter is optional.

.PARAMETER Ensure
    Ensures the state of the iteration nodes. This parameter is optional.

.PARAMETER Force
    A switch parameter to force the execution of the function. This parameter is optional.

.EXAMPLE
    Set-AzDoIterationNodes -ProjectName "MyProject" -IterationAttributes $attributes -LookupResult $lookupResult -Ensure "Present" -Force

    This example sets the iteration nodes for the project "MyProject" with the specified attributes and lookup results, ensuring the state is present and forcing the execution.

.NOTES
    This function retrieves the global organization name from the variable $Global:DSCAZDO_OrganizationName and updates the iteration nodes accordingly. It also updates the live cache and global cache for live iterations.

#>
Function Set-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying area paths
        [Parameter()]
        [HashTable[]]$IterationAttributes,

        # Optional hashtable for lookup results
        [Parameter()]
        [HashTable]$LookupResult,

        # Optional parameter to ensure state
        [Parameter()]
        [Ensure]$Ensure,

        # Switch parameter to force execution
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    # Retrieve the global organization name
    $OrganizationName = $Global:DSCAZDO_OrganizationName

    Write-Verbose "[Set-AzDoIterationNodes] Started"

    # If there are properties to add, call Set-AzDoIterationNodes
    if ($LookupResult.propertiesChanged.toAdd.count -ne 0) {
        Write-Verbose "[Set-AzDoIterationNodes] Properties to add detected."

        $params = @{
            ProjectName = $ProjectName
            NodeType = 'Iterations'
            LookupResult = $LookupResult
            IterationAttributes = $IterationAttributes
            OrganizationName = $Global:DSCAZDO_OrganizationName
        }

        New-ClassificationNodeResource @params
        Write-Verbose "[Set-AzDoIterationNodes] Added new iteration nodes."
    }

    # Iterate through each of the Properties to remove
    if ($LookupResult.propertiesChanged.toRemove.count -ne 0) {
        Write-Verbose "[Set-AzDoIterationNodes] Properties to remove detected."

        $params = @{
            ProjectName = $ProjectName
            NodeType = 'Iterations'
            LookupResult = $LookupResult
            OrganizationName = $Global:DSCAZDO_OrganizationName
        }

        Remove-ClassificationNodeResource @params
        Write-Verbose "[Set-AzDoIterationNodes] Removed iteration nodes."
    }

    # Iterate through each of the toUpdate properties.
    ForEach ($node in $LookupResult.propertiesChanged.toUpdate) {

        Write-Verbose "[Set-AzDoIterationNodes] Properties to update detected for node: $($node.Path)."

        # Switch the path slashes
        $areaPath = $node.Path.Replace('\', '/')
        # Remove the Project and Area prefix from the path
        $removedPrefix = $areaPath.Replace("/$ProjectName/Iteration/", '')
        # Split the path into an array
        $SplitPath = $removedPrefix.Split('/')

        Write-Verbose "[Set-AzDoIterationNodes] Area Path $areaPath"
        Write-Verbose "[Set-AzDoIterationNodes] Removed Prefix: $removedPrefix"
        Write-Verbose "[Set-AzDoIterationNodes] StartDate $($node.StartDate)"
        Write-Verbose "[Set-AzDoIterationNodes] EndDate $($node.EndDate)"

        # Define the parameters
        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = 'Iterations'
            Path = $(
                if ($SplitPath.Count -eq 1) {
                    $SplitPath[-1]
                }
                else {
                    $SplitPath[0..($SplitPath.Length - 2)] -join '/'
                }
            )
            Body = @{
                attributes = @{}
            }
        }

        #TODO: more work is needed here

        # If there is a startdate and endDate update the body.
        if (($node.StartDate) -or ($node.EndDate)) {
            Write-Verbose "[Set-AzDoIterationNodes] Updating startDate and finishDate."
            $params.Body.attributes.startDate  = (Get-Date $node.StartDate).ToString('yyyy-MM-ddT00:00:00Z')
            $params.Body.attributes.finishDate = (Get-Date $node.EndDate).ToString('yyyy-MM-ddT00:00:00Z')
        } else {
            Write-Verbose "[Set-AzDoIterationNodes] Clearing startDate and finishDate."
            $params.Body.attributes.startDate  = $null
            $params.Body.attributes.finishDate = $null
        }

        Write-Verbose "[Set-AzDoIterationNodes] Attempting to update Iteration Node: $($node.Path)."
        $response = Update-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Write-Verbose "[Set-AzDoIterationNodes] Successfully updated Iteration Node: $($node.Path), updating live cache."
            # Remove the cache item
            Remove-CacheItem -Key $node.Path -Type 'LiveIterations'
            Add-CacheItem -Type 'LiveIterations' -Key $node.Path -Value $response
        } else {
            Write-Error "[Set-AzDoIterationNodes] Failed to update Iteration Node: $($node.Path)."
            # Stop and Return
            return
        }
    }

    # Write the updated cache to the global cache and export to the cache file.
    Write-Verbose "[Set-AzDoIterationNodes] Updating global cache for LiveIterations."
    Set-CacheObject -Content $Global:AzDoLiveIterations -CacheType 'LiveIterations'
    Refresh-CacheObject -CacheType 'LiveIterations'

    Write-Verbose "[Set-AzDoIterationNodes] Function execution completed for Project: $ProjectName."
}
