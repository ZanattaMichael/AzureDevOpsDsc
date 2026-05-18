<#
.SYNOPSIS
    DSC resource for managing Azure DevOps agent pool permissions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoAgentPoolPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$PoolName

    [DscProperty(Key, Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoAgentPoolPermission()
    {
        $this.Construct()
    }

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