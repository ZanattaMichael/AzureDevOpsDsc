<#
.SYNOPSIS
    This class represents a DSC resource for managing Azure DevOps group members.

.DESCRIPTION
    The AzDoGroupMember class is a DSC resource that allows you to manage the members of an Azure DevOps group.
    It inherits from the AzDevOpsDscResourceBase class.

.NOTES
    Author: Your Name
    Date:   Current Date

.LINK
    GitHub Repository: <link to the GitHub repository>

.PARAMETER GroupName
    The name of the Azure DevOps group.

.PARAMETER GroupMembers
    An array of strings representing the members of the Azure DevOps group.

.EXAMPLE
    This example shows how to use the AzDoGroupMember resource to add members to an Azure DevOps group.

    Configuration Example {
        Import-DscResource -ModuleName AzDoGroupMember

        Node localhost {
            AzDoGroupMember GroupMember {
                GroupName = 'MyGroup'
                GroupMembers = @('User1', 'User2', 'User3')
                Ensure = 'Present'
            }
        }
    }

.INPUTS
    None

.OUTPUTS
    None

#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoGroupMember : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$GroupName

    [DscProperty(Mandatory)]
    [Alias('Members')]
    [System.String[]]$GroupMembers

    AzDoGroupMember()
    {
        $this.Construct()
    }

    [AzDoGroupMember] Get()
    {
        return [AzDoGroupMember]$($this.GetDscCurrentStateProperties())
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
        if ($null -eq $CurrentResourceObject) { return $properties }

        $properties.GroupName           = $CurrentResourceObject.GroupName
        $properties.GroupMembers        = $CurrentResourceObject.GroupMembers
        $properties.Ensure              = $CurrentResourceObject.Ensure
        $properties.LookupResult        = $CurrentResourceObject.LookupResult

        Write-Verbose "[xAzDoProjectGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
