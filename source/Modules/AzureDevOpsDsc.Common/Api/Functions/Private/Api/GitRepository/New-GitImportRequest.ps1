<#
.SYNOPSIS
Starts an import request against a Git repository in Azure DevOps.

.DESCRIPTION
The `New-GitImportRequest` function requests that Azure DevOps import the contents of an external
Git repository (identified by a URL) into an existing, typically empty, repository. The import
itself is asynchronous - this function only submits the request; use `Wait-DevOpsGitImportRequest`
to poll it to completion.

.PARAMETER ApiUri
The base URI of the Azure DevOps API.

.PARAMETER Project
The project containing the repository. This should include at least the project name.

.PARAMETER Repository
The (already-created) repository to import into. This should include at least the repository id.

.PARAMETER SourceUrl
The URL of the external Git repository to import from, e.g. 'https://github.com/MyUser/MyRepo.git'.

.PARAMETER ServiceEndpointId
(Optional) The id of a service endpoint (service connection) holding the credentials needed to
access a private 'SourceUrl'. Omit for a public source.

.PARAMETER ApiVersion
(Optional) The API version to use for the Azure DevOps REST API. Defaults to the version returned by `Get-AzDevOpsApiVersion -Default`.

.OUTPUTS
System.Management.Automation.PSObject
Returns the created import request object, including its 'status' and 'importRequestId'.

.EXAMPLE
PS> New-GitImportRequest -ApiUri "https://dev.azure.com/organization" -Project $project -Repository $repo -SourceUrl "https://github.com/MyUser/MyRepo.git"

.EXAMPLE
PS> New-GitImportRequest -ApiUri "https://dev.azure.com/organization" -Project $project -Repository $repo -SourceUrl "https://github.com/MyOrg/PrivateRepo.git" -ServiceEndpointId $endpointId

.NOTES
This function requires the `Invoke-AzDevOpsApiRestMethod` function to be defined and available in the session.
#>
Function New-GitImportRequest
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
        [Alias('Url', 'GitSourceUrl')]
        [System.String]$SourceUrl,

        [Parameter()]
        [System.String]$ServiceEndpointId,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    Write-Verbose "[New-GitImportRequest] Importing '$($SourceUrl)' into repository '$($Repository.name)' in project '$($Project.name)'"

    $body = @{
        parameters = @{
            gitSource = @{
                url = $SourceUrl
            }
        }
    }

    if ($ServiceEndpointId)
    {
        Write-Verbose "[New-GitImportRequest] Using service endpoint id '$($ServiceEndpointId)' for authentication"
        $body.parameters.serviceEndpointId = $ServiceEndpointId
    }

    # Define parameters for creating the import request
    $params = @{
        ApiUri = '{0}/{1}/_apis/git/repositories/{2}/importRequests?api-version={3}' -f $ApiUri.TrimEnd('/'), $Project.name, $Repository.id, $ApiVersion
        Method = 'POST'
        ContentType = 'application/json'
        Body = $body | ConvertTo-Json -Depth 5
    }

    # Try to invoke the REST method to create the import request and return the result
    try
    {
        $importRequest = Invoke-AzDevOpsApiRestMethod @params
        Write-Verbose "[New-GitImportRequest] Import request created: id '$($importRequest.importRequestId)', status '$($importRequest.status)'"
        return $importRequest
    }
    # Catch any exceptions and write an error message
    catch
    {
        Write-Error "[New-GitImportRequest] Failed to Create Import Request: $_"
    }

}
