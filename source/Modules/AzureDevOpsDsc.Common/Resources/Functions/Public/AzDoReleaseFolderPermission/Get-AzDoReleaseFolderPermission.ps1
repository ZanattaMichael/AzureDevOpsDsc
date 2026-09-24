<#
.SYNOPSIS
Retrieves the current ACL state of an Azure DevOps classic Release folder.

.DESCRIPTION
Builds the 'ReleaseManagement' ACL token for the folder and compares its ACL against the desired
permissions.

A Release folder's token addresses the folder by path - '{projectId}/{folderPath}' - whereas a
release definition's token uses its numeric id. Omitting FolderPath targets the project release
root, whose token is the project id alone.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER FolderPath
The Release folder path. Omit to target the project release root.

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
Get-AzDoReleaseFolderPermission -ProjectName 'Contoso' -FolderPath '\Platform' -isInherited $true
#>
Function Get-AzDoReleaseFolderPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [Alias('Path')]
        [System.String]$FolderPath,

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

    Write-Verbose "[Get-AzDoReleaseFolderPermission] Started."

    $SecurityNamespace = 'ReleaseManagement'
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

    $normalizedPath = Format-AzDoPipelineFolderPath -Path $FolderPath
    $isRoot         = ([String]::IsNullOrWhiteSpace($FolderPath) -or $normalizedPath -eq '\')

    if (-not $isRoot)
    {
        $folders = List-DevOpsReleaseFolders -Organization $OrganizationName -ProjectName $ProjectName -Path $normalizedPath
        $folder  = $folders | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -eq $normalizedPath } | Select-Object -First 1

        if ($null -eq $folder)
        {
            Write-Warning "[Get-AzDoReleaseFolderPermission] Release folder '$normalizedPath' not found in project '$ProjectName'."
            $getResult.status = [DSCGetSummaryState]::NotFound
            $getResult.reason = "Release folder not found: $normalizedPath"
            return $getResult
        }
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'

    if (-not $namespace)
    {
        Write-Error "[Get-AzDoReleaseFolderPermission] Security namespace '$SecurityNamespace' not found."
        $getResult.status = [DSCGetSummaryState]::Error
        return $getResult
    }

    $getResult.namespace = $namespace

    # The API token carries the folder path without its leading separator.
    $tokenFolderPath = $normalizedPath.TrimStart('\')

    $aclToken = if ($isRoot) { '{0}' -f $projectCache.id }
                else         { '{0}/{1}' -f $projectCache.id, $tokenFolderPath }

    $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $aclToken
    if (-not $DevOpsACLs) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }

    # Drop the ACLs this lookup cannot be interested in BEFORE formatting them, exactly as
    # Get-AzDoPipelineFolderPermission does. Formatting resolves every ACE through Find-Identity,
    # which costs an API round trip for each descriptor that is not already cached, so formatting
    # a whole namespace only to keep one token is where the time goes. The fallback above fires
    # whenever the folder has no explicit ACL - the normal state once permissions revert to
    # inherited - so the full namespace is the common path, not a rare one.
    $DevOpsACLs = @($DevOpsACLs | Where-Object {
        $rawToken = $_.token
        if ([String]::IsNullOrEmpty($rawToken)) { return $false }
        if ($isRoot) { return ($rawToken -eq $aclToken) }
        $prefix = '{0}/' -f $projectCache.id
        if (-not $rawToken.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { return $false }
        (Format-AzDoPipelineFolderPath -Path $rawToken.Substring($prefix.Length)) -eq $normalizedPath
    })

    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    if ($isRoot)
    {
        # The release root is the token with no folder path and no definition id.
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'ReleaseRoot') -and ($_.Token.ProjectId -eq $projectCache.id)
        }
    }
    else
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'ReleaseFolder') -and
            ($_.Token.ProjectId -eq $projectCache.id) -and
            ((Format-AzDoPipelineFolderPath -Path $_.Token.FolderPath) -eq $normalizedPath)
        }
    }

    # The resource-side token keeps the leading separator on the folder path: New-ACLToken uses it
    # to tell a folder from a root/definition token of the same name.
    $tokenName = if ($isRoot) { $ProjectName } else { '{0}/{1}' -f $ProjectName, $normalizedPath }

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
