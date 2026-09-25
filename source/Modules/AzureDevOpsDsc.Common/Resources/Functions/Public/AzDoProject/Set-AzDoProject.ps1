<#
.SYNOPSIS
Updates an existing Azure DevOps project with the specified parameters.

.DESCRIPTION
The Set-AzDoProject function updates an existing Azure DevOps project with the provided project name, description, source control type, process template, and visibility. It performs a lookup to see if the project exists in Azure DevOps, constructs the parameters for the API call, updates the project, waits for the update to complete, and refreshes the cache.

.PARAMETER ProjectName
Specifies the name of the Azure DevOps project to update. This parameter is validated using the Test-AzDevOpsProjectName function.

.PARAMETER ProjectDescription
Specifies the description of the Azure DevOps project.

.PARAMETER SourceControlType
Specifies the source control type for the project. Valid values are 'Git' and 'Tfvc'. The default value is 'Git'.

.PARAMETER ProcessTemplate
Specifies the process template for the project. Accepts any process name known to the organization
(system or inherited); unknown names throw. The default value is 'Agile'. Changing this on an
existing project is only applied when Get-AzDoProject determined the migration is supported (the
current and desired processes share a system-process ancestor) - when LookupResult.reason is
'ProcessMigrationIncompatible' this function refuses the change instead of silently dropping it.

.PARAMETER Visibility
Specifies the visibility of the project. Valid values are 'Public' and 'Private'. The default value is 'Private'.

.PARAMETER LookupResult
Specifies a hashtable to store the lookup result.

.PARAMETER Ensure
Specifies whether to ensure the project exists or not.

.PARAMETER Force
Specifies whether to force the update of the project.

.EXAMPLE
Set-AzDoProject -ProjectName "MyProject" -ProjectDescription "This is a sample project" -SourceControlType "Git" -ProcessTemplate "Agile" -Visibility "Private"

This example updates the Azure DevOps project named "MyProject" with the specified description, source control type, process template, and visibility.

#>
function Set-AzDoProject
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateScript({ Test-AzDevOpsProjectName -ProjectName $_ -IsValid -AllowWildcard })]
        [Alias('Name')]
        [System.String]
        $ProjectName,

        [Parameter()]
        [Alias('Description')]
        [System.String]
        $ProjectDescription,

        [Parameter()]
        [ValidateSet('Git','Tfvc')]
        [System.String]
        $SourceControlType = 'Git',

        [Parameter()]
        [System.String]$ProcessTemplate = 'Agile',

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [System.String]$Visibility = 'Private',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $OrganizationName = (Get-AzDoOrganizationName)

    #
    # Get returning Error still routes here (see AzDevOpsDscResourceBase.GetDscRequiredAction), so
    # a refusal it decided on has to be repeated here rather than assumed - Get-AzDoProject sets
    # this reason when the current and desired processes do not share a system-process ancestor.
    if ($LookupResult.reason -eq 'ProcessMigrationIncompatible')
    {
        Write-Error "[Set-AzDoProject] Refusing to change project '$ProjectName' to process '$ProcessTemplate': Azure DevOps only allows moving a project between a system process and its inherited children, or between two inheritors of the same parent."
        return
    }

    #
    # Perform a lookup to see if the group exists in Azure DevOps
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    # Resolve-DevOpsProcess falls back to a live lookup: an inherited process created by an
    # AzDoProcess resource earlier in the same configuration is not in the LiveProcesses cache.
    $processTemplateObj = Resolve-DevOpsProcess -ProcessName $ProcessTemplate -OrganizationName $OrganizationName

    if ($null -eq $processTemplateObj)
    {
        throw "[Set-AzDoProject] Process template '$ProcessTemplate' not found."
    }

    #
    # Construct the parameters for the API call
    $parameters = @{
        organization = $OrganizationName
        projectId  = $project.id
        description  = $ProjectDescription
        visibility = $Visibility
    }

    #
    # Update the project

    $projectJob = Update-DevOpsProject @parameters

    if ($null -eq $projectJob)
    {
        Throw "[Set-AzDoProject] Update-DevOpsProject returned null for project '$ProjectName'."
    }

    $projectURL = if ($projectJob -is [System.Collections.IEnumerable] -and -not ($projectJob -is [string])) { ($projectJob | Select-Object -First 1).url } else { $projectJob.url }

    if ([String]::IsNullOrEmpty($projectURL))
    {
        Throw "[Set-AzDoProject] Project update returned but URL is empty. Job details: $($projectJob | ConvertTo-Json -Depth 2)"
    }

    #
    # Wait for the project to be updated

    Wait-DevOpsProject -ProjectURL $projectURL -OrganizationName $OrganizationName

    #
    # The project properties PATCH above cannot change a project's process - Azure DevOps only
    # accepts that through the dedicated migration endpoint, and only within the same OOB process
    # family. Get-AzDoProject already confirmed compatibility before reporting this as a change.
    if ($LookupResult.propertiesChanged -contains 'ProcessTemplate')
    {
        $desiredProcessTypeId = if (-not [String]::IsNullOrWhiteSpace($LookupResult.desiredProcessTypeId)) { $LookupResult.desiredProcessTypeId } else { $processTemplateObj.id }
        $null = Move-DevOpsProjectProcess -Organization $OrganizationName -ProjectId $project.id -ProcessTypeId $desiredProcessTypeId
    }

    #
    # Only the project caches are stale. Narrowing the refresh skips the group,
    # user, permission and identity scans this resource never touched - which
    # matters under DSC v3, where every invocation is a fresh process and pays
    # for the refresh again.

    Refresh-AzDoCache -OrganizationName $OrganizationName -CacheType 'LiveProjects'

}
