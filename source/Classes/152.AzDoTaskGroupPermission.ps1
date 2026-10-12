<#
.SYNOPSIS
    DSC resource for managing task group permissions.

.DESCRIPTION
    This resource manages permissions in the 'MetaTask' security namespace, which secures task
    groups (see AzDoTaskGroup): who can administer, edit or delete them.

    Omitting TaskGroupName targets the project level, which sets the baseline for every task group
    in the project.

    Only the identities listed in Permissions are managed. Every other identity's entry on the
    token, such as the Administer grant a task group's creator receives, is carried through
    unchanged when permissions are written, and removing the resource clears only the listed
    identities' entries.

.NOTES
    The token is '{projectId}' for the project level and '{projectId}/{taskGroupId}' for one task
    group. Both are built from ids, so deleting and recreating a task group with the same name
    gives it a new token; this resource re-applies its permissions on the next run.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This is the key property.

.PARAMETER TaskGroupName
    The name of the task group. Omit to target every task group in the project.

.PARAMETER isInherited
    Whether permissions are inherited from the project level. Defaults to $true.

.PARAMETER Permissions
    An array of hashtables, each with an 'Identity' and a 'Permission' map from an action name
    (for example 'Edit task group') to 'Allow' or 'Deny'.

.EXAMPLE
    AzDoTaskGroupPermission DeployStepsEditors
    {
        ProjectName   = 'Contoso'
        TaskGroupName = 'Deploy web app'
        Permissions   = @(
            @{
                Identity   = '[Contoso]\Release Managers'
                Permission = @{ 'Edit task group' = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoTaskGroupPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty()]
    [System.String]$TaskGroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoTaskGroupPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTaskGroupPermission] Get()
    {
        return [AzDoTaskGroupPermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName   = $CurrentResourceObject.ProjectName
        $properties.TaskGroupName = $CurrentResourceObject.TaskGroupName
        $properties.isInherited   = $CurrentResourceObject.isInherited
        $properties.Permissions   = $CurrentResourceObject.Permissions
        $properties.LookupResult  = $CurrentResourceObject.LookupResult
        $properties.Ensure        = $CurrentResourceObject.Ensure
        return $properties
    }
}
