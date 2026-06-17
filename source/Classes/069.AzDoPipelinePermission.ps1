<#
.SYNOPSIS
    DSC resource for managing Azure DevOps pipeline-level ACL permissions.

.DESCRIPTION
    The AzDoPipelinePermission class manages pipeline-level permissions within
    an Azure DevOps project using the Build security namespace.

.PARAMETER ProjectName
    The Azure DevOps project name.

.PARAMETER PipelineName
    The name of the pipeline.

.PARAMETER GroupName
    The name of the group whose permissions are being managed.

.PARAMETER isInherited
    Whether the permissions are inherited. Default is $true.

.PARAMETER Permissions
    Hashtable array of permissions to apply.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoPipelinePermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$PipelineName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoPipelinePermission()
    {
        $this.Construct()
    }

    [AzDoPipelinePermission] Get()
    {
        return [AzDoPipelinePermission]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName       = $CurrentResourceObject.ProjectName
        $properties.PipelineName      = $CurrentResourceObject.PipelineName
        $properties.GroupName         = $CurrentResourceObject.GroupName
        $properties.isInherited       = $CurrentResourceObject.isInherited
        $properties.Permissions       = $CurrentResourceObject.Permissions
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoPipelinePermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}