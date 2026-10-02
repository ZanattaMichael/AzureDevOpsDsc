<#
.SYNOPSIS
Exports every manageable Azure DevOps project as AzDoProject-shaped property hashtables.

.DESCRIPTION
Export-AzDoProject is the '<ResourceName>' half of the AzDoProject DSC v3 Export() naming
convention: it is discovered and invoked by AzDevOpsDscResourceBase.ExportDscResourceInstances()
(via the static [AzDoProject]::Export() the DSC v3 PowerShell adapter calls), never called
directly by a configuration.

It lists every project in the organization with List-DevOpsProjects (the same call the
LiveProjects cache is built from) and emits, for each one, exactly the property set
Get-AzDoProject compares: ProjectName, ProjectDescription and Visibility, with Ensure set to
'Present'. Feeding these straight back through Invoke-DscResource -Method Test therefore reports
InDesiredState True, because Get-AzDoProject's own drift check only ever looks at Description and
Visibility.

SourceControlType and ProcessTemplate are left out. Both are immutable once a project exists
(AzDoProject.GetDscResourcePropertyNamesWithNoSetSupport() lists them, and Get-AzDoProject never
compares them - it only warns), and the project-list API this reads from does not return either
value, so there is nothing observed to export; the resource's own defaults ('Git'/'Agile') apply
when the exported hashtable is converted into an instance.

.PARAMETER OrganizationName
The name of the Azure DevOps organization to export projects from. Defaults to
Get-AzDoOrganizationName (the same global the resource's own Get/New/Set/Remove functions use).

.OUTPUTS
System.Collections.Hashtable[]
One hashtable per exportable project, each with Ensure, ProjectName, ProjectDescription and
Visibility.

.EXAMPLE
Export-AzDoProject

Returns one hashtable per project currently in the organization.

.NOTES
List-DevOpsProjects defaults to '-StateFilter wellFormed', so a project mid-creation or
mid-deletion is already excluded by the API call itself and is never returned here.
#>
function Export-AzDoProject
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        [Parameter()]
        [System.String]$OrganizationName = (Get-AzDoOrganizationName)
    )

    Write-Verbose "[Export-AzDoProject] Listing projects for organization '$OrganizationName'."

    $projects = @(List-DevOpsProjects -OrganizationName $OrganizationName)

    $exportedProjects = [System.Collections.Generic.List[Hashtable]]::new()

    foreach ($project in $projects)
    {
        if ($null -eq $project)
        {
            continue
        }

        # Belt-and-braces: List-DevOpsProjects defaults to 'wellFormed', but a project caught
        # mid-transition should never be exported even if that default is ever widened upstream.
        if ($project.state -in 'deleting', 'deleted', 'createPending')
        {
            Write-Verbose "[Export-AzDoProject] Skipping project '$($project.name)' in state '$($project.state)'."
            continue
        }

        $visibility = if ("$($project.visibility)".ToLowerInvariant() -eq 'public') { 'Public' } else { 'Private' }

        $exportedProjects.Add(
            @{
                Ensure             = [Ensure]::Present
                ProjectName        = $project.name
                ProjectDescription = $(if ($project.description) { $project.description } else { '' })
                Visibility         = $visibility
            }
        )
    }

    Write-Verbose "[Export-AzDoProject] Exported $($exportedProjects.Count) project(s)."

    return $exportedProjects.ToArray()
}
