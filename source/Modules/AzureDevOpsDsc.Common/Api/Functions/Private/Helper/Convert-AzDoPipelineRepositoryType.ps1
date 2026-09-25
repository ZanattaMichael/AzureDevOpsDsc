<#
.SYNOPSIS
Maps an 'AzDoPipeline' resource-side repository type to the value the Pipelines 'create' API
expects.

.DESCRIPTION
Two different Azure DevOps APIs use two different vocabularies for the same repository types.
Drift detection and updates both use the classic Build Definitions API, whose 'repository.type'
field is 'TfsGit' / 'GitHub' / 'GitHubEnterprise' / 'Bitbucket' - the same strings the
'AzDoPipeline' resource's 'RepositoryType' property uses, so no translation is needed there.
Creating a pipeline instead goes through the newer Pipelines API, whose
'configuration.repository.type' field uses a different casing ('azureReposGit', 'gitHub',
'gitHubEnterprise', 'bitbucket'). This function is the one place that translation happens.

.PARAMETER RepositoryType
The resource-side repository type, as validated on the 'AzDoPipeline' class.

.EXAMPLE
Convert-AzDoPipelineRepositoryType -RepositoryType 'GitHub'
Returns 'gitHub'.
#>
Function Convert-AzDoPipelineRepositoryType
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')]
        [System.String]$RepositoryType
    )

    switch ($RepositoryType)
    {
        'TfsGit' { return 'azureReposGit' }
        'GitHub' { return 'gitHub' }
        'GitHubEnterprise' { return 'gitHubEnterprise' }
        'Bitbucket' { return 'bitbucket' }
    }
}
