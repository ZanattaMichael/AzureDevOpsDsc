Function Update-ClassificationNode {
    param(
        [Parameter(Mandatory)]
        [String]$OrganizationName,

        [Parameter(Mandatory)]
        [String]$ProjectName,

        [Parameter(Mandatory)]
        [ValidateSet('Areas', 'Iterations')]
        [String]$StructureType,

        [Parameter()]
        [String]$Path,

        [Parameter(Mandatory)]
        [HashTable]$Body,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    Write-Verbose "[Update-ClassificationNode] Started."
    Write-Verbose "[Update-ClassificationNode] Organization Name: $OrganizationName"
    Write-Verbose "[Update-ClassificationNode] Project Name: $ProjectName"
    Write-Verbose "[Update-ClassificationNode] Structure Type: $StructureType"
    Write-Verbose "[Update-ClassificationNode] Path: $Path"
    Write-Verbose "[Update-ClassificationNode] API Version: $ApiVersion"


    $params = @{
        Uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?api-version={4}' -f $OrganizationName,
                                                                                            $ProjectName,
                                                                                            $StructureType,
                                                                                            $Path,
                                                                                            $ApiVersion
        Method = 'PATCH'
        Body = $Body | ConvertTo-Json
    }

    Write-Verbose "[Update-ClassificationNode] Uri: $($params.Uri)"

    try
    {
        <#
            Call the Invoke-AzDevOpsApiRestMethod function with the parameters defined above.
            The "@" symbol is used to pass the hashtable as splatting parameters.
        #>
        Write-Verbose "[Update-ClassificationNode] Attempting to invoke REST method to update classification node:"
        $response = Invoke-AzDevOpsApiRestMethod @params

    }
    catch
    {
        # If an exception occurs, write an error message to the console with details about the issue.
        Write-Error "[Update-ClassificationNode] Failed to update the classification node: $($_.Exception.Message)"
    }

    return $response

}
