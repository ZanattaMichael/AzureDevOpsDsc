<#
.SYNOPSIS
Retrieves the permissions for a specified Azure DevOps group.

.DESCRIPTION
The Get-AzDoGroupPermission function retrieves the permissions for a specified Azure DevOps group.
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
PS C:\> Get-AzDoGroupPermission -GroupName "ProjectName\GroupName" -isInherited $true

Retrieves the permissions for the specified Azure DevOps group with inheritance.

#>

Function Get-AzDoGroupPermission
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

    Write-Verbose "[Get-AzDoGroupPermission] Started."

    # Define the Descriptor Type and Organization Name
    $SecurityNamespace = 'Identity'
    $OrganizationName = (Get-AzDoOrganizationName)
    # Split the Group Name
    $split = $GroupName.Split('\').Split('/')

    # Test if the Group Name is valid
    if ($split.Count -ne 2)
    {
        Write-Warning "[Get-AzDoGroupPermission] Invalid Group Name: $GroupName"
        return
    }

    # Define the Project and Group Name
    $ProjectName = $split[0].Replace('[', '').Replace(']', '')
    $GroupName = $split[1]

    # If the Project Name contains 'organization'. Update the Project Name

    Write-Verbose "[Get-AzDoGroupPermission] Security Namespace: $SecurityNamespace"
    Write-Verbose "[Get-AzDoGroupPermission] Organization Name: $OrganizationName"

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

    Write-Verbose "[Get-AzDoGroupPermission] Group result hashtable constructed."
    Write-Verbose "[Get-AzDoGroupPermission] Performing lookup of permissions for the group."

    # Define the ACL List
    $ACLList = [System.Collections.Generic.List[Hashtable]]::new()

    # Perform a Lookup within the Cache for the Group
    $group = Get-CacheItem -Key $('[{0}]\{1}' -f $ProjectName, $GroupName) -Type 'LiveGroups'
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # If not in cache (e.g. group created after last cache init), fall back to a live REST lookup
    if (-not $group)
    {
        Write-Verbose "[Get-AzDoGroupPermission] Group not found in cache — falling back to live API lookup."
        $allGroups = List-DevOpsGroups -Organization $OrganizationName
        $group = $allGroups | Where-Object { $_.principalName -eq $('[{0}]\{1}' -f $ProjectName, $GroupName) } | Select-Object -First 1
        if ($group)
        {
            # Enrich the group with its ACL identity before caching. The init-time cache guarantees every
            # LiveGroups entry carries a .value.ACLIdentity (used downstream by Find-Identity ->
            # ConvertTo-ACLHashtable to key ACEs by descriptor). Caching the raw group here would poison
            # the cache: a later Find-Identity principalName hit would return an identity whose
            # ACLIdentity.descriptor is null, crashing ConvertTo-ACLHashtable ("key cannot be null").
            try
            {
                $aclIdentitySource = Get-DevOpsDescriptorIdentity -OrganizationName $OrganizationName -SubjectDescriptor $group.descriptor

                $aclIdentity = [PSCustomObject]@{
                    id                  = $aclIdentitySource.id
                    descriptor          = $aclIdentitySource.descriptor
                    subjectDescriptor   = $aclIdentitySource.subjectDescriptor
                    providerDisplayName = $aclIdentitySource.providerDisplayName
                    isActive            = $aclIdentitySource.isActive
                    isContainer         = $aclIdentitySource.isContainer
                }
                $group | Add-Member -MemberType NoteProperty -Name 'ACLIdentity' -Force -Value $aclIdentity

                Add-CacheItem -Key $group.principalName -Value $group -Type 'LiveGroups' -SuppressWarning

                # Register in the descriptor index so a later descriptor search resolves from the index.
                $descriptorIndexParams = @{
                    AclDescriptor     = $aclIdentitySource.descriptor
                    PrincipalName     = $group.principalName
                    OriginId          = $group.originId
                    GraphDescriptor   = $group.descriptor
                    AclId             = $aclIdentitySource.id
                    SubjectDescriptor = $aclIdentitySource.subjectDescriptor
                    Persist           = $true
                }
                Add-IdentityDescriptorIndexItem @descriptorIndexParams
            }
            catch
            {
                Write-Warning "[Get-AzDoGroupPermission] Failed to enrich live group '$($group.principalName)' with its ACL identity: $_"
            }
        }
    }

    if (-not $group)
    {
        Throw "[Get-AzDoGroupPermission] Group not found: $('[{0}]\{1}' -f $ProjectName, $GroupName)"
        return
    }

    # If project not in cache, fall back to a live API lookup
    if (-not $project)
    {
        Write-Verbose "[Get-AzDoGroupPermission] Project not found in cache — falling back to live API lookup."
        $projectResponse = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectResponse)
        {
            $project = $projectResponse
            Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects'
        }
    }

    if (-not $project)
    {
        Throw "[Get-AzDoGroupPermission] Project not found: $ProjectName"
        return
    }

    #
    # Perform Lookup of the Permissions for the Group

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    Write-Verbose "[Get-AzDoGroupPermission] Retrieved namespace: $($namespace.namespaceId)"

    # Add to the ACL Lookup Params
    $getGroupResult.namespace = $namespace

    # Build the token for this specific group so Get-DevOpsACL returns only the one ACL we care
    # about rather than every ACL in the Identity namespace (which can be thousands and very slow).
    # Azure DevOps Identity ACL tokens use a SINGLE backslash: {projectId}\{groupOriginId}.
    $groupToken = '{0}\{1}' -f $project.id, $group.originId

    $ACLLookupParams = @{
        OrganizationName        = $OrganizationName
        SecurityDescriptorId    = $namespace.namespaceId
        Token                   = $groupToken
    }

    # Get the ACL List and format the ACLS
    Write-Verbose "[Get-AzDoGroupPermission] ACL Lookup Params: $($ACLLookupParams | Out-String)"

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

    Write-Verbose "[Get-AzDoGroupPermission] ACL List retrieved and formatted."

    #
    # Convert the Permissions into an ACL Token

    $params = @{
        Permissions         = $Permissions
        SecurityNamespace   = $SecurityNamespace
        isInherited         = $isInherited
        OrganizationName    = $OrganizationName
        TokenName           = '{0}\{1}' -f $project.id, $group.originId
    }

    # Convert the Permissions to an ACL Token
    $ReferenceACLs = ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'GroupUnknown' }

    # if the ACEs are empty, the desired permissions could not be resolved (unknown identities filtered out)
    if ($ReferenceACLs.aces.Count -eq 0)
    {
        Write-Verbose "[Get-AzDoGroupPermission] No resolvable ACEs for the group — treating as NotFound."
        $getGroupResult.status = [DSCGetSummaryState]::NotFound
        return $getGroupResult
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
    Write-Verbose "[Get-AzDoGroupPermission] Result Status: $($getGroupResult.status)"
    Write-Verbose "[Get-AzDoGroupPermission] Returning Group Result."

    # Return the Group Result
    return $getGroupResult

}

