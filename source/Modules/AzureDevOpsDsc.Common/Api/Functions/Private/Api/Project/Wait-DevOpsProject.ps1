<#
.SYNOPSIS
    Waits for a project to be created in Azure DevOps.

.DESCRIPTION
    The Wait-DevOpsProject function waits for a project to be created in Azure DevOps. It checks the status of the project creation and waits until the project is either created successfully or fails to be created.

.PARAMETER OrganizationName
    The name of the Azure DevOps organization.

.PARAMETER ProjectURL
    The URL of the project to wait for.

.PARAMETER ApiVersion
    The version of the Azure DevOps API to use. If not specified, the default API version will be used.

.EXAMPLE
    Wait-DevOpsProject -OrganizationName "MyOrg" -ProjectURL "https://dev.azure.com/MyOrg/MyProject"

.NOTES
    Author: Michael Zanatta
    Date: 2025-01-06
#>

Function Wait-DevOpsProject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectURL,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    $params = @{
        Uri    = '{0}' -f $ProjectURL
        Method = "GET"
    }

    Write-Verbose "[Wait-DevOpsProject] URI: $($params.URI)"

    # Loop until the project reaches a terminal status.
    #
    # 'break' inside a switch leaves the switch, not the enclosing do/while, so the
    # loop used to run its full ten iterations no matter what the API reported and
    # the '$counter -ge 10' check afterwards was therefore always true - every call
    # slept 50 seconds and then wrote a spurious timeout error. Track completion
    # explicitly instead.
    $maxAttempts = 10
    $counter     = 0
    $completed   = $false

    do
    {
        Write-Verbose "[Wait-DevOpsProject] Sending request to check project status..."
        $response = Invoke-AzDevOpsApiRestMethod @params

        # Check the status of the project
        switch ($response.status)
        {
            'creating' {
                Write-Verbose "[Wait-DevOpsProject] Project is still being created..."
                Start-Sleep -Seconds 5
            }
            'wellFormed' {
                Write-Verbose "[Wait-DevOpsProject] Project has been created successfully."
                $completed = $true
            }
            'failed' {
                Write-Error "[Wait-DevOpsProject] Project creation failed: $response"
                $completed = $true
            }
            'notSet' {
                Write-Error "[Wait-DevOpsProject] Project creation status is not set: $response"
                $completed = $true
            }
            default {
                # Still creating
                Write-Verbose "[Wait-DevOpsProject] Project is still being created (default case)..."
                Start-Sleep -Seconds 5
            }
        }

        # Increment the counter
        $counter++

    } while ((-not $completed) -and ($counter -lt $maxAttempts))

    if (-not $completed)
    {
        Write-Error "[Wait-DevOpsProject] Timed out waiting for project to be created."
    }

}
