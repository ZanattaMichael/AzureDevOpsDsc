
Function Get-AzDoAreaPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$AreaPath,

        [Parameter(Mandatory = $true)]
        [bool]$isInherited,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[Get-AzDoAreaPermission] Started."

    # Define the Descriptor Type and Organization Name
    # https://learn.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference?view=azure-devops
    $SecurityNamespace = 'CSS' # Manages area path object-level permissions.
    $OrganizationName = (Get-AzDoOrganizationName)

    Write-Verbose "[Get-AzDoAreaPermission] Security Namespace: $SecurityNamespace"
    Write-Verbose "[Get-AzDoAreaPermission] Organization Name: $OrganizationName"
    Write-Verbose "[Get-AzDoAreaPermission] Project Name: $ProjectName"


    if ([String]::IsNullOrEmpty($AreaPath)) {

        Write-Warning "[Get-AzDoAreaPermission] AreaPath not specified. Defaulting to top-level Project permissions"
        $AreaPath = $null

    } else {
        Write-Verbose "[Get-AzDoAreaPermission] AreaPath: $AreaPath"
    }

    #
    # Construct a hashtable detailing the group

    $results = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        project = $ProjectName
        areaPath = $AreaPath
        status = $null
        reason = $null
        identifiers = $null
    }

    Write-Verbose "[Get-AzDoAreaPermission] Group result hashtable constructed."
    Write-Verbose "[Get-AzDoAreaPermission] Performing lookup of permissions for the AreaPath."

    # Define the ACL List
    $ACLList = [System.Collections.Generic.List[Hashtable]]::new()

    # Perform a Lookup within the Cache for the Project
    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # If not in cache, fall back to a live API lookup
    if (-not $projectCache)
    {
        Write-Verbose "[Get-AzDoAreaPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $projectCache = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectCache) { Add-CacheItem -Key $ProjectName -Value $projectCache -Type 'LiveProjects' }
    }

    # Test if the Project was found
    if (-not $projectCache)
    {
        Write-Warning "[Get-AzDoAreaPermission] Project not found: $ProjectName"
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "Project not found: $ProjectName"

        return $results
    }

    # Test if the AreaPath was specified
    if ($AreaPath) {
        Write-Verbose "[Get-AzDoAreaPermission] AreaPath Name: $AreaPath is not null."
        # Format the AreaPath to retrieve all of the AreaPath nodes
        $FormattedAreaPaths = Format-AzDoAreaPath -AreaPath $AreaPath -ProjectName $ProjectName | Get-AllAzDoClassificationNodePaths
    } else {
        Write-Verbose "[Get-AzDoAreaPermission] AreaPath Name: $AreaPath is null."
        # If AreaPath is not specified, get the top-level area path
        $FormattedAreaPaths = @("\$ProjectName\Area")
    }

    # Perform a Lookup within the Cache for the AreaPath
    [Array]$AreaPaths = $FormattedAreaPaths | ForEach-Object {
        Write-Verbose "[Get-AzDoAreaPermission] AreaPath: $_"
        # Get the cached item for the AreaPath and add it to the list
        Get-CacheItem -Key $_ -Type 'LiveAreaNodes'
    }

    # If area nodes not in cache, fall back to a live API lookup
    if ($AreaPaths.count -ne $FormattedAreaPaths.Count)
    {
        Write-Verbose "[Get-AzDoAreaPermission] Area path nodes not in cache — falling back to live API lookup."
        $liveNodes = List-DevOpsClassificationNodes -OrganizationName $OrganizationName -ProjectName $ProjectName
        foreach ($node in $liveNodes)
        {
            if ($node.structureType -eq 'area')
            {
                Format-ClassificationNode -Node $node -CacheType 'LiveAreaNodes'
            }
        }

        [Array]$AreaPaths = $FormattedAreaPaths | ForEach-Object {
            Get-CacheItem -Key $_ -Type 'LiveAreaNodes'
        }
    }

    # Ensure that the number of cached area path nodes is the same as the formatted nodes.
    if ($AreaPaths.count -ne $FormattedAreaPaths.Count)
    {
        Write-Warning "[Get-AzDoAreaPermission] The area path nodes do not match the formatted area path nodes."
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "The area path nodes do not match the formatted area path nodes."
        return $results
    }

    # Once the AreaPath is found, we can get the identifiers
    $identifierArr = $AreaPaths | ForEach-Object { $_.identifier }
    # Update the results. This is used to construct regex expressions.
    $results.identifiers = $identifierArr

    #
    # Perform Lookup of the Permissions

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    Write-Verbose "[Get-AzDoAreaPermission] Retrieved namespace: $($namespace.namespaceId)"

    # Add to the ACL Lookup Params
    $results.namespace = $namespace

    # Token-scope the ACL fetch to this area path's classification-node token instead of scanning the
    # entire org-wide CSS namespace. Fall back to the full-namespace fetch if the scoped query returns
    # nothing, so behaviour is never worse than the previous full scan.
    $aclToken = ($identifierArr | ForEach-Object { 'vstfs:///Classification/Node/{0}' -f $_ }) -join ':'
    $ACLLookupParams = @{
        OrganizationName        = $OrganizationName
        SecurityDescriptorId    = $namespace.namespaceId
    }
    if ($aclToken) { $ACLLookupParams.Token = $aclToken }

    # Get the ACL List and format the ACLS
    Write-Verbose "[Get-AzDoAreaPermission] ACL Lookup Params: $($ACLLookupParams | Out-String)"

    # Get the ACLs for the AreaPath
    $DevOpsACLs = Get-DevOpsACL @ACLLookupParams
    if (($null -eq $DevOpsACLs) -and $aclToken) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }

    # Test if the ACLs were found
    if ($DevOpsACLs -eq $null)
    {
        Write-Error "[Get-AzDoAreaPermission] No ACLs were found within the Security Namespace."
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "No ACLs were found within the Security Namespace."
        return $results
    }

    # Convert the ACLs to a formatted ACL
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    # Test if the ACLs were found
    if ($DifferenceACLs -eq $null)
    {
        Write-Warning "[Get-AzDoAreaPermission] No ACLs found for the AreaPath."
        $results.status = [DSCGetSummaryState]::NotFound
        return $results
    }

    # Filter the ACLs to only those matching the specific area path token (always applied).
    $DifferenceACLs = $DifferenceACLs | Where-Object { $_.Token.Type -eq 'AreaPathPermission' } | Where-Object {

        # Check if the current array contains all items in the matching list
        if ($_.token.Identifiers.Count -ne $identifierArr.Count) { return $false }

        # Check if the current array contains all items in the matching list
        foreach ($item in $identifierArr) {
            if ($_.token.Identifiers.identifier -notcontains $item) {
                return $false
            }
        }

        return $true

    }

    Write-Verbose "[Get-AzDoAreaPermission] ACL List retrieved and formatted."

    #
    # Convert the Permissions into an ACL Token

    $params = @{
        Permissions         = $Permissions
        SecurityNamespace   = $SecurityNamespace
        isInherited         = $isInherited
        OrganizationName    = $OrganizationName
        TokenName           = $(($identifierArr | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')
    }

    # Convert the Permissions to an ACL Token
    $ReferenceACLs = ConvertTo-ACL @params

    # Compare the Reference ACLs to the Difference ACLs
    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $results.propertiesChanged = $compareResult.propertiesChanged
    $results.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $results.reason = $compareResult.reason

    Write-Verbose "[Get-AzDoAreaPermission] ACL Token converted."
    Write-Verbose "[Get-AzDoAreaPermission] ACL Token Comparison Result: $($results.status)"

    # Export the ACL List to a file
    $results.ReferenceACLs = $ReferenceACLs
    $results.DifferenceACLs = $DifferenceACLs

    # Write
    Write-Verbose "[Get-AzDoAreaPermission] Result Status: $($results.status)"
    Write-Verbose "[Get-AzDoAreaPermission] Returning Group Result."

    # Return the Group Result
    return $results

}

