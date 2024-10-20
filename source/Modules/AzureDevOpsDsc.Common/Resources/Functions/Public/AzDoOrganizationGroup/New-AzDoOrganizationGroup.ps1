Function New-AzDoOrganizationGroup {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory)]
        [Alias('Name')]
        [System.String]$GroupName,

        [Parameter()]
        [Alias('Description')]
        [System.String]$GroupDescription,

        [Parameter()]
        [Alias('Lookup')]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force

    )

    # Define parameters for creating a new DevOps group
    $params = @{
        GroupName = $GroupName
        GroupDescription = $GroupDescription
        ApiUri = "https://vssps.dev.azure.com/{0}" -f $Global:DSCAZDO_OrganizationName
    }

    # Write verbose log with the parameters used for creating the group
    Write-Verbose "[New-AzDoOrganizationGroup] Creating a new DevOps group with GroupName: '$($params.GroupName)', GroupDescription: '$($params.GroupDescription)' and ApiUri: '$($params.ApiUri)'"

    # Create a new group
    $group = New-DevOpsGroup @params

    # Update the cache with the new group
    Refresh-CacheIdentity -Identity $group -Key $group.principalName -CacheType 'LiveGroups'

    # Add the group to the Group cache and write to verbose log
    Add-CacheItem -Key $group.principalName -Value $group -Type 'Group'
    Write-Verbose "[New-AzDoOrganizationGroup] Added new group to Group cache with key: '$($group.principalName)'"

    # Update the global AzDoGroup object and write to verbose log
    Set-CacheObject -Content $Global:AzDoGroup -CacheType 'Group'
    Write-Verbose "[New-AzDoOrganizationGroup] Updated global AzDoGroup cache object."


}
