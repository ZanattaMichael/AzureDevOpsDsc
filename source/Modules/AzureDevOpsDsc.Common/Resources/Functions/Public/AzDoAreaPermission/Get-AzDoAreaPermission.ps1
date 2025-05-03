
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
    $OrganizationName = $Global:DSCAZDO_OrganizationName

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

    $getGroupResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        project = $ProjectName
        areaPath = $AreaPath
        status = $null
        reason = $null
    }

    Write-Verbose "[Get-AzDoAreaPermission] Group result hashtable constructed."
    Write-Verbose "[Get-AzDoAreaPermission] Performing lookup of permissions for the AreaPath."

    # Define the ACL List
    $ACLList = [System.Collections.Generic.List[Hashtable]]::new()

    # Perform a Lookup within the Cache for the Project
    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # Test if the Project was found
    if (-not $projectCache)
    {
        Write-Warning "[Get-AzDoAreaPermission] Project not found: $ProjectName"
        $getGroupResult.status = [DSCGetSummaryState]::Error
        $getGroupResult.reason = "Project not found: $ProjectName"

        return $getGroupResult
    }

    # Test if the AreaPath was specified
    if ($AreaPath) {

        #
        Write-Verbose "[Get-AzDoAreaPermission] AreaPath Name: $AreaPath is not null."

        # Format the AreaPath to retrieve all of the AreaPath nodes
        $AreaPaths = Format-AzDoAreaPath -AreaPath $AreaPath -ProjectName $ProjectName | ForEach-Object {
            # Get the cached item for the AreaPath and add it to the list
            Get-CacheItem -Key $_ -Type 'LiveAreaNodes'
        }

        # Test if the AreaPath was found, however only if the ProjectName was specified
        if ($AreaPaths.count -eq 0)
        {
            Write-Warning "[Get-AzDoAreaPermission] AreaPath not found: $AreaPath"
            $getGroupResult.status = [DSCGetSummaryState]::NotFound
            $getGroupResult.reason = "AreaPath not found: $AreaPath"
            return $getGroupResult
        }

    } else {
        # If AreaPath is not specified, get the top-level area path
        $AreaPaths = @(
            Get-CacheItem -Key "$ProjectName\Area" -Type 'LiveAreaNodes'
        )
    }

    #
    # Perform Lookup of the Permissions

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    Write-Verbose "[Get-AzDoAreaPermission] Retrieved namespace: $($namespace.namespaceId)"

    # Add to the ACL Lookup Params
    $getGroupResult.namespace = $namespace

    $ACLLookupParams = @{
        OrganizationName        = $OrganizationName
        SecurityDescriptorId    = $namespace.namespaceId
    }

    # Get the ACL List and format the ACLS
    Write-Verbose "[Get-AzDoAreaPermission] ACL Lookup Params: $($ACLLookupParams | Out-String)"

    # Get the ACLs for the AreaPath
    $DevOpsACLs = Get-DevOpsACL @ACLLookupParams

    # Test if the ACLs were found
    if ($DevOpsACLs -eq $null)
    {
        Write-Error "[Get-AzDoAreaPermission] No ACLs were found within the Security Namespace."
        $getGroupResult.status = [DSCGetSummaryState]::Error
        $getGroupResult.reason = "No ACLs were found within the Security Namespace."
        return $getGroupResult
    }

    # Convert the ACLs to a formatted ACL
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    # Test if the ACLs were found
    if ($DifferenceACLs -eq $null)
    {
        Write-Warning "[Get-AzDoAreaPermission] No ACLs found for the AreaPath."
        $getGroupResult.status = [DSCGetSummaryState]::NotFound
        return $getGroupResult
    }

    #TODO: NEEDS WORK TO DISTINGUISH BETWEEN TOP LEVEL AND REPOSITORY ACLS

    # Filter the ACLs for the AreaPath
    if (-not $AreaPath) {

        $identifierArr = $areaNodes | ForEach-Object { $_.value.identifier }

        # Construct the AreaPath Token
        $DifferenceACLs = $DifferenceACLs | Where-Object { $_.Token.Type -eq 'AreaPathPermission' } | Where-Object {

            # Check if the current array contains all items in the matching list
            if ($_.Count -ne $identifierArr.Count) { return $false }

            # Check if the current array contains all items in the matching list
            foreach ($item in $identifierArr) {
                if ($_ -notcontains $item) {
                    return $false
                }
            }

            return $true

        }

        # Test if the ACLs were found
        if ($DifferenceACLs -eq $null)
        {
            Write-Warning "[Get-AzDoAreaPermission] No ACLs found for the AreaPath."
            $getGroupResult.status = [DSCGetSummaryState]::Error
            $getGroupResult.reason = "No ACLs found for the AreaPath."
            return $getGroupResult
        }

    }

    #TODO: START WORK HERE

    Write-Verbose "[Get-AzDoAreaPermission] ACL List retrieved and formatted."

    #
    # Convert the Permissions into an ACL Token

    $params = @{
        Permissions         = $Permissions
        SecurityNamespace   = $SecurityNamespace
        isInherited         = $isInherited
        OrganizationName    = $OrganizationName
        TokenName           = $(
                                if (-not $RepositoryName) {
                                    'repoV2\{0}' -f $ProjectName
                                } else {
                                    '[{0}]\{1}' -f $ProjectName, $RepositoryName
                                })
    }

    # Convert the Permissions to an ACL Token
    $ReferenceACLs = ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'GitUnknown' }

    # Compare the Reference ACLs to the Difference ACLs
    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $getGroupResult.propertiesChanged = $compareResult.propertiesChanged
    $getGroupResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getGroupResult.reason = $compareResult.reason

    Write-Verbose "[Get-AzDoAreaPermission] ACL Token converted."
    Write-Verbose "[Get-AzDoAreaPermission] ACL Token Comparison Result: $($getGroupResult.status)"

    # Export the ACL List to a file
    $getGroupResult.ReferenceACLs = $ReferenceACLs
    $getGroupResult.DifferenceACLs = $DifferenceACLs

    # Write
    Write-Verbose "[Get-AzDoAreaPermission] Result Status: $($getGroupResult.status)"
    Write-Verbose "[Get-AzDoAreaPermission] Returning Group Result."

    # Return the Group Result
    return $getGroupResult

}

