Function Set-AzDoProjectPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoProjectPermission] Started."

    $OrganizationName  = Get-AzDoOrganizationName
    $SecurityNamespace = Get-CacheItem -Key 'Project' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if (-not $Project)
    {
        Write-Verbose "[Set-AzDoProjectPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $Project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($Project) { Add-CacheItem -Key $ProjectName -Value $Project -Type 'LiveProjects' }
    }

    if ((-not $SecurityNamespace) -or (-not $Project))
    {
        Write-Error "[Set-AzDoProjectPermission] Security namespace or project not found."
        return
    }

    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.ProjectPermission -f $Project.id)
    }

    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }

    # Explicitly delete the target descriptors' ACEs before the Set below, so it always starts
    # from a clean slate rather than whatever an earlier run (or a manual portal edit) left behind.
    $projectToken = '$PROJECT:vstfs:///Classification/TeamProject/{0}' -f $Project.id
    $targetDescriptors = @($LookupResult.propertiesChanged.aces | ForEach-Object { $_.Identity.value.ACLIdentity.descriptor } | Where-Object { $_ })
    if ($targetDescriptors)
    {
        $clearInput = @(
            @{
                token = @{
                    _token = $projectToken
                }
                aces  = $LookupResult.propertiesChanged.aces
            }
        )
        Clear-AzDoACE -OrganizationName $OrganizationName -SecurityNamespaceID $SecurityNamespace.namespaceId -DifferenceACLs $clearInput
    }

    Set-AzDoPermission @params
}
