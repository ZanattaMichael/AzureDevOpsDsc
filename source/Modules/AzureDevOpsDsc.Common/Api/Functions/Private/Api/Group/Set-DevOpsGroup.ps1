<#
.SYNOPSIS
Updates an Azure DevOps group.

.DESCRIPTION
The Set-DevOpsGroup function is used to update an Azure DevOps group by sending a PATCH request to the Azure DevOps REST API.

.PARAMETER ApiUri
The mandatory parameter for the API URI. This should be the base URI of the Azure DevOps organization.

.PARAMETER GroupName
The mandatory parameter for the group name. This specifies the name of the group to be updated.

.PARAMETER GroupDescription
The optional parameter for the group description. This specifies the new description for the group. If not provided, the description will not be modified.

.PARAMETER ApiVersion
The optional parameter for the API version. This specifies the version of the Azure DevOps REST API to use. If not provided, the default API version will be obtained from the Get-AzDevOpsApiVersion function.

.PARAMETER ProjectScopeDescriptor
The optional parameter for the project scope descriptor. This specifies the scope descriptor for the project. If provided, the group will be updated within the specified project scope.

.OUTPUTS
The function returns a PSObject representing the updated group.

.EXAMPLE
Set-DevOpsGroup -ApiUri "https://dev.azure.com/contoso" -GroupName "MyGroup" -GroupDescription "Updated group description"

This example updates the group named "MyGroup" in the Azure DevOps organization "https://dev.azure.com/contoso" with the new description "Updated group description".

#>

# This function is designed to update the description of a group in Azure DevOps.
Function Set-DevOpsGroup
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        # Parameter attribute marks this as a mandatory parameter that the user must supply when calling the function.
        [Parameter(Mandatory = $true, ParameterSetName = 'ProjectScope')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [string]
        $ApiUri, # The URI for the Azure DevOps API.

        [Parameter(Mandatory = $true, ParameterSetName = 'ProjectScope')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [string]
        $GroupName, # The name of the group to be updated.

        # Optional parameter with a default value of $null if not specified by the user.
        [Parameter(ParameterSetName = 'ProjectScope')]
        [Parameter(ParameterSetName = 'Default')]
        [String]
        $GroupDescription = $null, # The new description for the group.

        # Optional parameter that gets the default API version if not specified.
        [Parameter(ParameterSetName = 'ProjectScope')]
        [Parameter(ParameterSetName = 'Default')]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default), # The API version to use for the request.

        # Group Descriptor for the project within which the group exists.
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [String]
        $GroupDescriptor,

        # Optional parameter without a default value.
        [Parameter(Mandatory = $true, ParameterSetName = 'ProjectScope')]
        [String]
        $ProjectScopeDescriptor # Scope descriptor for the project within which the group exists.
    )

    # A hashtable is created to hold parameters that will be used in the REST method invocation.
    $params = @{
        Uri = "{0}/_apis/graph/groups/{1}?api-version={2}" -f $ApiUri, $GroupDescriptor, $ApiVersion # The API endpoint, formatted with the base URI and API version.
        Method = 'Patch' # The HTTP method used for the request, indicating an update operation.
        ContentType = 'application/json-patch+json' # The content type of the request body.
        Body = @(
            @{
                op = "replace" # Operation type in JSON Patch format, here adding a new value.
                path = "/displayName" # The path in the target object to add the new value.
                value = $GroupName # The value to add, which is the new group display name.
            }
            @{
                op = "replace" # Operation type in JSON Patch format, here adding a new value.
                path = "/description" # The path in the target object to add the new value.
                value = $GroupDescription # The value to add, which is the new group description.
            }
        ) | ConvertTo-Json # Convert the hashtable to JSON format for the request body.
    }

    # If ProjectScopeDescriptor is provided, modify the URI to include it in the query parameters.
    if ($ProjectScopeDescriptor) {
        $params.Uri = "{0}/_apis/graph/groups?scopeDescriptor={1}&api-version={2}" -f $ApiUri, $ProjectScopeDescriptor, $ApiVersion
    }

    try
    {
        # Invoke the REST method with the parameters and store the result in $group.
        $group = Invoke-AzDevOpsApiRestMethod @params
        return $group # Return the result of the REST method call.
    }
    catch
    {
        # Write an error message to the console if the REST method call fails.
        Write-Error "Failed to create group: $_"
    }

}
