Function New-AzDoAreaPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$AreaPath,

        [Parameter(Mandatory = $true)]
        [bool]$isInherited,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[New-AzDoAreaPermission] Started."

    #
    # Test if the Repository is specified
    if ([String]::IsNullOrEmpty($AreaPath))
    {
        Write-Warning "[New-AzDoAreaPermission] Area Path Name not specified. Defaulting to top-level Project permissions."
        Write-Warning "[New-AzDoAreaPermission] STOPPING. It is not possible add permissions to a top-level Project."
        return
    }

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'CSS' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if (($null -eq $SecurityNamespace) -or ($null -eq $Project))
    {
        Write-Warning "[New-AzDoAreaPermission] Security Namespace or Project not found."
        return
    }

    #
    # Serialize the ACLs

    $token = $(($LookupResult.propertiesChanged.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $token
    }

    $params = @{
        OrganizationName = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    #
    # Set the Git Repository Permissions

    Write-Verbose "[New-AzDoAreaPermission] Setting Area Path Permissions for $ProjectName - $AreaPath"

    Set-AzDoPermission @params

    # Invalidate the LiveACLList cache so the next Get re-fetches from the API.
    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

}
