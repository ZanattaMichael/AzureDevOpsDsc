Function Format-ClassificationNode {
    param(
        [Object]$Node,
        [String]$CacheType
    )

    Write-Verbose "[Format-ClassificationNode] Adding node to cache: $($Node.path) with CacheType: $CacheType."

    # Add the current node to the cache
    $cacheParams = @{
        Key = $Node.Path
        Value = @{
            id              = $node.id
            identifier      = $node.identifier
            name            = $node.name
            structureType   = $node.structureType
            path            = $node.path
            url             = $node.url
        }
        Type = $CacheType
        SuppressWarning = $true
    }

    # Add to the cache
    Add-CacheItem @cacheParams

    # If attributes are specified include them into the cache parameters.
    if ($Node.attributes) {

        Write-Verbose "[AzDoAPI_8_DevOpsClassificationNodes] Attributes found. Including attributes."

        $cacheParams.Value.startDate = $Node.attributes.startDate
        $cacheParams.Value.endDate = $Node.attributes.finishDate
    }


    # Check if the node contains children
    if ($Node.hasChildren) {
        Write-Verbose "[Format-ClassificationNode] Node has children, recursing into child nodes."
        # Recurse through each of the children
        ForEach ($childNode in $node.children) {
            Format-ClassificationNode -Node $childNode -CacheType $CacheType
        }
    } else {
        Write-Verbose "[Format-ClassificationNode] Node has no children."
    }
}
