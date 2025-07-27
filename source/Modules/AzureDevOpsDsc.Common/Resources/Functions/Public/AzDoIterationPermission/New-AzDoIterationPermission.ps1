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

    #
    # Test if the Repository is specified
    if ([String]::IsNullOrEmpty($IterationPath))
    {
        Write-Warning "[New-AzDoIterationPermission] Iteration Path Name not specified. Defaulting to top-level Project permissions."
        Write-Warning "[New-AzDoIterationPermission] STOPPING. It is not possible add permissions to a top-level Project."
        return
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

    #TODO CONSTRUCT TOKEN OBJECT.
    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $token
    }

    $serializeACLParams | Export-Clixml C:\Temp\SerializeACLParams.xml


    $params = @{
        OrganizationName = $Global:DSCAZDO_OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    $params | Export-Clixml C:\Temp\params.clixml
    #
    # Set the Git Repository Permissions

    Write-Verbose "[New-AzDoIterationPermission] Setting Iteration Path Permissions for $ProjectName - $IterationPath"

    Set-AzDoPermission @params

}
