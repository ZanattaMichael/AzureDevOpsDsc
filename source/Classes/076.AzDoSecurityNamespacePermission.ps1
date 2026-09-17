<#
.SYNOPSIS
    DSC resource for managing generic Azure DevOps security namespace permissions.
.DESCRIPTION
    This resource provides low-level access to Azure DevOps security namespaces, allowing fine-
    grained permission control over any object in the system. It is the escape hatch for namespaces
    with no dedicated resource. ### Prefer a dedicated resource where one exists This resource
    takes a caller-supplied Token string, and constructing that token correctly is the hard and
    error-prone part — the shape differs per namespace, and a wrong token silently targets nothing.
    The dedicated resources build it for you from readable names: | Namespace | Dedicated resource
    | |---|---| | Git Repositories | [AzDoGitPermission](AzDoGitPermission.md) | | CSS |
    [AzDoAreaPermission](AzDoAreaPermission.md) | | Iteration |
    [AzDoIterationPermission](AzDoIterationPermission.md) | | Project |
    [AzDoProjectPermission](AzDoProjectPermission.md) | | Process |
    [AzDoProcessPermission](AzDoProcessPermission.md) | | Build |
    [AzDoPipelinePermission](AzDoPipelinePermission.md),
    [AzDoPipelineFolderPermission](AzDoPipelineFolderPermission.md) | | Library |
    [AzDoVariableGroupPermission](AzDoVariableGroupPermission.md),
    [AzDoSecureFilePermission](AzDoSecureFilePermission.md) | | ServiceEndpoints |
    [AzDoServiceConnectionPermission](AzDoServiceConnectionPermission.md) | | AgentPool,
    DistributedTask | [AzDoAgentPoolPermission](AzDoAgentPoolPermission.md),
    [AzDoEnvironmentPermission](AzDoEnvironmentPermission.md) | | WorkItemQueryFolders |
    [AzDoQueryPermission](AzDoQueryPermission.md) | Use this resource for anything not in that
    list. ### Permission names come from the namespace Do not assume a fixed set of action names.
    Read them from _apis/securitynamespaces/{namespaceId} — they differ per namespace and have
    changed between API versions.

.PARAMETER SecurityNamespace
    The name of the Azure DevOps security namespace (e.g., Build, Git Repositories, Project). This property is mandatory and serves as a key property for the resource.

.PARAMETER Token
    The security token identifying the specific object within the namespace. This is a key property.

.PARAMETER GroupName
    The name of the group to grant permissions to. This is a key property. Use the format [ProjectName]\GroupName.

.PARAMETER isInherited
    Whether permissions are inherited. Defaults to $true.

#>

[DscResource()]
class AzDoSecurityNamespacePermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$SecurityNamespace

    [DscProperty(Mandatory)]
    [System.String]$Token

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoSecurityNamespacePermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoSecurityNamespacePermission] Get()
    {
        return [AzDoSecurityNamespacePermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.SecurityNamespace = $CurrentResourceObject.SecurityNamespace
        $properties.Token             = $CurrentResourceObject.Token
        $properties.GroupName         = $CurrentResourceObject.GroupName
        $properties.isInherited       = $CurrentResourceObject.isInherited
        $properties.Permissions       = $CurrentResourceObject.Permissions
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoSecurityNamespacePermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
