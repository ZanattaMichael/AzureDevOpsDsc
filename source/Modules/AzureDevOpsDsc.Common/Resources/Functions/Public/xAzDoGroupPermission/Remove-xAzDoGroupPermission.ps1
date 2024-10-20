Function Remove-xAzDoGroupPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
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


    Write-Verbose "[New-xAzDoGitPermission] Started."

    #
    # Format the Group Name

    # Split the Group Name
    $split = $GroupName.Split('\').Split('/')

    # Test if the Group Name is valid
    if ($split.Count -ne 2) {
        Write-Warning "[Get-xAzDoProjectGroupPermission] Invalid Group Name: $GroupName"
        return
    }

    # Define the Project and Group Name
    $ProjectName = $split[0]
    $GroupName = $split[1]

    #
    # Security Namespace ID

    $SecurityNamespace  = Get-CacheItem -Key 'Identity' -Type 'SecurityNamespaces'
    $Project            = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $Repository         = Get-CacheItem -Key "$ProjectName\$RepositoryName" -Type 'LiveRepositories'
    $DescriptorACLList  = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

    #
    # Filter the ACLs that pertain to the Git Repository

    $searchString = "repoV2/{0}/{1}" -f $Project.id, $Repository.id

    # Test if the Token exists
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $searchString }

    # If the ACLs are not null, remove them
    if ($Filtered) {

        $params = @{
            OrganizationName = $Global:DSCAZDO_OrganizationName
            SecurityNamespaceID = $SecurityNamespace.namespaceId
            TokenName = $searchString
        }

        # Remove the ACLs
        Remove-xAzDoPermission @params

    }

}
