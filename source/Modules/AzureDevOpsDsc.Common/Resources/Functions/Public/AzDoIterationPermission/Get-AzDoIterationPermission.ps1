
Function Get-AzDoIterationPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$IterationPath,

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

    Write-Verbose "[Get-AzDoIterationPermission] Started."

    # Define the Descriptor Type and Organization Name
    # https://learn.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference?view=azure-devops
    $SecurityNamespace = 'Iteration' # Manages Iteration path object-level permissions.
    $OrganizationName = $Global:DSCAZDO_OrganizationName

    Write-Verbose "[Get-AzDoIterationPermission] Security Namespace: $SecurityNamespace"
    Write-Verbose "[Get-AzDoIterationPermission] Organization Name: $OrganizationName"
    Write-Verbose "[Get-AzDoIterationPermission] Project Name: $ProjectName"


    if ([String]::IsNullOrEmpty($IterationPath)) {

        Write-Warning "[Get-AzDoIterationPermission] IterationPath not specified. Defaulting to top-level Project permissions"
        $IterationPath = $null

    } else {
        Write-Verbose "[Get-AzDoIterationPermission] IterationPath: $IterationPath"
    }

    #
    # Construct a hashtable detailing the group

    $results = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        project = $ProjectName
        IterationPath = $IterationPath
        status = $null
        reason = $null
        identifiers = $null
    }

    Write-Verbose "[Get-AzDoIterationPermission] Group result hashtable constructed."
    Write-Verbose "[Get-AzDoIterationPermission] Performing lookup of permissions for the IterationPath."

    # Define the ACL List
    $ACLList = [System.Collections.Generic.List[Hashtable]]::new()

    # Perform a Lookup within the Cache for the Project
    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # Test if the Project was found
    if (-not $projectCache)
    {
        Write-Warning "[Get-AzDoIterationPermission] Project not found: $ProjectName"
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "Project not found: $ProjectName"

        return $results
    }

    # Test if the IterationPath was specified
    if ($IterationPath) {
        Write-Verbose "[Get-AzDoIterationPermission] IterationPath Name: $IterationPath is not null."
        # Format the IterationPath to retrieve all of the IterationPath nodes
        $FormattedIterationPaths = Format-AzDoIterationPath -Iteration $IterationPath -ProjectName $ProjectName | Get-AllAzDoClassificationNodePaths
    } else {
        Write-Verbose "[Get-AzDoIterationPermission] IterationPath Name: $IterationPath is null."
        # If IterationPath is not specified, get the top-level Iteration path
        $FormattedIterationPaths = @("\$ProjectName\Iteration")
    }

    $FormattedIterationPaths | Export-Clixml C:\Temp\export.clixml

    # Perform a Lookup within the Cache for the IterationPath
    [Array]$IterationPaths = $FormattedIterationPaths | ForEach-Object {
        Write-Verbose "[Get-AzDoIterationPermission] IterationPath: $_"
        # Get the cached item for the IterationPath and add it to the list
        Get-CacheItem -Key $_ -Type 'LiveIterations'
    }

    # Ensure that the number of cached iteration path nodes is the same as the formatted nodes.
    if ($IterationPaths.count -ne $FormattedIterationPaths.Count)
    {
        Write-Warning "[Get-AzDoIterationPermission] The iteration path nodes do not match the formatted iteration path nodes."
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "The iteration path nodes do not match the formatted iteration path nodes."
        return $results
    }

    # Once the IterationPath is found, we can get the identifiers
    $identifierArr = $IterationPaths | ForEach-Object { $_.identifier }
    # Update the results. This is used to construct regex expressions.
    $results.identifiers = $identifierArr

    #
    # Perform Lookup of the Permissions

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    Write-Verbose "[Get-AzDoIterationPermission] Retrieved namespace: $($namespace.namespaceId)"

    # Add to the ACL Lookup Params
    $results.namespace = $namespace

    $ACLLookupParams = @{
        OrganizationName        = $OrganizationName
        SecurityDescriptorId    = $namespace.namespaceId
    }

    # Get the ACL List and format the ACLS
    Write-Verbose "[Get-AzDoIterationPermission] ACL Lookup Params: $($ACLLookupParams | Out-String)"

    # Get the ACLs for the IterationPath
    $DevOpsACLs = Get-DevOpsACL @ACLLookupParams

    # Test if the ACLs were found
    if ($DevOpsACLs -eq $null)
    {
        Write-Error "[Get-AzDoIterationPermission] No ACLs were found within the Security Namespace."
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "No ACLs were found within the Security Namespace."
        return $results
    }

    # Convert the ACLs to a formatted ACL
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    # Filter the ACLs for the IterationPath
    # Both the IterationPath and DifferenceACLs must be specified.
    if (($IterationPath) -and ($DifferenceACLs)) {

        # Construct the IterationPath Token
        $DifferenceACLs = $DifferenceACLs | Where-Object { $_.Token.Type -eq 'IterationPathPermission' } | Where-Object {

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

        # Test if the ACLs were found
        #if ($null -eq $DifferenceACLs)
        #{
        #    Write-Warning "[Get-AzDoIterationPermission] No ACLs found for the IterationPath."
        #    $results.status = [DSCGetSummaryState]::Error
        #    $results.reason = "No ACLs found for the IterationPath."
        #    return $results
        #}

    }

    Write-Verbose "[Get-AzDoIterationPermission] ACL List retrieved and formatted."
    Write-Verbose "[Get-AzDoIterationPermission] Difference ACLs Count: $($DifferenceACLs.Count)"

    #
    # Convert the Permissions into an ACL Token

    $params = @{
        Permissions         = $Permissions
        SecurityNamespace   = $SecurityNamespace
        isInherited         = $isInherited
        OrganizationName    = $OrganizationName
        TokenName           = $(($identifierArr | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')
    }

    $params | Export-Clixml C:\Temp\params_convertoacl.xml

    # Convert the Permissions to an ACL Token
    $ReferenceACLs = ConvertTo-ACL @params

    # Compare the Reference ACLs to the Difference ACLs
    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $results.propertiesChanged = $compareResult.propertiesChanged
    $results.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $results.reason = $compareResult.reason

    Write-Verbose "[Get-AzDoIterationPermission] ACL Token converted."
    Write-Verbose "[Get-AzDoIterationPermission] ACL Token Comparison Result: $($results.status)"

    # Export the ACL List to a file
    $results.ReferenceACLs = $ReferenceACLs
    $results.DifferenceACLs = $DifferenceACLs

    # Write
    Write-Verbose "[Get-AzDoIterationPermission] Result Status: $($results.status)"
    Write-Verbose "[Get-AzDoIterationPermission] Returning Group Result."

    # Return the Group Result
    return $results

}

