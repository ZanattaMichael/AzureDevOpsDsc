function AzDoAPI_8_DevOpsClassificationNodes {

    [CmdletBinding()]
    param(
        [string]$OrganizationName
    )

    if (-not $OrganizationName)
    {
        Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] No organization name provided as parameter; using global variable."
        $OrganizationName = $Global:DSCAZDO_OrganizationName
    }

    # Enumerate all the projects within the organization
    Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Retrieving live projects from cache."
    $AzDoLiveProjects = Get-CacheObject -CacheType 'LiveProjects'

    # Recurse through each of the Projects
    ForEach ($Project in $AzDoLiveProjects) {

        Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Processing project: $($Project.value.name)."

        # List the Classification Nodes
        Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Listing classification nodes for project: $($Project.value.name)."
        $ClassificationNodes = List-DevOpsClassificationNodes -ProjectName $Project.value.name -OrganizationName $OrganizationName

        # Split the Classification Nodes into Area and Iteration Classification Nodes
        ForEach ($ClassificationNode in $ClassificationNodes) {

            if ($ClassificationNode.structureType -eq 'area') {
                $CacheType = 'LiveAreaNodes'
                Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Found area node: $($ClassificationNode.path)."
            } elseif ($ClassificationNode.structureType -eq 'iteration') {
                $CacheType = 'LiveIterations'
                Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Found iteration node: $($ClassificationNode.path)."
            }

            Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Formatting classification node: $($ClassificationNode.path) as $CacheType."

            # Add the top-level node to the cache
            $cacheParams = @{
                Key = $ClassificationNode.Path
                Value = @{
                    id              = $ClassificationNode.id
                    identifier      = $ClassificationNode.identifier
                    name            = $ClassificationNode.name
                    structureType   = $ClassificationNode.structureType
                    path            = $ClassificationNode.path
                    url             = $ClassificationNode.url
                }
                Type = $CacheType
                SuppressWarning = $true
            }

            # Add to the cache
            Add-CacheItem @cacheParams

            # If there are any children recurse through each of the nodes
            if ($ClassificationNode.hasChildren) {
                ForEach ($childNode in $ClassificationNode.children) {
                    Format-ClassificationNode -Node $childNode -CacheType $CacheType
                }
            }

        }

        # Export the Cache
        Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Exporting area nodes cache."
        Export-CacheObject -CacheType 'LiveAreaNodes' -Content $AzDoLiveAreaNodes

        Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Exporting iterations cache."
        Export-CacheObject -CacheType 'LiveIterations' -Content $AzDoLiveIterations

    }

}
