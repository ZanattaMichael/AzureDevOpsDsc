<#
.SYNOPSIS
    DSC resource for managing Azure DevOps pipeline (build) folders.

.DESCRIPTION
    Manages a folder in a project's pipeline tree. Pipeline folders are configuration in their own
    right: they carry ACLs that the definitions beneath them inherit, which is how pipeline
    security is normally administered.

.NOTES
    Author: Michael Zanatta

    Pipeline folder paths are backslash-delimited and rooted at '\', unlike work item query paths,
    which use forward slashes. Forward slashes are accepted and normalized, so '\Platform\Release',
    'Platform/Release' and '\Platform\Release\' all describe the same folder.

    Path is the resource key. The Build folders API can also rename or move a folder by supplying
    a different path, which moves every definition beneath it - the resource deliberately does not
    use that, because a mistyped path would silently relocate a whole tree. Changing Path describes
    a different folder, which is created; the old one is removed only if the configuration says so.

    Unlike the work item query tree, the Build folders API creates missing ancestors implicitly, so
    a nested folder can be declared without declaring each level above it.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER Path
    The full path of the folder, for example '\Platform\Release'.

.PARAMETER Description
    An optional description shown in the Azure DevOps UI.

.PARAMETER AllowRecursiveDelete
    Deleting a pipeline folder deletes every pipeline definition beneath it. Removal of a folder
    that still has contents is refused unless this is set to $true.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoPipelineFolder Platform
    {
        ProjectName = 'Contoso'
        Path        = '\Platform'
        Description = 'Platform team pipelines'
        Ensure      = 'Present'
    }
#>

[DscResource()]
class AzDoPipelineFolder : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [Alias('FolderPath')]
    [System.String]$Path

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.Boolean]$AllowRecursiveDelete = $false

    AzDoPipelineFolder()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoPipelineFolder] Get()
    {
        return [AzDoPipelineFolder]$($this.GetDscCurrentStateProperties())
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

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.Path                 = $CurrentResourceObject.Path
        $properties.Description          = $CurrentResourceObject.Description
        $properties.AllowRecursiveDelete = $CurrentResourceObject.AllowRecursiveDelete
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoPipelineFolder] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
