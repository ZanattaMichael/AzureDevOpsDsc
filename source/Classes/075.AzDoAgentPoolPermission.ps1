<#
.SYNOPSIS
    DSC resource for managing Azure DevOps agent pool permissions.
.DESCRIPTION
    This resource manages security permissions on Azure DevOps agent pools, controlling which
    groups or users can use or administer the pool.

.PARAMETER PoolName
    The name of the agent pool. This property is mandatory and serves as the key property for the resource.

.PARAMETER GroupName
    The name of the group to grant permissions to. This is a key property. Use the format [ProjectName]\GroupName or [TEAM FOUNDATION]\GroupName for organization-level groups.

.PARAMETER isInherited
    Whether permissions are inherited. Defaults to $true.

#>

[DscResource()]
class AzDoAgentPoolPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$PoolName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoAgentPoolPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoAgentPoolPermission] Get()
    {
        return [AzDoAgentPoolPermission]$($this.GetDscCurrentStateProperties())
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

        $properties.PoolName     = $CurrentResourceObject.PoolName
        $properties.GroupName    = $CurrentResourceObject.GroupName
        $properties.isInherited  = $CurrentResourceObject.isInherited
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoAgentPoolPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
