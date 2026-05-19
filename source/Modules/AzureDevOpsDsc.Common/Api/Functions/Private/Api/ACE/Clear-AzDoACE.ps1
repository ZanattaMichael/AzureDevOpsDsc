<#
.SYNOPSIS
Clears Access Control Entries (ACEs) for a specified security namespace in Azure DevOps.

.DESCRIPTION
The Clear-AzDoACE function removes ACEs from a specified security namespace in Azure DevOps.
It takes the organization name, security namespace ID, and a difference ACLs object as input parameters.
The function constructs a URI for the Azure DevOps REST API and invokes the API to clear the ACEs.

.PARAMETER OrganizationName
The name of the Azure DevOps organization.

.PARAMETER SecurityNamespaceID
The ID of the security namespace from which ACEs will be cleared.

.PARAMETER DifferenceACLs
An object containing the difference ACLs, including the token and subdescriptors.

.PARAMETER ApiVersion
The API version to use for the Azure DevOps REST API. Defaults to the version returned by Get-AzDevOpsApiVersion.

.EXAMPLE
Clear-AzDoACE -OrganizationName "MyOrganization" -SecurityNamespaceID "12345" -DifferenceACLs $aclObject

This example clears the ACEs for the specified security namespace in the "MyOrganization" Azure DevOps organization.

.NOTES
The function uses the Invoke-AzDevOpsApiRestMethod to call the Azure DevOps REST API.
#>
Function Clear-AzDoACE {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [string]$SecurityNamespaceID,

        [Parameter(Mandatory = $true)]
        [Object]$DifferenceACLs,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    Write-Verbose "[Clear-AzDoACE] Started."
    Write-Verbose "[Clear-AzDoACE] Organization Name: $OrganizationName"
    Write-Verbose "[Clear-AzDoACE] Security Namespace ID: $SecurityNamespaceID"
    Write-Verbose "[Clear-AzDoACE] Difference ACLs: $($DifferenceACLs | ConvertTo-Json)"

    $Token = $DifferenceACLs.token._token
    # Define a hashtable to store parameters for the Invoke-AzDevOpsApiRestMethod function.

    $SubDescriptors = $DifferenceACLs.aces.Identity.value.ACLIdentity.descriptor

    # If there are no subdescriptors, no work is required - skip!
    if (-not $SubDescriptors)
    {
        Write-Verbose "[Clear-AzDoACE] No subdescriptors found. Skipping."
        return
    }

    # Join the subdescriptors into a comma-separated string.
    $SubDescriptors = $SubDescriptors -join ','

    $params = @{
        <#
            Construct the Uri using string formatting with the -f operator.
            It includes the API endpoint, group identity, member identity, and the API version.
        #>

        Uri = 'https://dev.azure.com/{0}/_apis/accesscontrolentries/{1}?token={2}&descriptors={3}&api-version={4}' -f $OrganizationName,
                                                                                            $SecurityNamespaceID,
                                                                                            $Token,
                                                                                            $SubDescriptors,
                                                                                            $ApiVersion
        # Set the method to PUT.
        Method = 'DELETE'
    }

    Write-Verbose "[Clear-AzDoACE] Uri: $($params.Uri)"

    try
    {
        <#
            Call the Invoke-AzDevOpsApiRestMethod function with the parameters defined above.
            The "@" symbol is used to pass the hashtable as splatting parameters.
        #>
        Write-Verbose "[Clear-AzDoACE] Attempting to invoke REST method to clear ACEs from $Token Token."
        $null = Invoke-AzDevOpsApiRestMethod @params

    }
    catch
    {
        # If an exception occurs, write an error message to the console with details about the issue.
        Write-Error "[Clear-AzDoACE] Failed to set ACLs: $($_.Exception.Message)"
    }

}
