<#
.SYNOPSIS
Creates a new Azure DevOps project.

.DESCRIPTION
This function creates a new Azure DevOps project using the Azure DevOps REST API. It requires the organization name, project name, description, visibility (either "private" or "public"), and a personal access token for authentication.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the project to be created.

.PARAMETER Description
A brief description of the project.

.PARAMETER Visibility
The visibility of the project. Valid values are "private" or "public".

.PARAMETER PersonalAccessToken
The personal access token used for authentication.

.EXAMPLE
New-DevOpsProject -Organization "myorg" -ProjectName "MyProject" -Description "This is a new project" -Visibility "private" -PersonalAccessToken "mytoken"

This example creates a new private Azure DevOps project named "MyProject" with the description "This is a new project" in the organization "myorg" using the specified personal access token.

#>
function New-DevOpsProject
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

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
        [System.String]
        $SourceControlType,

        [Parameter()]
        [System.String]$ProcessTemplateId,

        [Parameter()]
        [System.String]$Visibility,

        # Use 6.0 — later versions return 405 for POST /projects
        [Parameter()]
        [String]
        $ApiVersion = '6.0',

        # Wait for the (asynchronous) project provisioning to complete before returning.
        # POST /_apis/projects returns a 202 operation reference; the project is not usable
        # (queryable / able to host child resources) until it reaches the 'wellFormed' state.
        [Parameter()]
        [Switch]
        $NoWait,

        # Maximum number of seconds to wait for the project to become 'wellFormed'.
        [Parameter()]
        [int]
        $TimeoutSeconds = 180
    )

    # Validate the parameters
    $params = @{
        Uri              = 'https://dev.azure.com/{0}/_apis/projects?api-version={1}' -f $Organization, $ApiVersion
        Method           = "POST"
        Body             = @{
            name         = $ProjectName
            description  = $ProjectDescription
            visibility   = $Visibility
            capabilities = @{
                versioncontrol = @{
                    sourceControlType = $SourceControlType
                }
                processTemplate = @{
                    templateTypeId = $ProcessTemplateId
                }
            }
        }
    }

    # Seralize the Body to JSON
    $params.Body = $params.Body | ConvertTo-Json

    try
    {
        # Invoke the Azure DevOps REST API to create the project
        $response = Invoke-AzDevOpsApiRestMethod @params

        if ($null -eq $response)
        {
            Throw "[New-DevOpsProject] Failed to create the Azure DevOps project: No response returned"
        }

        # Project creation is asynchronous. Unless told otherwise, wait until the project
        # reaches the 'wellFormed' state so that callers (and child-resource creation) do not
        # race against provisioning and hit 'TF200016: project does not exist'.
        if (-not $NoWait)
        {
            Write-Verbose "[New-DevOpsProject] Waiting up to $TimeoutSeconds s for project '$ProjectName' to reach 'wellFormed' state."
            $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
            do
            {
                Start-Sleep -Seconds 3
                $project = $null
                try
                {
                    $project = List-DevOpsProjects -OrganizationName $Organization -StateFilter all |
                        Where-Object { $_.name -eq $ProjectName } | Select-Object -First 1
                }
                catch
                {
                    Write-Verbose "[New-DevOpsProject] Polling project state failed (will retry): $_"
                }

                $state = $project.state
                Write-Verbose "[New-DevOpsProject] Project '$ProjectName' state: $state"
            }
            while ($state -ne 'wellFormed' -and (Get-Date) -lt $deadline)

            if ($state -ne 'wellFormed')
            {
                Throw "[New-DevOpsProject] Project '$ProjectName' did not reach 'wellFormed' state within $TimeoutSeconds seconds (last state: '$state')."
            }

            Write-Verbose "[New-DevOpsProject] Project '$ProjectName' is now 'wellFormed'."
        }

        # Output the response which contains the created project details
        return $response
    }
    catch
    {
        throw "[New-DevOpsProject] Failed to create project '$ProjectName' in '$Organization': $_"
    }
}
