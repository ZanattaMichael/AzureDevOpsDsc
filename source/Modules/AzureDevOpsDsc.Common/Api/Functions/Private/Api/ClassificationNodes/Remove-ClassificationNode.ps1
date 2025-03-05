Function Remove-ClassificationNode {
    param(
        [Parameter(Mandatory)]
        [String]$OrganizationName,

        [Parameter(Mandatory)]
        [String]$ProjectName,

        [Parameter(Mandatory)]
        [ValidateSet('Areas', 'Iterations')]
        [String]$StructureType,

        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter()]
        [String]$ReclassificationId,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    Write-Verbose "[Remove-ClassificationNode] Started."
    Write-Verbose "[Remove-ClassificationNode] Organization Name: $OrganizationName"
    Write-Verbose "[Remove-ClassificationNode] Project Name: $ProjectName"
    Write-Verbose "[Remove-ClassificationNode] Structure Type: $StructureType"
    Write-Verbose "[Remove-ClassificationNode] Path: $Path"
    Write-Verbose "[Remove-ClassificationNode] Reclassification Id: $ReclassificationId"
    Write-Verbose "[Remove-ClassificationNode] API Version: $ApiVersion"

    # If the ReclassificationId exists, amend the ReclassificationId to the URI
    if ($ReclassificationId) {
        $Uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?api-version={4}&$reclassifyId={5}' -f $OrganizationName,
                                                                                            $ProjectName,
                                                                                            $StructureType,
                                                                                            $Path,
                                                                                            $ApiVersion,
                                                                                            $ReclassificationId
    } else {
        $Uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?api-version={4}' -f $OrganizationName,
                                                                                            $ProjectName,
                                                                                            $StructureType,
                                                                                            $Path,
                                                                                            $ApiVersion
    }

    $params = @{
        Uri = $Uri
        Method = 'DELETE'
    }

    Write-Verbose "[Remove-ClassificationNode] Uri: $($params.Uri)"

    try
    {
        <#
            Call the Invoke-AzDevOpsApiRestMethod function with the parameters defined above.
            The "@" symbol is used to pass the hashtable as splatting parameters.
        #>
        Write-Verbose "[Remove-ClassificationNode] Attempting to invoke REST method remove classification node:"
        $null = Invoke-AzDevOpsApiRestMethod @params

    }
    catch
    {
        # If an exception occurs, write an error message to the console with details about the issue.
        Write-Error "[Remove-ClassificationNode] Failed to remove classification node: $($_.Exception.Message)"
    }

}
