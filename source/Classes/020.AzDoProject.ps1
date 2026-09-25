<#
.SYNOPSIS
    This class represents an Azure DevOps project.

.DESCRIPTION
    The AzDoProject class is used to define and manage Azure DevOps projects. It inherits from the AzDevOpsDscResourceBase class.

.NOTES
    Author: Michael Zanatta
    Date: 2025-01-06

.LINK
    GitHub Repository: <link to the GitHub repository>

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER ProjectDescription
    The description of the Azure DevOps project.

.PARAMETER SourceControlType
    The type of source control for the project. Valid values are 'Git' and 'Tfvc'.

.PARAMETER ProcessTemplate
    The process template for the project. Accepts any process name available in the organization,
    including the built-in system processes ('Agile', 'Scrum', 'CMMI', 'Basic') and any inherited
    process created from them. Unknown names are rejected at apply time against the live process
    list. Changing this on an existing project (via Set) is only permitted when the current and
    desired processes share the same system-process ancestor (for example, moving between a system
    process and one of its inherited children, or between two inherited children of the same
    parent) - Azure DevOps does not allow migrating a project across unrelated process families.

.PARAMETER Visibility
    The visibility of the project. Valid values are 'Public' and 'Private'.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    $project = [AzDoProject]::Get()
    $project.ProjectName = 'MyProject'
    $project.ProjectDescription = 'This is a sample project'
    $project.SourceControlType = 'Git'
    $project.ProcessTemplate = 'Agile'
    $project.Visibility = 'Private'
    $project | Set-AzDevOpsProject

#>

[DscResource()]
class AzDoProject : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Description')]
    [System.String]$ProjectDescription

    [DscProperty()]
    [ValidateSet('Git', 'Tfvc')]
    [System.String]$SourceControlType = 'Git'

    [DscProperty()]
    [System.String]$ProcessTemplate = 'Agile'

    [DscProperty()]
    [ValidateSet('Public', 'Private')]
    [System.String]$Visibility = 'Private'

    AzDoProject()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoProject] Get()
    {
        return [AzDoProject]$($this.GetDscCurrentStateProperties())
    }


    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @('SourceControlType')
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

        $properties.ProjectName         = $CurrentResourceObject.ProjectName
        $properties.ProjectDescription  = $CurrentResourceObject.ProjectDescription
        $properties.SourceControlType   = $CurrentResourceObject.SourceControlType
        $properties.ProcessTemplate     = $CurrentResourceObject.ProcessTemplate
        $properties.Visibility          = $CurrentResourceObject.Visibility
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        $properties.Ensure              = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoGroupPermission] Current state properties: $($properties | Out-String)"

        return $properties

    }

}
