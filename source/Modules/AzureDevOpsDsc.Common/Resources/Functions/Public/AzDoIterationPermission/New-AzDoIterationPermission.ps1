Function New-AzDoIterationPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$IterationPath,

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

    Write-Verbose "[New-AzDoIterationPermission] Started."

    if ([String]::IsNullOrEmpty($IterationPath))
    {
        Write-Verbose "[New-AzDoIterationPermission] IterationPath not specified. Using top-level Project Iteration permissions."
    }

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'Iteration' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if (($null -eq $SecurityNamespace) -or ($null -eq $Project))
    {
        Write-Warning "[New-AzDoIterationPermission] Security Namespace or Project not found."
        return
    }

    #
    # Serialize the ACLs

    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

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

    Write-Verbose "[New-AzDoIterationPermission] Setting Iteration Path Permissions for $ProjectName - $IterationPath"

    Set-AzDoPermission @params

}
