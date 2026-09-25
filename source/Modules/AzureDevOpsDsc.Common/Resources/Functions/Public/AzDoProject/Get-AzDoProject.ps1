<#
.SYNOPSIS
    Retrieves information about an Azure DevOps project.

.DESCRIPTION
    The Get-AzDoProject function retrieves details about an Azure DevOps project, including its name, description, source control type, process template, and visibility. It performs lookups to check if the project and process template exist and returns the project's status and any properties that have changed.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This parameter is validated using the Test-AzDevOpsProjectName function.

.PARAMETER ProjectDescription
    The description of the Azure DevOps project. Defaults to an empty string if not specified.

.PARAMETER SourceControlType
    The source control type of the Azure DevOps project. Valid values are 'Git' and 'Tfvc'. Defaults to 'Git'.

.PARAMETER ProcessTemplate
    The process template used by the Azure DevOps project. Accepts any process name known to the
    organization (system or inherited); unknown names throw. Defaults to 'Agile'. When the project
    already exists and is on a different process, this is only reported as a supported change
    (status Changed) when the current and desired processes share the same system-process
    ancestor - otherwise status Error is returned with reason 'ProcessMigrationIncompatible'.

.PARAMETER Visibility
    The visibility of the Azure DevOps project. Valid values are 'Public' and 'Private'. Defaults to 'Private'.

.PARAMETER LookupResult
    A hashtable to store the lookup result.

.PARAMETER Ensure
    Specifies the desired state of the project.

.OUTPUTS
    [System.Management.Automation.PSObject[]]
    Returns a hashtable containing the project's details and status.

.EXAMPLE
    Get-AzDoProject -ProjectName "MyProject" -ProjectDescription "Sample project" -SourceControlType "Git" -ProcessTemplate "Agile" -Visibility "Private"

    Retrieves information about the Azure DevOps project named "MyProject" with the specified parameters.

.NOTES
    This function relies on global variables and other functions such as Get-CacheItem and Test-AzDevOpsProjectName to perform lookups and validations.
#>
function Get-AzDoProject
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter()]
        [ValidateScript({ Test-AzDevOpsProjectName -ProjectName $_ -IsValid -AllowWildcard })]
        [Alias('Name')]
        [System.String] $ProjectName,

        [Parameter()]
        [Alias('Description')]
        [System.String] $ProjectDescription = '',

        [Parameter()]
        [ValidateSet('Git', 'Tfvc')]
        [System.String] $SourceControlType = 'Git',

        [Parameter()]
        [System.String] $ProcessTemplate = 'Agile',

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [System.String] $Visibility = 'Private',

        [Parameter()]
        [HashTable] $LookupResult,

        [Parameter()]
        [Ensure] $Ensure
    )

    Write-Verbose "[Get-AzDoProject] Started."

    # Set the organization name
    $OrganizationName = (Get-AzDoOrganizationName)
    Write-Verbose "[Get-AzDoProject] Organization Name: $OrganizationName"

    # Construct a hashtable detailing the group
    $result = @{
        Ensure             = [Ensure]::Absent
        ProjectName        = $ProjectName
        ProjectDescription = $ProjectDescription
        SourceControlType  = $SourceControlType
        ProcessTemplate    = $ProcessTemplate
        Visibility         = $Visibility
        propertiesChanged  = @()
        status             = $null
        reason             = $null
    }

    Write-Verbose "[Get-AzDoProject] Initial result hashtable constructed."

    # Perform a lookup to see if the project exists in Azure DevOps
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # If not in cache, fall back to a live API lookup
    if ($null -eq $project)
    {
        Write-Verbose "[Get-AzDoProject] Project '$ProjectName' not in cache — falling back to live API lookup."
        try
        {
            $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
            # Project deletion is asynchronous: a project being removed is still returned for a
            # short window with state 'deleting'/'deleted'. Treat that as absent so a Test run
            # immediately after a delete correctly reports the desired (Absent) state.
            if ($project -and ($project.state -in 'deleting', 'deleted'))
            {
                Write-Verbose "[Get-AzDoProject] Project '$ProjectName' is in state '$($project.state)' — treating as absent."
                $project = $null
            }
            if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' }
        }
        catch
        {
            if ($_ -match '404') { $project = $null }
            else { throw }
        }
    }

    Write-Verbose "[Get-AzDoProject] Project lookup result: $project"

    # Resolve-DevOpsProcess falls back to a live lookup: an inherited process created by an
    # AzDoProcess resource earlier in the same configuration is not in the LiveProcesses cache.
    $processTemplateObj = Resolve-DevOpsProcess -ProcessName $ProcessTemplate -OrganizationName $OrganizationName
    Write-Verbose "[Get-AzDoProject] Process template lookup result: $processTemplateObj"

    # Test if the project exists. If the project does not exist, return NotFound
    if (($null -eq $project) -and ($null -ne $ProjectName))
    {
        $result.Status = [DSCGetSummaryState]::NotFound
        Write-Verbose "[Get-AzDoProject] Project not found."
        return $result
    }

    # Test if the process template exists. If the process template does not exist, throw an error.
    if ($null -eq $processTemplateObj)
    {
        throw "[Get-AzDoProject] Process template '$ProcessTemplate' not found."
    }

    Write-Verbose "[Get-AzDoProject] Testing source control type."

    # Test if the project is using the same source control type. If the source control type is different, return a conflict.
    if ($SourceControlType -ne $project.SourceControlType)
    {
        Write-Warning "[Get-AzDoProject] Source control type is different. Current: $($project.SourceControlType), Desired: $SourceControlType"
        Write-Warning "[Get-AzDoProject] Source control type cannot be changed. Please delete the project and recreate it."
    }

    # If the project description property does not exist. Create it and set it to an empty string.
    if ($null -eq $project.description)
    {
        $project | Add-Member -MemberType NoteProperty -Name description -Value ''
        Write-Verbose "[Get-AzDoProject] Project description was null, set to empty string."
    }

    # Test if the project description is the same. If the description is different, return a conflict.
    if ($ProjectDescription.Trim() -ne $project.description.Trim())
    {
        $result.Status = [DSCGetSummaryState]::Changed
        $result.propertiesChanged += 'Description'
        Write-Verbose "[Get-AzDoProject] Project description has changed."
    }

    # Test if the project visibility is the same. If the visibility is different, return a conflict.
    if ($Visibility -ne $project.Visibility)
    {
        $result.Status = [DSCGetSummaryState]::Changed
        $result.propertiesChanged += 'Visibility'
        Write-Verbose "[Get-AzDoProject] Project visibility has changed."
    }

    # Test if the project's process has changed. This only runs once both the project and the
    # desired process template have resolved to real objects with ids - the mocked unit tests for
    # the other properties don't populate an id, so this intentionally no-ops for them, and a
    # live cache-miss lookup that still returned an id-less object is treated the same way.
    if (-not [String]::IsNullOrWhiteSpace($project.id) -and -not [String]::IsNullOrWhiteSpace($processTemplateObj.id))
    {
        $projectCapabilities = Get-DevOpsProjectCapabilities -Organization $OrganizationName -ProjectId $project.id
        $currentProcessTypeId = $projectCapabilities.capabilities.processTemplate.templateTypeId

        if (-not [String]::IsNullOrWhiteSpace($currentProcessTypeId))
        {
            $result.currentProcessTypeId = $currentProcessTypeId
            $result.desiredProcessTypeId = $processTemplateObj.id

            if ($currentProcessTypeId -ne $processTemplateObj.id)
            {
                Write-Verbose "[Get-AzDoProject] Project process differs. Current: $currentProcessTypeId, Desired: $($processTemplateObj.id)"

                # The LiveProcesses cache does not carry parentProcessTypeId/customizationType, so
                # family membership can only be determined with a live per-process lookup.
                $currentProcessDetail = Get-DevOpsProcess -Organization $OrganizationName -ProcessTypeId $currentProcessTypeId
                $desiredProcessDetail = Get-DevOpsProcess -Organization $OrganizationName -ProcessTypeId $processTemplateObj.id

                if (($null -ne $currentProcessDetail) -and ($null -ne $desiredProcessDetail))
                {
                    $currentFamilyRoot = Get-AzDoProcessFamilyRootId -ProcessDetail $currentProcessDetail
                    $desiredFamilyRoot = Get-AzDoProcessFamilyRootId -ProcessDetail $desiredProcessDetail

                    if ($currentFamilyRoot -eq $desiredFamilyRoot)
                    {
                        $result.Status = [DSCGetSummaryState]::Changed
                        $result.propertiesChanged += 'ProcessTemplate'
                        Write-Verbose "[Get-AzDoProject] Project process has changed and the migration is supported."
                    }
                    else
                    {
                        Write-Error "[Get-AzDoProject] Project '$ProjectName' cannot be migrated to process '$ProcessTemplate': Azure DevOps only allows moving a project between a system process and its inherited children, or between two inheritors of the same parent."
                        $result.status = [DSCGetSummaryState]::Error
                        $result.reason = 'ProcessMigrationIncompatible'
                        return $result
                    }
                }
                else
                {
                    Write-Verbose "[Get-AzDoProject] Could not resolve process family details for comparison - skipping."
                }
            }
        }
    }

    # Test if the properties have changed. If the properties haven't changed, return Unchanged.
    if ($result.propertiesChanged.Count -eq 0)
    {
        $result.Status = [DSCGetSummaryState]::Unchanged
        Write-Verbose "[Get-AzDoProject] Project properties have not changed."
    }

    # Return the group from the cache
    Write-Verbose "[Get-AzDoProject] Returning final result."

    return $result

}
