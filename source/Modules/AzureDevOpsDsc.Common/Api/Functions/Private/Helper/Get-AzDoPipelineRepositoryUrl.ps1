<#
.SYNOPSIS
Returns the clone URL a build definition records for a pipeline's repository.

.DESCRIPTION
A pipeline is updated by writing its build definition back (see 'Set-DevOpsPipeline'), and when
the repository changes the definition's 'repository.url' has to change with it. An Azure Repos
repository reports its own 'remoteUrl'. An external repository has no object of its own to read,
so its URL is built from its 'owner/repo' name: on github.com or bitbucket.org, or on the GitHub
Enterprise server the service connection points at.

.PARAMETER RepositoryType
The build definition repository type: 'TfsGit', 'GitHub', 'GitHubEnterprise' or 'Bitbucket'.

.PARAMETER RepositoryName
The repository name: an Azure Repos repository name, or 'owner/repo' for an external repository.

.PARAMETER Repository
The Azure Repos repository object. Used only when 'RepositoryType' is 'TfsGit'.

.PARAMETER ServiceConnection
The service connection object. Used only when 'RepositoryType' is 'GitHubEnterprise'.

.EXAMPLE
Get-AzDoPipelineRepositoryUrl -RepositoryType 'GitHub' -RepositoryName 'contoso/app'
Returns 'https://github.com/contoso/app.git'.
#>
Function Get-AzDoPipelineRepositoryUrl
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')]
        [System.String]$RepositoryType,

        [Parameter(Mandatory = $true)]
        [System.String]$RepositoryName,

        [Parameter()]
        [System.Object]$Repository,

        [Parameter()]
        [System.Object]$ServiceConnection
    )

    switch ($RepositoryType)
    {
        'TfsGit'    { return $(if ($Repository) { [string]$Repository.remoteUrl } else { $null }) }
        'GitHub'    { return 'https://github.com/{0}.git' -f $RepositoryName }
        'Bitbucket' { return 'https://bitbucket.org/{0}.git' -f $RepositoryName }
        'GitHubEnterprise'
        {
            if ($ServiceConnection -and -not [String]::IsNullOrWhiteSpace($ServiceConnection.url))
            {
                return '{0}/{1}.git' -f ([string]$ServiceConnection.url).TrimEnd('/'), $RepositoryName
            }
            return $null
        }
    }
}
