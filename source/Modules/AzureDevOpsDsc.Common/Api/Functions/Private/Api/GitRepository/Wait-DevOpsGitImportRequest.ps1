<#
.SYNOPSIS
Polls an Azure DevOps Git import request until it reaches a terminal status.

.DESCRIPTION
The `Wait-DevOpsGitImportRequest` function repeatedly queries an import request created by
`New-GitImportRequest` until it reports 'completed', 'failed' or 'abandoned', or until the wait
times out. A repository that was requested to be imported must never be left silently empty - a
'failed'/'abandoned' outcome, and a timeout, are both surfaced as a terminating error rather than
being swallowed.

.PARAMETER ApiUri
The base URI of the Azure DevOps API.

.PARAMETER Project
The project containing the repository. This should include at least the project name.

.PARAMETER Repository
The repository the import request was created against. This should include at least the repository id.

.PARAMETER ImportRequestId
The id of the import request to poll, as returned by `New-GitImportRequest`.

.PARAMETER WaitIntervalMs
(Optional) The number of milliseconds to wait between polls. Defaults to `Get-AzDevOpsApiWaitIntervalMs`.

.PARAMETER WaitTimeoutMs
(Optional) The maximum number of milliseconds to wait for the import to complete before giving up. Defaults to `Get-AzDevOpsApiWaitTimeoutMs`.

.PARAMETER ApiVersion
(Optional) The API version to use for the Azure DevOps REST API. Defaults to the version returned by `Get-AzDevOpsApiVersion -Default`.

.OUTPUTS
System.Management.Automation.PSObject
Returns the final import request object once it has completed successfully.

.EXAMPLE
PS> Wait-DevOpsGitImportRequest -ApiUri "https://dev.azure.com/organization" -Project $project -Repository $repo -ImportRequestId $importRequest.importRequestId

.NOTES
This function requires the `Invoke-AzDevOpsApiRestMethod` function to be defined and available in the session.
#>
Function Wait-DevOpsGitImportRequest
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('URI')]
        [System.String]$ApiUri,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [Object]$Project,

        [Parameter(Mandatory = $true)]
        [Alias('Repo')]
        [Object]$Repository,

        [Parameter(Mandatory = $true)]
        [Alias('Id')]
        [System.String]$ImportRequestId,

        [Parameter()]
        [Int32]
        $WaitIntervalMs = $(Get-AzDevOpsApiWaitIntervalMs),

        [Parameter()]
        [Int32]
        $WaitTimeoutMs = $(Get-AzDevOpsApiWaitTimeoutMs),

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    $params = @{
        ApiUri = '{0}/{1}/_apis/git/repositories/{2}/importRequests/{3}?api-version={4}' -f $ApiUri.TrimEnd('/'), $Project.name, $Repository.id, $ImportRequestId, $ApiVersion
        Method = 'GET'
    }

    Write-Verbose "[Wait-DevOpsGitImportRequest] URI: $($params.ApiUri)"

    # Loop until the import request reaches a terminal status. Mirrors the do/while + explicit
    # '$completed' flag pattern used by 'Wait-DevOpsProject' - a 'switch'/'break' loop only breaks
    # out of the switch, not the enclosing loop, and silently runs to the iteration cap regardless
    # of the reported status.
    $startTime = Get-Date
    $completed = $false
    $result    = $null

    do
    {
        Write-Verbose "[Wait-DevOpsGitImportRequest] Checking import request '$ImportRequestId' status..."
        $result = Invoke-AzDevOpsApiRestMethod @params

        switch ($result.status)
        {
            { $_ -in 'queued', 'started' } {
                Write-Verbose "[Wait-DevOpsGitImportRequest] Import is still in progress (status: $_)..."
                Start-Sleep -Milliseconds $WaitIntervalMs
            }
            'completed' {
                Write-Verbose "[Wait-DevOpsGitImportRequest] Import completed successfully."
                $completed = $true
            }
            { $_ -in 'failed', 'abandoned' } {
                $errorMessage = $result.detailedStatus.errorMessage
                Write-Error "[Wait-DevOpsGitImportRequest] Import request '$ImportRequestId' ended with status '$($result.status)'$(if ($errorMessage) { ": $errorMessage" })"
                $completed = $true
            }
            default {
                Write-Verbose "[Wait-DevOpsGitImportRequest] Import is still in progress (default case, status: $($result.status))..."
                Start-Sleep -Milliseconds $WaitIntervalMs
            }
        }

    } while ((-not $completed) -and (-not (Test-AzDevOpsApiTimeoutExceeded -StartTime $startTime -EndTime (Get-Date) -TimeoutMs $WaitTimeoutMs)))

    if (-not $completed)
    {
        Write-Error "[Wait-DevOpsGitImportRequest] Timed out waiting for import request '$ImportRequestId' to complete."
        return $result
    }

    return $result

}
