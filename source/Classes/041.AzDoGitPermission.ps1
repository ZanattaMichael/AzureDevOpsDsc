<#
.SYNOPSIS
    This class represents an Azure DevOps DSC resource for managing Git permissions.

.DESCRIPTION
    The AzDoGitPermission class is a DSC resource that allows you to manage Git permissions in Azure DevOps. It inherits from the AzDevOpsDscResourceBase class and provides properties and methods for managing Git permissions.

.PARAMETER ProjectName
    Specifies the name of the Azure DevOps project.

.PARAMETER RepositoryName
    Specifies the name of the Git repository.

.PARAMETER isInherited
    Specifies whether the permissions are inherited from the parent repository. Default value is $true.

.PARAMETER BranchName
    Optional. Targets a single branch's ACL (the 'refs/heads/{BranchName}' token) rather than the
    repository's own ACL. Write it as a bare ref name, e.g. 'main' or 'release/1.0' - a leading
    'refs/heads/' is accepted and stripped for comparison, but the value stored back is always what
    the configuration supplied. Requires RepositoryName. Mutually exclusive with TagName.

.PARAMETER TagName
    Optional. Targets a single tag's ACL (the 'refs/tags/{TagName}' token) rather than the
    repository's own ACL. Same rules as BranchName. Requires RepositoryName. Mutually exclusive
    with BranchName.

.PARAMETER PermissionsList
    Specifies the list of permissions to be set for the repository.

.NOTES
    This class is part of the AzureDevOpsDSC module.

.LINK
    https://github.com/ZanattaMichael/AzureDevOpsDsc

.EXAMPLE
    This example shows how to use the AzDoGitPermission class to manage Git permissions in Azure DevOps.

    Configuration Example {
        Import-DscResource -ModuleName AzureDevOpsDSC

        Node localhost {
            AzDoGitPermission GitPermission {
                ProjectName = 'MyProject'
                RepositoryName = 'MyRepository'
                PermissionsList = @('Read', 'Contribute')
                Ensure = 'Present'
            }
        }
    }

#>

[DscResource()]
class AzDoGitPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Repository')]
    [System.String]$RepositoryName = $null

    [DscProperty()]
    [Alias('Inherited')]
    [System.Boolean]$isInherited=$true

    [DscProperty()]
    [System.String]$BranchName = $null

    [DscProperty()]
    [System.String]$TagName = $null

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoGitPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoGitPermission] Get()
    {
        return [AzDoGitPermission]$($this.GetDscCurrentStateProperties())
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

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName           = $CurrentResourceObject.ProjectName
        $properties.RepositoryName        = $CurrentResourceObject.RepositoryName
        $properties.isInherited           = $CurrentResourceObject.isInherited
        $properties.BranchName            = $CurrentResourceObject.BranchName
        $properties.TagName               = $CurrentResourceObject.TagName
        $properties.Permissions           = $CurrentResourceObject.Permissions
        $properties.lookupResult          = $CurrentResourceObject.lookupResult
        $properties.Ensure                = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoGitPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
