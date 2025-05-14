<#
.SYNOPSIS
Retrieves the permissions for a specified Azure DevOps group.

.DESCRIPTION
The Get-AzDoGroupProjectPermission function retrieves the permissions for a specified Azure DevOps group.
It performs a lookup within the cache for the group and its associated project, retrieves the
security namespace, and constructs a hashtable detailing the group. It then performs a lookup
of the permissions for the group, formats the ACLs, and compares the reference ACLs to the
difference ACLs to determine any changes.

.PARAMETER GroupName
The name of the Azure DevOps group. This parameter is mandatory.

.PARAMETER isInherited
A boolean value indicating whether the permissions are inherited. This parameter is mandatory.

.PARAMETER Permissions
An array of hashtables representing the permissions to be checked. This parameter is optional.

.PARAMETER LookupResult
A hashtable representing the lookup result. This parameter is optional.

.PARAMETER Ensure
Specifies the desired state of the group permissions. This parameter is optional.

.PARAMETER Force
A switch parameter to force the operation. This parameter is optional.

.OUTPUTS
System.Management.Automation.PSObject[]
Returns a hashtable detailing the group permissions, including the reference ACLs, difference ACLs,
properties changed, status, and reason.

.EXAMPLE
PS C:\> Get-AzDoGroupProjectPermission -GroupName "ProjectName\GroupName" -isInherited $true

Retrieves the permissions for the specified Azure DevOps group with inheritance.

#>

Function Get-AzDoGroupProjectPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GroupName,

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

    Write-Verbose "[Get-AzDoGroupProjectPermission] Started."

    # Define the Descriptor Type and Organization Name
    $SecurityNamespace = 'Identity'
    $OrganizationName = $Global:DSCAZDO_OrganizationName
    # Split the Group Name
    $split = $GroupName.Split('\').Split('/')

    # Test if the Group Name is valid
    if ($split.Count -ne 2)
    {
        Write-Warning "[Get-AzDoGroupProjectPermission] Invalid Group Name: $GroupName"
        return
    }

    # Define the Project and Group Name
    $ProjectName = $split[0].Replace('[', '').Replace(']', '')
    $GroupName = $split[1]

    # If the Project Name contains 'organization'. Update the Project Name

    Write-Verbose "[Get-AzDoGroupProjectPermission] Security Namespace: $SecurityNamespace"
    Write-Verbose "[Get-AzDoGroupProjectPermission] Organization Name: $OrganizationName"

    #
    # Construct a hashtable detailing the group

    $getGroupResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        project = $ProjectName
        groupName = $GroupName
        status = $null
        reason = $null
    }

    Write-Verbose "[Get-AzDoGroupProjectPermission] Group result hashtable constructed."
    Write-Verbose "[Get-AzDoGroupProjectPermission] Performing lookup of permissions for the group."

    # Define the ACL List
    $ACLList = [System.Collections.Generic.List[Hashtable]]::new()

    # Perform a Lookup within the Cache for the Group
    $group = Get-CacheItem -Key $('[{0}]\{1}' -f $ProjectName, $GroupName) -Type 'LiveGroups'
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # Test if the Group was found
    if (-not $group)
    {
        Throw "[Get-AzDoGroupProjectPermission] Group not found: $('[{0}]\{1}' -f $ProjectName, $GroupName)"
        return
    }

    #
    # Perform Lookup of the Permissions for the Group

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    Write-Verbose "[Get-AzDoGroupProjectPermission] Retrieved namespace: $($namespace.namespaceId)"

    # Add to the ACL Lookup Params
    $getGroupResult.namespace = $namespace

    $ACLLookupParams = @{
        OrganizationName        = $OrganizationName
        SecurityDescriptorId    = $namespace.namespaceId
    }

    # Get the ACL List and format the ACLS
    Write-Verbose "[Get-AzDoGroupProjectPermission] ACL Lookup Params: $($ACLLookupParams | Out-String)"

    $DifferenceACLs = Get-DevOpsACL @ACLLookupParams | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName
    $DifferenceACLs = $DifferenceACLs | Where-Object {
        ($_.Token.Type -eq 'GroupPermission') -and
        ($_.Token.GroupId -eq $group.originId) -and
        ($_.Token.ProjectId -eq $project.id)
    }

    #
    # Iterate through each of the Permissions and append the permission identity if it contains 'Self' or 'This'
    forEach ($Permission in $Permissions)
    {
        if ($Permission.Identity -in 'self', 'this')
        {
            $Permission.Identity = '[{0}]\{1}' -f $ProjectName, $GroupName
        }
    }

    Write-Verbose "[Get-AzDoGroupProjectPermission] ACL List retrieved and formatted."

    #
    # Convert the Permissions into an ACL Token

    $params = @{
        Permissions         = $Permissions
        SecurityNamespace   = $SecurityNamespace
        isInherited         = $isInherited
        OrganizationName    = $OrganizationName
        TokenName           = '{0}\\{1}' -f $project.id, $group.id
    }

    # Convert the Permissions to an ACL Token
    $ReferenceACLs = ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'GroupUnknown' }

    # if the ACEs are empty, skip
    if ($ReferenceACLs.aces.Count -eq 0)
    {
        Write-Verbose "[Get-AzDoGroupProjectPermission] No ACEs found for the group."
        return
    }

    # Compare the Reference ACLs to the Difference ACLs
    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $getGroupResult.propertiesChanged = $compareResult.propertiesChanged
    $getGroupResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getGroupResult.reason = $compareResult.reason

    # Export the ACL List to a file
    $getGroupResult.ReferenceACLs = $ReferenceACLs
    $getGroupResult.DifferenceACLs = $DifferenceACLs

    # Write
    Write-Verbose "[Get-AzDoGroupProjectPermission] Result Status: $($getGroupResult.status)"
    Write-Verbose "[Get-AzDoGroupProjectPermission] Returning Group Result."

    # Return the Group Result
    return $getGroupResult

}

