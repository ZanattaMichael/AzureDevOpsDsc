<#
.SYNOPSIS
Updates the configuration for an existing Azure DevOps Git repository.

.DESCRIPTION
The Set-AzDoGitRepository function updates an existing Azure DevOps Git repository. Only
'IsDisabled' is ever applied here - 'SourceRepository', 'SourceType' and
'ImportServiceConnectionName' seed a repository at creation time only (see
'New-AzDoGitRepository') and are listed in the class's 'GetDscResourcePropertyNamesWithNoSetSupport()',
so they are never passed to this function and an existing repository is never re-imported/re-forked.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER RepositoryName
The name of the Azure DevOps Git repository. This parameter is mandatory.

.PARAMETER IsDisabled
The desired disabled state of the repository.

.PARAMETER LookupResult
A hashtable containing lookup results. This parameter is optional.

.PARAMETER Ensure
Specifies whether the repository should be present or absent. This parameter is optional.

.PARAMETER Force
A switch parameter to force the operation. This parameter is optional.

.OUTPUTS
[System.Management.Automation.PSObject[]]
Returns an array of PSObject representing the result of the operation.

.EXAMPLE
Set-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo" -IsDisabled $true
#>
Function Set-AzDoGitRepository
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Alias('Repository')]
        [System.String]$RepositoryName,

        [Parameter()]
        [System.Boolean]$IsDisabled = $false,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[Set-AzDoGitRepository] Updating repository '$($RepositoryName)' in project '$($ProjectName)'"

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if ($null -eq $project)
    {
        Write-Error "[Set-AzDoGitRepository] Project '$($ProjectName)' not found. Skipping change."
        return
    }

    $repository = Get-CacheItem -Key "$ProjectName\$RepositoryName" -Type 'LiveRepositories'
    if ($null -eq $repository)
    {
        # Repository may have been created after the cache was built at init — fall back to a live lookup.
        $allRepos   = List-DevOpsGitRepository -OrganizationName (Get-AzDoOrganizationName) -ProjectName $ProjectName
        $repository = $allRepos | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
    }

    if ($null -eq $repository)
    {
        Write-Error "[Set-AzDoGitRepository] Repository '$RepositoryName' not found in project '$ProjectName'. Skipping change."
        return
    }

    # Define parameters for updating the repository
    $params = @{
        ApiUri     = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        Project    = $project
        Repository = $repository
        IsDisabled = $IsDisabled
    }

    $value = Set-GitRepository @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoGitRepository] Set-GitRepository returned null for repository '$RepositoryName' in project '$ProjectName'."
        return
    }

    # Update the LiveRepositories cache and write to verbose log
    Add-CacheItem -Key "$ProjectName\$RepositoryName" -Value $value -Type 'LiveRepositories'
    Export-CacheObject -CacheType 'LiveRepositories' -Content $AzDoLiveRepositories
    Refresh-CacheObject -CacheType 'LiveRepositories'
    Write-Verbose "[Set-AzDoGitRepository] Updated repository in LiveRepositories cache with key: '$ProjectName\$RepositoryName'"

}
