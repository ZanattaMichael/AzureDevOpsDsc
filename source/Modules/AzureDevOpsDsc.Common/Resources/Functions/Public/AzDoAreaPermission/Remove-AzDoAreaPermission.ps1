Function Remove-AzDoAreaPermission
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


    Write-Verbose "[Remove-AzDoAreaPermission] Started."

    #
    # Test if the AreaPath is specified
    if ([String]::IsNullOrEmpty($AreaPath))
    {
        Write-Warning "[Remove-AzDoAreaPermission] Area Path Name not specified. Defaulting to top-level Project permissions."
        Write-Warning "[Remove-AzDoAreaPermission] STOPPING. It is not possible to remove permissions from a top-level Project."
        return
    }

    #
    # Security Namespace ID

    # Get the Security Namespace
    $SecurityNamespace  = Get-CacheItem -Key 'CSS' -Type 'SecurityNamespaces'

    # If the Security Namespace is null, return
    if (-not $SecurityNamespace)
    {
        Write-Error "[Remove-AzDoAreaPermission] Security Namespace not found."
        return
    }

    # Get the Project
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # If the Project is null, return
    if (-not $Project)
    {
        Write-Error "[Remove-AzDoAreaPermission] Project not found."
        return
    }

    # Get the Area Path
    $AreaPath = Get-CacheItem -Key "\$ProjectName\Area\" -Type 'LiveAreaNodes'

    # If the AreaPath is null, return
    if (-not $AreaPath)
    {
        Write-Error "[Remove-AzDoAreaPermission] AreaPath not found."
        return
    }

    # Get the ACLs
    $DescriptorACLList  = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

    # If the ACLs are null, return
    if (-not $DescriptorACLList)
    {
        Write-Error "[Remove-AzDoAreaPermission] ACLs not found."
        return
    }

    #
    # Check the ACLs to see if the token identifier exists

    $token = $(($LookupResult.propertiesChanged.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    # Test if the Token exists
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    # If the ACLs are not null, remove them
    if ($Filtered)
    {

        Write-Verbose "[Remove-AzDoAreaPermission] Attempting to remove ACLs."

        $params = @{
            OrganizationName = $Global:DSCAZDO_OrganizationName
            SecurityNamespaceID = $SecurityNamespace.namespaceId
            TokenName = $token
        }

    $params | Export-CLixml 'C:\temp\Remove-AzDoAreaPermission.clixml'

        # Remove the ACLs
        #Remove-AzDoPermission @params

    }

}
