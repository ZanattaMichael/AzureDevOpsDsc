<#
.SYNOPSIS
Retrieves an Azure DevOps Git repository from the live and local cache.

.DESCRIPTION
The Get-AzDoGitRepository function attempts to retrieve an Azure DevOps Git repository based on the provided project and repository names. It first checks the live cache for the repository and returns the repository object if found. If the repository is not found in the live cache, it returns a status indicating that the repository was not found.

'SourceRepository', 'SourceType' and 'ImportServiceConnectionName' seed a repository only at
creation time (see 'GetDscResourcePropertyNamesWithNoSetSupport()' on the 'AzDoGitRepository'
class) and are never compared here - an existing repository never drifts against them. 'IsDisabled'
is a plain repository property the API can update at any time, so it is the only property compared
against the live repository.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER RepositoryName
The name of the Azure DevOps Git repository.

.PARAMETER SourceRepository
(Optional) Create-time only - not compared. See DESCRIPTION.

.PARAMETER SourceType
(Optional) Create-time only - not compared. See DESCRIPTION.

.PARAMETER ImportServiceConnectionName
(Optional) Create-time only - not compared. See DESCRIPTION.

.PARAMETER IsDisabled
(Optional) The desired disabled state of the repository. Compared against the live repository's
'isDisabled' value.

.PARAMETER LookupResult
(Optional) A hashtable to store lookup results.

.PARAMETER Ensure
(Optional) Specifies the desired state of the repository.

.PARAMETER Force
(Optional) A switch parameter to force the operation.

.OUTPUTS
System.Management.Automation.PSObject[]
Returns a hashtable detailing the repository status and properties.

.EXAMPLE
PS C:\> Get-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo"

This command retrieves the "MyRepo" repository from the "MyProject" project.

#>
Function Get-AzDoGitRepository
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
        [Alias('Source')]
        [System.String]$SourceRepository,

        [Parameter()]
        [Alias('SourceKind')]
        [System.String]$SourceType,

        [Parameter()]
        [Alias('ServiceConnection')]
        [System.String]$ImportServiceConnectionName,

        [Parameter()]
        [System.Boolean]$IsDisabled,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    #
    # Construct a hashtable detailing the group

    $getRepositoryResult = @{
        #Reasons = $()
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        status = $null
    }

    #
    # Attempt to retrive the Project Group from the Live and Local Cache.
    Write-Verbose "[Get-AzDoGitRepository] Retriving the Project Group from the Live and Local Cache."

    # Format the Key for the Project Group.
    $projectGroupKey = "$ProjectName\$RepositoryName"

    # Retrive the Repositories from the Live Cache.
    $repository = Get-CacheItem -Key $projectGroupKey -Type 'LiveRepositories'

    # If the Repository exists in the Live Cache, return the Repository object.
    if ($repository)
    {
        Write-Verbose "[Get-AzDoGitRepository] The Repository '$RepositoryName' was found in the Live Cache."

        $getRepositoryResult.liveCache    = $repository
        $getRepositoryResult.RepositoryId = $repository.id

        # Only 'IsDisabled' is ever compared on an existing repository - see DESCRIPTION.
        $currentIsDisabled = [System.Boolean]$repository.isDisabled

        if ($PSBoundParameters.ContainsKey('IsDisabled') -and ($currentIsDisabled -ne $IsDisabled))
        {
            Write-Verbose "[Get-AzDoGitRepository] 'IsDisabled' drift detected: current '$currentIsDisabled', desired '$IsDisabled'."
            $getRepositoryResult.status = [DSCGetSummaryState]::Changed
            $getRepositoryResult.propertiesChanged += 'IsDisabled'
        }
        else
        {
            $getRepositoryResult.status = [DSCGetSummaryState]::Unchanged
        }

        return $getRepositoryResult

    }
    else
    {
        Write-Verbose "[Get-AzDoGitRepository] The Repository '$RepositoryName' was not found in the Live Cache."
        $getRepositoryResult.status = [DSCGetSummaryState]::NotFound
    }

    # Return the Repository object.
    return $getRepositoryResult

}
