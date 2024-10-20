Function New-AzDoProjectGroup {

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

        [Parameter(Mandatory)]
        [Alias('Project')]
        [System.String]$ProjectName,

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
        ProjectScopeDescriptor = (Get-CacheItem -Key $ProjectName -Type 'LiveProjects').ProjectDescriptor
    }

    # If the project scope descriptor is not found, write a warning message to the console and return.
    if ($null -eq $params.ProjectScopeDescriptor) {
        Write-Warning "[New-AzDoProjectGroup] Unable to find project scope descriptor for project '$ProjectName'. Aborting group creation."
        return
    }

    # Write verbose log before creating a new group
    Write-Verbose "[New-AzDoProjectGroup] Creating a new DevOps group with the following parameters: $($params | Out-String)"

    # Create a new group
    $group = New-DevOpsGroup @params

    # Write verbose log after group creation
    Write-Verbose "[New-AzDoProjectGroup] New DevOps group created: $($group | Out-String)"

    # Update the cache with the new group
    Refresh-CacheIdentity -Identity $group -Key $group.principalName -CacheType 'LiveGroups'

    Add-CacheItem -Key $group.principalName -Value $group -Type 'Group'
    Write-Verbose "[New-AzDoProjectGroup] Added new group to Group cache with key: $($group.principalName)"

    Set-CacheObject -Content $Global:AzDoGroup -CacheType 'Group'
    Write-Verbose "[New-AzDoProjectGroup] Updated global AzDoGroup cache object."

}
