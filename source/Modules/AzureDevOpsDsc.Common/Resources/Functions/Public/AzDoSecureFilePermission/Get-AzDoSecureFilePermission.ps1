<#
.SYNOPSIS
Retrieves the current ACL state of an Azure DevOps secure file.

.DESCRIPTION
Builds the 'Library' ACL token for the secure file and compares its ACL against the desired
permissions. Secure files share the Library namespace with variable groups but carry their own
token segment: 'Library/Project/{projectId}/SecureFile/{secureFileId}'.

Omitting SecureFileName targets the project Library root, which is the parent of every secure
file and variable group in the project.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER SecureFileName
The name of the secure file. Omit to target the project Library root.

.PARAMETER isInherited
Whether the ACL inherits permissions from its parent.

.PARAMETER Permissions
The desired access control entries.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoSecureFilePermission -ProjectName 'Contoso' -SecureFileName 'signing.pfx' -isInherited $true
#>
Function Get-AzDoSecureFilePermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [Alias('FileName')]
        [System.String]$SecureFileName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]$isInherited,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoSecureFilePermission] Started."

    $SecurityNamespace = 'Library'
    $OrganizationName  = Get-AzDoOrganizationName

    $getResult = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $projectCache = Resolve-AzDoProject -ProjectName $ProjectName

    if (-not $projectCache)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Project not found: $ProjectName"
        return $getResult
    }

    $secureFile = $null

    if (-not [String]::IsNullOrWhiteSpace($SecureFileName))
    {
        $sfCacheKey = '{0}\{1}' -f $ProjectName, $SecureFileName
        $secureFile = Get-CacheItem -Key $sfCacheKey -Type 'LiveSecureFiles'

        if (-not $secureFile)
        {
            Write-Verbose "[Get-AzDoSecureFilePermission] Secure file '$SecureFileName' not in cache - falling back to a live API lookup."
            $allFiles   = List-DevOpsSecureFiles -Organization $OrganizationName -ProjectName $ProjectName
            $secureFile = $allFiles | Where-Object { $_.name -eq $SecureFileName } | Select-Object -First 1
            if ($secureFile) { Add-CacheItem -Key $sfCacheKey -Value $secureFile -Type 'LiveSecureFiles' }
        }

        if (-not $secureFile)
        {
            Write-Warning "[Get-AzDoSecureFilePermission] Secure file '$SecureFileName' not found in project '$ProjectName'."
            $getResult.status = [DSCGetSummaryState]::NotFound
            $getResult.reason = "Secure file not found: $SecureFileName"
            return $getResult
        }
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'

    if (-not $namespace)
    {
        Write-Error "[Get-AzDoSecureFilePermission] Security namespace '$SecurityNamespace' not found."
        $getResult.status = [DSCGetSummaryState]::Error
        return $getResult
    }

    $getResult.namespace = $namespace

    $aclToken = if ($secureFile) { 'Library/Project/{0}/SecureFile/{1}' -f $projectCache.id, $secureFile.id }
                else              { 'Library/Project/{0}' -f $projectCache.id }

    $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $aclToken
    if (-not $DevOpsACLs) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }

    # Drop the ACLs this lookup cannot be interested in BEFORE formatting them, exactly as
    # Get-AzDoProjectPermission and Get-AzDoProcessPermission already do. Formatting resolves every
    # ACE through Find-Identity, which costs an API round trip for each descriptor that is not
    # already cached, so formatting a whole namespace only to keep one token is where the time goes.
    # The fallback above fires whenever the secure file has no explicit ACL - the normal state
    # once permissions revert to inherited - so the full namespace is the common path, not a rare
    # one. The Library pattern is anchored, so the parsed filter below can only
    # keep a token equal to $aclToken: this drops exactly what that filter would have dropped.
    $DevOpsACLs = @($DevOpsACLs | Where-Object { $_.token -eq $aclToken })

    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    if ($secureFile)
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'Library') -and ($_.Token.ProjectId -eq $projectCache.id) -and ($_.Token.SecureFileId -eq $secureFile.id)
        }
    }
    else
    {
        # The project Library root is the token with neither a secure file nor a variable group
        # segment - both live in this namespace.
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'Library') -and ($_.Token.ProjectId -eq $projectCache.id) -and (-not $_.Token.SecureFileId) -and (-not $_.Token.VariableGroupId)
        }
    }

    $tokenName = if ($secureFile) { 'Library/Project/{0}/SecureFile/{1}' -f $ProjectName, $SecureFileName }
                 else              { 'Library/Project/{0}' -f $ProjectName }

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $tokenName
    }

    $ReferenceACLs = ConvertTo-ACL @params

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs

    $getResult.propertiesChanged = $compareResult.propertiesChanged
    $getResult.status            = [DSCGetSummaryState]::"$($compareResult.status)"
    $getResult.reason            = $compareResult.reason
    $getResult.ReferenceACLs     = $ReferenceACLs
    $getResult.DifferenceACLs    = $DifferenceACLs
    $getResult.aclToken          = $aclToken

    return $getResult
}
