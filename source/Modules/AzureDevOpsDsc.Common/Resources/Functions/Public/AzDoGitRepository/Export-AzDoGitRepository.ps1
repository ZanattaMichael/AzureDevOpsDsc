<#
.SYNOPSIS
Exports every manageable Azure DevOps Git repository as AzDoGitRepository-shaped property
hashtables.

.DESCRIPTION
Export-AzDoGitRepository is the '<ResourceName>' half of the AzDoGitRepository DSC v3 Export()
naming convention: it is discovered and invoked by
AzDevOpsDscResourceBase.ExportDscResourceInstances() (via the static
[AzDoGitRepository]::Export() the DSC v3 PowerShell adapter calls), never called directly by a
configuration.

It lists every project with List-DevOpsProjects and, for each one, every repository with
List-DevOpsGitRepository (the same calls the LiveProjects/LiveRepositories caches are built from),
emitting ProjectName, RepositoryName and Ensure = 'Present' for each. Feeding these straight back
through Invoke-DscResource -Method Test therefore reports InDesiredState True: Get-AzDoGitRepository
only ever checks whether the '<ProjectName>\<RepositoryName>' pair exists, never a property value.

A disabled repository is skipped: the resource has no way to re-enable or otherwise manage one
(New-/Set-AzDoGitRepository have no notion of a disabled repository), so exporting it would only
produce a resource block that can never converge.

SourceRepository is left out. It names the repository a new repository should be forked from at
creation time; Azure DevOps does not report an existing repository's fork origin back through the
list API in a form that round-trips into that same property, and the property has no bearing on
whether an already-existing repository is in the desired state (Get-AzDoGitRepository never
compares it - ProjectName, RepositoryName and SourceRepository are all listed in
AzDoGitRepository.GetDscResourcePropertyNamesWithNoSetSupport()).

.PARAMETER OrganizationName
The name of the Azure DevOps organization to export repositories from. Defaults to
Get-AzDoOrganizationName (the same global the resource's own Get/New/Set/Remove functions use).

.OUTPUTS
System.Collections.Hashtable[]
One hashtable per exportable repository, each with Ensure, ProjectName and RepositoryName.

.EXAMPLE
Export-AzDoGitRepository

Returns one hashtable per Git repository across every project in the organization.
#>
function Export-AzDoGitRepository
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        [Parameter()]
        [System.String]$OrganizationName = (Get-AzDoOrganizationName)
    )

    Write-Verbose "[Export-AzDoGitRepository] Listing projects for organization '$OrganizationName'."

    $projects = @(List-DevOpsProjects -OrganizationName $OrganizationName)

    $exportedRepositories = [System.Collections.Generic.List[Hashtable]]::new()

    foreach ($project in $projects)
    {
        if ($null -eq $project)
        {
            continue
        }

        Write-Verbose "[Export-AzDoGitRepository] Listing repositories for project '$($project.name)'."
        $repositories = @(List-DevOpsGitRepository -OrganizationName $OrganizationName -ProjectName $project.name)

        foreach ($repository in $repositories)
        {
            if ($null -eq $repository)
            {
                continue
            }

            if ($repository.isDisabled -eq $true)
            {
                Write-Verbose "[Export-AzDoGitRepository] Skipping disabled repository '$($repository.name)' in project '$($project.name)'."
                continue
            }

            $exportedRepositories.Add(
                @{
                    Ensure         = [Ensure]::Present
                    ProjectName    = $project.name
                    RepositoryName = $repository.name
                }
            )
        }
    }

    Write-Verbose "[Export-AzDoGitRepository] Exported $($exportedRepositories.Count) repository(ies)."

    return $exportedRepositories.ToArray()
}
