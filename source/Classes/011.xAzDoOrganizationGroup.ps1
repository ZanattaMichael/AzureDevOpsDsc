<#
.SYNOPSIS
    This class represents an Azure DevOps organization group.

.DESCRIPTION
    The xAzDoOrganizationGroup class is a DSC resource that allows you to manage Azure DevOps organization groups.
    It provides properties to specify the group name, display name, and description.

.NOTES
    Author: Your Name
    Date:   Current Date

.LINK
    GitHub Repository: <link to the GitHub repository>

.PARAMETER GroupName
    The name of the organization group.
    This property is mandatory and serves as the key property for the resource.

.PARAMETER GroupDisplayName
    The display name of the organization group.
    This property is mandatory and serves as the key property for the resource.

.PARAMETER GroupDescription
    The description of the organization group.

.INPUTS
    None.

.OUTPUTS
    None.

.EXAMPLE
    This example shows how to create an instance of the xAzDoOrganizationGroup class:

    $organizationGroup = [xAzDoOrganizationGroup]::new()
    $organizationGroup.GroupName = "MyGroup"
    $organizationGroup.GroupDisplayName = "My Group"
    $organizationGroup.GroupDescription = "This is my group."

    $organizationGroup.Get()

#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class xAzDoOrganizationGroup : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$GroupName

    [DscProperty()]
    [Alias('DisplayName')]
    [System.String]$GroupDisplayName

    [DscProperty()]
    [Alias('Description')]
    [System.String]$GroupDescription

    xAzDoOrganizationGroup()
    {

        # Import the AzureDevOpsDsc.Common module using the $true argument to bypassing the cache flush
        Import-Module AzureDevOpsDsc.Common -ArgumentList @($true)

        # Check if the Managed Identity Token exists. If not create one.
        if (-not($Global:DSCAZDO_ManagedIdentityToken))
        {
            # Create a Managed Identity Token
            New-AzManagedIdentity -OrganizationName "akkodistestorg" -Verbose -Debug
        }

        # Initialize the cache object
        Initialize-CacheObject -CacheType 'Group' -BypassFileCheck -Debug
        Initialize-CacheObject -CacheType 'LiveGroups' -BypassFileCheck -Debug
    }

    [xAzDoOrganizationGroup] Get()
    {
        return [xAzDoOrganizationGroup]$($this.GetDscCurrentStateProperties())
    }

    hidden [HashTable] getDscCurrentAPIState()
    {
        # Get the current state of the resource
        $params = @{
            GroupName = $this.GroupName
            GroupDisplayName = $this.GroupDisplayName
            GroupDescription = $this.GroupDescription
        }

        return Get-xAzDoOrganizationGroup @params

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
        $properties.GroupDisplayName    = $CurrentResourceObject.GroupDisplayName
        $properties.GroupDescription    = $CurrentResourceObject.GroupDescription
        $properties.Ensure              = $CurrentResourceObject.Ensure
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        #$properties.Reasons             = $CurrentResourceObject.LookupResult.Reasons

        Write-Verbose "[xAzDoOrganizationGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
