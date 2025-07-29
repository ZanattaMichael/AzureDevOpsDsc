Function Remove-AzDoIterationPermission
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


    Write-Verbose "[Remove-AzDoIterationPermission] Started."

    #
    # Test if the IterationPath is specified
    if ([String]::IsNullOrEmpty($IterationPath))
    {
        Write-Warning "[Remove-AzDoIterationPermission] Iteration Path Name not specified. Defaulting to top-level Project permissions."
        Write-Warning "[Remove-AzDoIterationPermission] STOPPING. It is not possible to remove permissions from a top-level Project."
        return
    }

    #
    # Security Namespace ID

    # Get the Security Namespace
    $SecurityNamespace  = Get-CacheItem -Key 'Iteration' -Type 'SecurityNamespaces'

    # If the Security Namespace is null, return
    if (-not $SecurityNamespace)
    {
        Write-Error "[Remove-AzDoIterationPermission] Security Namespace not found."
        return
    }

    # Get the Project
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # If the Project is null, return
    if (-not $Project)
    {
        Write-Error "[Remove-AzDoIterationPermission] Project not found."
        return
    }

    # Get the ACLs
    $DescriptorACLList  = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

    # If the ACLs are null, return
    if (-not $DescriptorACLList)
    {
        Write-Error "[Remove-AzDoIterationPermission] ACLs not found."
        return
    }

    #
    # Check the ACLs to see if the token identifier exists

    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    # Test if the Token exists
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    # If the ACLs are not null, remove them
    if ($Filtered)
    {

        Write-Verbose "[Remove-AzDoIterationPermission] Attempting to remove ACLs."

        $params = @{
            OrganizationName = $Global:DSCAZDO_OrganizationName
            SecurityNamespaceID = $SecurityNamespace.namespaceId
            TokenName = $token
        }

        # Remove the ACLs
        Remove-AzDoPermission @params

    }

}
