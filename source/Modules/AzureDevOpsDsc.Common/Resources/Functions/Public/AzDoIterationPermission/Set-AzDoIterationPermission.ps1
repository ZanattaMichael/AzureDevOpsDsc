Function Set-AzDoIterationPermission
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

    Write-Verbose "[Set-AzDoIterationPermission] Started."

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'Iteration' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ($SecurityNamespace -eq $null)
    {
        Write-Error "[Set-AzDoIterationPermission] Security Namespace not found."
        return
    }

    if ($Project -eq $null)
    {
        Write-Error "[Set-AzDoIterationPermission] Project not found."
        return
    }

    #
    # Serialize the ACLs

    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    # More work is needed here.
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
    # If the Iteration is not specified, this dictates that the permissions are for the Project.
    # Because of this we need to remove the ACE's that need to be removed prior to setting the new permissions.
    if (-not $IterationPath) {
        Write-Verbose "[Set-AzDoIterationPermission] Clearing ACEs."
        $params.ClearACEs = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    #
    # Set the Iteration Permissions

    Write-Verbose "[Set-AzDoIterationPermission] Parameters: $($params | ConvertTo-Json -Depth 5)"
    Set-AzDoPermission @params

}
