Function New-ClassificationNode {
    param(
        [Parameter(Mandatory)]
        [String]$OrganizationName,

        [Parameter(Mandatory)]
        [String]$ProjectName,

        [Parameter(Mandatory)]
        [ValidateSet('Area', 'Iteration')]
        [String]$StructureType,

        [Parameter()]
        [String]$Path,

        [Parameter(Mandatory)]
        [HashTable]$Body,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    Write-Verbose "[New-ClassificationNode] Started."
    Write-Verbose "[New-ClassificationNode] Organization Name: $OrganizationName"
    Write-Verbose "[New-ClassificationNode] Project Name: $ProjectName"
    Write-Verbose "[New-ClassificationNode] Structure Type: $StructureType"
    Write-Verbose "[New-ClassificationNode] Path Name: $Path"
    Write-Verbose "[New-ClassificationNode] API Version: $ApiVersion"


    $params = @{
        <#
            Construct the Uri using string formatting with the -f operator.
            It includes the API endpoint, group identity, member identity, and the API version.
        #>
        Uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?api-version={4}' -f $OrganizationName,
                                                                                            $ProjectName,
                                                                                            $StructureType,
                                                                                            $Path,
                                                                                            $ApiVersion
        Method = 'POST'
        Body = $Body | ConvertTo-Json
    }

    Write-Verbose "[New-ClassificationNode] Uri: $($params.Uri)"

    try
    {
        <#
            Call the Invoke-AzDevOpsApiRestMethod function with the parameters defined above.
            The "@" symbol is used to pass the hashtable as splatting parameters.
        #>
        Write-Verbose "[New-ClassificationNode] Attempting to invoke REST method to clear ACEs from $Token Token."
        return (Invoke-AzDevOpsApiRestMethod @params)

    }
    catch
    {
        # If an exception occurs, write an error message to the console with details about the issue.
        Write-Error "[New-ClassificationNode] Failed to set ACLs: $($_.Exception.Message)"
    }


}
