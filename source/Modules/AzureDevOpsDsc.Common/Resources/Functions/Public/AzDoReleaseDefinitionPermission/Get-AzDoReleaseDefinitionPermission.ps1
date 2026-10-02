<#
.SYNOPSIS
Retrieves the current ACL state of an Azure DevOps classic Release definition.

.DESCRIPTION
Resolves the Release definition by name (and, when given, by the folder it lives in) to its
numeric id, builds the 'ReleaseManagement' ACL token for it, and compares its ACL against the
desired permissions.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DefinitionName
The name of the Release definition.

.PARAMETER FolderPath
The Release folder the definition lives in. Omit when the definition lives at the release root,
or when its name is unique across the project.

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
Get-AzDoReleaseDefinitionPermission -ProjectName 'Contoso' -DefinitionName 'Platform Release' -isInherited $true
#>
Function Get-AzDoReleaseDefinitionPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$DefinitionName,

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

    Write-Verbose "[Get-AzDoReleaseDefinitionPermission] Started."

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

    $normalizedFolderPath = if ([String]::IsNullOrWhiteSpace($FolderPath)) { $null } else { Format-AzDoPipelineFolderPath -Path $FolderPath }

    # Resolve the definition to its numeric id through the live search endpoint, and cache the
    # result under 'LiveReleaseDefinitions' so New-ACLToken resolves the same name to the same id
    # when it builds the reference ACL below, instead of falling back to the name as a literal id.
    $definitionCacheKey = '{0}\{1}' -f $ProjectName, $DefinitionName
    $definition = Get-CacheItem -Key $definitionCacheKey -Type 'LiveReleaseDefinitions'

    if (-not $definition)
    {
        $findParams = @{
            Organization   = $OrganizationName
            ProjectName    = $ProjectName
            DefinitionName = $DefinitionName
        }
        if ($normalizedFolderPath) { $findParams.FolderPath = $normalizedFolderPath }

        $definition = Find-DevOpsReleaseDefinition @findParams

        if ($definition)
        {
            Add-CacheItem -Key $definitionCacheKey -Value $definition -Type 'LiveReleaseDefinitions'
        }
    }

    if (-not $definition)
    {
        Write-Warning "[Get-AzDoReleaseDefinitionPermission] Release definition '$DefinitionName' not found in project '$ProjectName'."
        $getResult.status = [DSCGetSummaryState]::NotFound
        $getResult.reason = "Release definition not found: $DefinitionName"
        return $getResult
    }

    $definitionFolderPath = if ($definition.path) { (Format-AzDoPipelineFolderPath -Path $definition.path).TrimStart('\') } else { $null }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'

    if (-not $namespace)
    {
        Write-Error "[Get-AzDoReleaseDefinitionPermission] Security namespace '$SecurityNamespace' not found."
        $getResult.status = [DSCGetSummaryState]::Error
        return $getResult
    }

    $getResult.namespace = $namespace

    $aclToken = if ($definitionFolderPath) { '{0}/{1}/{2}' -f $projectCache.id, $definitionFolderPath, $definition.id }
                else                       { '{0}/{1}' -f $projectCache.id, $definition.id }

    $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $aclToken
    if (-not $DevOpsACLs) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }

    # Drop the ACLs this lookup cannot be interested in BEFORE formatting them - same rationale as
    # Get-AzDoReleaseFolderPermission and Get-AzDoPipelinePermission.
    $DevOpsACLs = @($DevOpsACLs | Where-Object { $_.token -eq $aclToken })

    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    $DifferenceACLs = $DifferenceACLs | Where-Object {
        ($_.Token.Type -eq 'ReleaseDefinition') -and
        ($_.Token.ProjectId -eq $projectCache.id) -and
        ($_.Token.DefinitionId -eq $definition.id.ToString())
    }

    # The resource-side token marks a definition with a leading '@' immediately before its name, so
    # New-ACLToken can tell it apart from a folder or root token of the same text. A folder segment
    # keeps its own leading and trailing separator.
    $tokenName = if ($definitionFolderPath) { '{0}/\{1}\@{2}' -f $ProjectName, $definitionFolderPath, $DefinitionName }
                 else                       { '{0}/@{1}' -f $ProjectName, $DefinitionName }

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
