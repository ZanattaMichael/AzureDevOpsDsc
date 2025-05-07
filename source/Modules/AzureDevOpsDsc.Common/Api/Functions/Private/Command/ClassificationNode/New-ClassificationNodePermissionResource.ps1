Function New-ClassificationNodePermissionResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Iterations','Areas')]
        [String]$NodeType,

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

    Write-Verbose "[New-ClassificationNodePermissionResource] Started."

    #
    # Test if the Repository is specified
    if ([String]::IsNullOrEmpty($AreaPath))
    {
        Write-Warning "[New-ClassificationNodePermissionResource] AreaPath not specified. Defaulting to top-level Project permissions."
        Write-Warning "[New-ClassificationNodePermissionResource] STOPPING. It is not possible add permissions to a top-level Project."
        return
    }

    #
    # Security Namespace ID

    if ($NodeType -eq 'Areas')
    {
        $SecurityNamespace = 'CSS' # Manages area path object-level permissions.
    } else {
        $SecurityNamespace = 'Iterations' # Managed iteration path object-level permissions.
    }

    # Perform a lookup to get the security namespace and project details
    $SecurityNamespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if (($null -eq $SecurityNamespace) -or ($null -eq $Project))
    {
        Write-Warning "[New-ClassificationNodePermissionResource] Security Namespace or Project not found."
        return
    }

    #
    # Serialize the ACLs

    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $([regex]::Escape(($lookup.propertiesChanged.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':'))
    }

    $params = @{
        OrganizationName = $Global:DSCAZDO_OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    #
    # Set the Git Repository Permissions

    Set-AzDoPermission @params

}
