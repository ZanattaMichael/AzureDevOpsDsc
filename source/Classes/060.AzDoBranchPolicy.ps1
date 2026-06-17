<#
.SYNOPSIS
    DSC resource for managing Azure DevOps branch policies.

.DESCRIPTION
    The AzDoBranchPolicy class manages branch policy configurations on a Git
    repository branch within an Azure DevOps project.

.PARAMETER ProjectName
    The Azure DevOps project name.

.PARAMETER RepositoryName
    The Git repository name.

.PARAMETER BranchName
    The branch ref name (e.g. 'refs/heads/main').

.PARAMETER PolicyType
    The policy type display name (e.g. 'MinimumReviewerCount').

.PARAMETER isEnabled
    Whether the policy is enabled. Default is $true.

.PARAMETER isBlocking
    Whether the policy is blocking. Default is $true.

.PARAMETER PolicySettings
    Policy-type-specific settings hashtable.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoBranchPolicy : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$RepositoryName

    [DscProperty(Mandatory)]
    [System.String]$BranchName

    [DscProperty(Mandatory)]
    [System.String]$PolicyType

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
        $properties.isEnabled         = $CurrentResourceObject.isEnabled
        $properties.isBlocking        = $CurrentResourceObject.isBlocking
        $properties.PolicySettings    = $CurrentResourceObject.PolicySettings
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoBranchPolicy] Current state properties: $($properties | Out-String)"

        return $properties
    }
}