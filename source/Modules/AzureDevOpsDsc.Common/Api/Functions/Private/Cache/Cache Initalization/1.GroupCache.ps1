<#
.SYNOPSIS
Sets the Azure DevOps API group cache.

.DESCRIPTION
This function sets the cache for Azure DevOps API groups. It retrieves the groups using the List-AzDevOpsGroup function and adds them to the cache.

.PARAMETER OrganizationName
The name of the organization. If not provided as a parameter, it uses the global variable $Global:DSCAZDO_OrganizationName.

.EXAMPLE
AzDoAPI_1_GroupCache -OrganizationName "MyOrganization"
#>
Function AzDoAPI_1_GroupCache
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OrganizationName
    )

    # Use a verbose statement to indicate the start of the function.
    Write-Verbose "Starting 'Set-GroupCache' function."

    if (-not $OrganizationName)
    {
        Write-Verbose "No organization name provided as parameter; using global variable."
        $OrganizationName = $Global:DSCAZDO_OrganizationName
    }

    $params = @{
        Organization = $OrganizationName
    }

    try
    {
        Write-Verbose "Calling 'List-DevOpsGroups' with parameters: $($params | Out-String)"
        # Perform an Azure DevOps API request to get the groups

        $groups = List-DevOpsGroups @params

        Write-Verbose "'List-DevOpsGroups' returned a total of $($groups.Count) groups."

        # Iterate through each of the responses and add them to the cache
        foreach ($group in $groups)
        {
            Write-Verbose "Adding group '$($group.PrincipalName)' to cache."
            # Add the group to the cache
            Add-CacheItem -Key $group.PrincipalName -Value $group -Type 'LiveGroups'
        }

        # Export the cache to a file
        Export-CacheObject -CacheType 'LiveGroups' -Content $AzDoLiveGroups
        Write-Verbose "Completed adding groups to cache."

    }
    catch
    {
        Write-Error "An error occurred: $_"
    }

    Write-Verbose "Function 'AzDoAPI_1_GroupCache' completed."
}
