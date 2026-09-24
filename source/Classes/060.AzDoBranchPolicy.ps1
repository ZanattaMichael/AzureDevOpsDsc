<#
.SYNOPSIS
    DSC resource for managing Azure DevOps branch policies.

.DESCRIPTION
    The AzDoBranchPolicy class manages branch policy configurations on a Git
    repository branch within an Azure DevOps project. A policy's full scope is
    a repository, a ref and how the ref is matched; RepositoryName and
    BranchName can each be left empty to widen that scope (see below), and
    PolicySettings drift is detected on whichever keys the configuration
    states, so raising an approver count or changing a build definition id is
    caught by Test() like any other property.

.PARAMETER ProjectName
    The Azure DevOps project name.

.PARAMETER RepositoryName
    The Git repository name. Leave empty for a cross-repository policy scope
    that applies to every repository in the project.

.PARAMETER BranchName
    The branch ref name (with or without the 'refs/heads/' prefix), or a
    branch-name prefix when MatchKind is 'Prefix' (e.g. 'release/' matches
    every 'release/*' branch). Leave empty for a repository-wide policy scope
    with no branch restriction - only meaningful for policy types that do not
    require a ref, such as the repository settings policies (file size
    restriction, path length restriction, reserved names restriction, file
    name restriction, commit author email validation).

.PARAMETER PolicyType
    The policy type display name (e.g. 'MinimumReviewerCount').

.PARAMETER PolicyIdentifier
    Optional. Azure DevOps allows several policies of the same PolicyType in
    the same scope (two build validation policies pointing at different
    pipelines, several status checks, a required-reviewers policy per path
    filter) but this resource has exactly one Key property (ProjectName), so
    a second discriminator is needed to give each one a stable identity. Set
    this to a value that appears among that policy's PolicySettings - a
    buildDefinitionId, a status check's name, a required reviewer's display
    name - and it is used, together with PolicyType and the scope, to tell
    the policies apart. Leaving it unset behaves exactly as before this
    property existed: the first policy of that type found in the scope is
    used, so a single-policy-per-type configuration needs no change.

.PARAMETER MatchKind
    Optional. 'Exact' (default) matches BranchName as one branch. 'Prefix'
    matches every branch whose ref name starts with BranchName.

.PARAMETER isEnabled
    Whether the policy is enabled. Default is $true.

.PARAMETER isBlocking
    Whether the policy is blocking. Default is $true.

.PARAMETER PolicySettings
    Policy-type-specific settings hashtable. Only the keys present here are
    compared against the live policy's settings when checking for drift - a
    key the configuration does not state is left alone, never read as "must
    be empty". A 'scope' key, if supplied, overrides the scope this resource
    would otherwise build from RepositoryName/BranchName/MatchKind.
#>

[DscResource()]
class AzDoBranchPolicy : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty()]
    [System.String]$RepositoryName = ''

    [DscProperty()]
    [System.String]$BranchName = ''

    [DscProperty(Mandatory)]
    [System.String]$PolicyType

    [DscProperty()]
    [System.String]$PolicyIdentifier

    [DscProperty()]
    [ValidateSet('Exact', 'Prefix')]
    [System.String]$MatchKind = 'Exact'

    [DscProperty()]
    [System.Boolean]$isEnabled = $true

    [DscProperty()]
    [System.Boolean]$isBlocking = $true

    [DscProperty()]
    [HashTable]$PolicySettings

    AzDoBranchPolicy()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoBranchPolicy] Get()
    {
        return [AzDoBranchPolicy]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName       = $CurrentResourceObject.ProjectName
        $properties.RepositoryName    = $CurrentResourceObject.RepositoryName
        $properties.BranchName        = $CurrentResourceObject.BranchName
        $properties.PolicyType        = $CurrentResourceObject.PolicyType
        $properties.PolicyIdentifier  = $CurrentResourceObject.PolicyIdentifier
        $properties.MatchKind         = $CurrentResourceObject.MatchKind
        $properties.isEnabled         = $CurrentResourceObject.isEnabled
        $properties.isBlocking        = $CurrentResourceObject.isBlocking
        $properties.PolicySettings    = $CurrentResourceObject.PolicySettings
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoBranchPolicy] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
