Function Remove-xAzDoOrganizationGroup {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (

        [Parameter(Mandatory)]
        [Alias('Name')]
        [System.String]$GroupName,

        [Parameter()]
        [Alias('DisplayName')]
        [System.String]$GroupDisplayName,

        [Parameter()]
        [Alias('Description')]
        [System.String]$GroupDescription,

        [Parameter()]
        [Alias('Lookup')]
        [System.String]$LookupResult

    )

    #
    # Format the Key According to the Principal Name

    $Key = Format-UserPrincipalName -Prefix '[TEAM FOUNDATION]' -GroupName $GroupName

    #
    # Check if the group exists in the live cache.

    $group = Get-CacheItem -Key $Key -Type 'LiveGroups'

    if ($null -eq $group) {
        $group = Get-AzDoOrganizationGroup -ApiUri $ApiUri -Pat $Pat -GroupDisplayName $GroupDisplayName
    }

    #
    # Remove the group from the API

    $params = @{
        ApiUri = $ApiUri
        GroupDescriptor = $group.Descriptor
    }

    # Remove the group from the API
    $null = Remove-DevOpsGroup @params

    #
    # Remove the group from the cache and live cache

    Remove-CacheItem -Key $Key -Type 'LiveGroups'

}
