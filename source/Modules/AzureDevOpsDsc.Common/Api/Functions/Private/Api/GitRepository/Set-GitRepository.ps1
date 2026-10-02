<#
.SYNOPSIS
Updates properties of an existing Git repository in an Azure DevOps project.

.DESCRIPTION
The `Set-GitRepository` function updates a Git repository's mutable properties - currently
'isDisabled' - via the Azure DevOps REST API. Unlike 'name'/'project', which require dedicated
operations (rename, move), 'isDisabled' is a plain PATCH and can be applied at any time.

.PARAMETER ApiUri
The base URI of the Azure DevOps API.

.PARAMETER Project
The project containing the repository. This should include at least the project name.

.PARAMETER Repository
The repository to update. This should include at least the repository id.

.PARAMETER IsDisabled
Whether the repository should be disabled ($true) or enabled ($false).

.PARAMETER ApiVersion
(Optional) The API version to use for the Azure DevOps REST API. Defaults to the version returned by `Get-AzDevOpsApiVersion -Default`.

.OUTPUTS
System.Management.Automation.PSObject[]
Returns the updated repository object if successful.

.EXAMPLE
PS> Set-GitRepository -ApiUri "https://dev.azure.com/organization" -Project $project -Repository $repo -IsDisabled $true

.NOTES
This function requires the `Invoke-AzDevOpsApiRestMethod` function to be defined and available in the session.
#>
Function Set-GitRepository
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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
        [System.Boolean]$IsDisabled,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    Write-Verbose "[Set-GitRepository] Setting 'isDisabled' = '$IsDisabled' on repository '$($Repository.name)' in project '$($Project.name)'"

    $body = @{
        isDisabled = $IsDisabled
    }

    # Define parameters for updating the repository
    $params = @{
        ApiUri = '{0}/{1}/_apis/git/repositories/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $Project.name, $Repository.id, $ApiVersion
        Method = 'PATCH'
        ContentType = 'application/json'
        Body = $body | ConvertTo-Json -Depth 5
    }

    # Try to invoke the REST method to update the repository and return the result
    try
    {
        $repo = Invoke-AzDevOpsApiRestMethod @params
        Write-Verbose "[Set-GitRepository] Repository Updated: '$($repo.name)'"
        return $repo
    }
    # Catch any exceptions and write an error message
    catch
    {
        Write-Error "[Set-GitRepository] Failed to Update Repository: $_"
    }

}
