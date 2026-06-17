<#
.SYNOPSIS
Converts a security TokenName to an ACL token based on the security namespace.

.DESCRIPTION
The New-ACLToken function converts a security TokenName to an ACL token based on the specified security namespace. It is used in the Azure DevOps DSC module to derive the token type and other relevant information for Git repositories.

.PARAMETER SecurityNamespace
Specifies the security namespace for which the ACL token needs to be generated.

.PARAMETER TokenName
Specifies the security TokenName that needs to be converted to an ACL token.

.OUTPUTS
The function returns a hashtable containing the following properties:
- type: The type of the ACL token (e.g., GitOrganization, GitProject, GitRepository, GitUnknown, UnknownSecurityNamespace).
- inherited: Indicates whether the security TokenName is inherited or not.
- projectId: The ID of the project associated with the ACL token (applicable for GitProject and GitRepository types).
- RepoId: The ID of the repository associated with the ACL token (applicable for GitRepository type).

.EXAMPLE
New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'Contoso/Org/Project'

This example converts the security TokenName 'Contoso/Org/Project' to an ACL token for the 'Git Repositories' security namespace. The resulting ACL token will have the type 'GitProject' and the project ID will be retrieved from the cache.

.NOTES
This function is part of the AzureDevOpsDsc.Common module and is used internally by other functions in the module.
#>

Function New-ACLToken
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$SecurityNamespace,

        [Parameter(Mandatory = $true)]
        [string]$TokenName

    )

    $TokenName = $TokenName.Replace('[', '').Replace(']', '')

    Write-Verbose "[New-ACLToken] Started."
    Write-Verbose "[New-ACLToken] Security Namespace: $SecurityNamespace"
    Write-Verbose "[New-ACLToken] Token Name: $TokenName"

    $result = @{}

    # Create a new ACL Object
    switch ($SecurityNamespace)
    {

        # Git Repositories
        'Git Repositories' {

            # Derive the Token Type GitOrganization, GitProject or GitRepository
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.OrganizationGit)
            {
                # Derive the Token Type GitOrganization
                $result.type = 'GitOrganization'
            }
            elseif ($TokenName -match $LocalizedDataAzResourceTokenPatten.GitProject)
            {
                # Derive the Token Type GitProject
                $result.type = 'GitProject'
                $result.projectId = (Get-CacheItem -Key $matches.ProjectName.Trim() -Type 'LiveProjects').id
            }
            elseif ($TokenName -match $LocalizedDataAzResourceTokenPatten.GitRepository)
            {
                # Derive the Token Type GitRepository
                $result.type = 'GitRepository'
                $result.projectId = (Get-CacheItem -Key $matches.ProjectName.Trim() -Type 'LiveProjects').id
                $result.RepoId = (Get-CacheItem -Key $TokenName -Type 'LiveRepositories').id
            }
            else
            {
                # Derive the Token Type GitUnknown
                $result.type = 'GitUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Git ACL Token Patterns."
            }
            break;
        }

        # Identity
        'Identity' {

            # Derive the Token Type Identity
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.GroupPermission)
            {
                # Derive the Token Type Identity
                $result.type = 'Identity'
                $result.projectId = $matches.ProjectId
                $result.groupId = $matches.GroupId
            }
            else
            {
                # Derive the Token Type Identity
                $result.type = 'GroupUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Identity ACL Token Patterns."
            }

            #$result.type = 'Identity'
            break;
        }

        # CSS
        'CSS' {

            # Use custom logic to extract the AreaPath from the token.
            # We cant use the regex variable as it it's a complex regex pattern.
            $regexMatches = [regex]::Matches($TokenName, $LocalizedDataAzResourceTokenPatten.AreaPathPermission)

            # Check if the match was successful
            if ($regexMatches.Count -eq 0)
            {
                $result.type = 'Unknown CSS'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Identity ACL Token Patterns."
                break
            }

            $result.Identifiers = @()
            $result.type = 'CSS'

            # Construct the token structure
            foreach ($match in $regexMatches) {
                $result.Identifiers += @{
                    identifier = $match.groups['identifiers'].value
                }
            }

            break;

        }
        # Iteration Path
        'Iteration' {

            # Use custom logic to extract the IterationPath from the token.
            # We cant use the regex variable as it it's a complex regex pattern.
            $regexMatches = [regex]::Matches($TokenName, $LocalizedDataAzResourceTokenPatten.IterationPathPermission)

            # Check if the match was successful
            if ($regexMatches.Count -eq 0)
            {
                $result.type = 'Unknown IterationPath'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Iteration Path ACL Token Patterns."
                break
            }

            $result.Identifiers = @()
            $result.type = 'Iteration'

            # Construct the token structure
            foreach ($match in $regexMatches) {
                $result.Identifiers += @{
                    identifier = $match.groups['identifiers'].value
                }
            }

            break;

        }

        # Project-level permissions  ($PROJECT:vstfs:///Classification/TeamProject/{id})
        'Project' {
            if ($TokenName -match $LocalizedDataAzACLTokenPatten.ProjectPermission)
            {
                $result.type      = 'Project'
                $result.ProjectId = $matches.ProjectId
            }
            else
            {
                $result.type = 'ProjectUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Project ACL Token Patterns."
            }
            break
        }

        # Build / Pipeline permissions — resolve pipeline name to numeric ID for the API token.
        'Build' {
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.BuildPermission)
            {
                $result.type      = 'Build'
                $result.ProjectId = (Get-CacheItem -Key $matches.ProjectName.Trim() -Type 'LiveProjects').id
                if ($matches.PipelineName) {
                    $pipelineCacheKey  = '{0}\{1}' -f $matches.ProjectName.Trim(), $matches.PipelineName.Trim()
                    $pipelineEntry     = Get-CacheItem -Key $pipelineCacheKey -Type 'LivePipelines'
                    $result.PipelineId = if ($pipelineEntry) { $pipelineEntry.id.ToString() } else { $matches.PipelineName.Trim() }
                }
            }
            else
            {
                $result.type = 'BuildUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Build ACL Token Patterns."
            }
            break
        }

        # Library / VariableGroup permissions — resolve variable group name to numeric ID.
        'Library' {
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.LibraryPermission)
            {
                $result.type      = 'Library'
                $result.ProjectId = (Get-CacheItem -Key $matches.ProjectName.Trim() -Type 'LiveProjects').id
                if ($matches.VariableGroupName) {
                    $vgCacheKey             = '{0}\{1}' -f $matches.ProjectName.Trim(), $matches.VariableGroupName.Trim()
                    $vgEntry                = Get-CacheItem -Key $vgCacheKey -Type 'LiveVariableGroups'
                    $result.VariableGroupId = if ($vgEntry) { $vgEntry.id.ToString() } else { $matches.VariableGroupName.Trim() }
                }
            }
            else
            {
                $result.type = 'LibraryUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known Library ACL Token Patterns."
            }
            break
        }

        # ServiceEndpoints / ServiceConnection permissions — resolve endpoint name to GUID.
        'ServiceEndpoints' {
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.ServiceEndpointPermission)
            {
                $result.type      = 'ServiceEndpoints'
                $result.ProjectId = (Get-CacheItem -Key $matches.ProjectName.Trim() -Type 'LiveProjects').id
                if ($matches.EndpointName) {
                    $scCacheKey        = '{0}\{1}' -f $matches.ProjectName.Trim(), $matches.EndpointName.Trim()
                    $scEntry           = Get-CacheItem -Key $scCacheKey -Type 'LiveServiceConnections'
                    $result.EndpointId = if ($scEntry) { $scEntry.id } else { $matches.EndpointName.Trim() }
                }
            }
            else
            {
                $result.type = 'ServiceEndpointsUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known ServiceEndpoints ACL Token Patterns."
            }
            break
        }

        # AgentPool permissions — TokenName is the pool name; resolve to numeric ID for the API token.
        'AgentPool' {
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.AgentPoolPermission)
            {
                $result.type   = 'AgentPool'
                $poolEntry     = Get-CacheItem -Key $TokenName.Trim() -Type 'LiveAgentPools'
                $result.PoolId = if ($poolEntry) { $poolEntry.id.ToString() } else { $TokenName.Trim() }
            }
            else
            {
                $result.type = 'AgentPoolUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known AgentPool ACL Token Patterns."
            }
            break
        }

        # DistributedTask — covers both Environment and AgentPool permissions.
        'DistributedTask' {
            if ($TokenName -match $LocalizedDataAzResourceTokenPatten.EnvironmentPermission)
            {
                $result.type      = 'Environment'
                $result.ProjectId = (Get-CacheItem -Key $matches.ProjectName.Trim() -Type 'LiveProjects').id
                if ($matches.EnvironmentName) {
                    # Resolve the environment numeric ID from cache so the token matches
                    # what Parse-ACLToken extracts from the API's Environments/{ProjectId}/{EnvironmentId} format.
                    $envCacheKey          = '{0}\{1}' -f $matches.ProjectName.Trim(), $matches.EnvironmentName.Trim()
                    $envCacheEntry        = Get-CacheItem -Key $envCacheKey -Type 'LivePipelineEnvironments'
                    $result.EnvironmentId = if ($envCacheEntry) { $envCacheEntry.id.ToString() } else { $matches.EnvironmentName.Trim() }
                }
            }
            elseif ($TokenName -match $LocalizedDataAzResourceTokenPatten.AgentPoolPermission)
            {
                # Pool name passed — resolve to numeric ID for the ACL token.
                $result.type   = 'AgentPool'
                $poolEntry     = Get-CacheItem -Key $TokenName.Trim() -Type 'LiveAgentPools'
                $result.PoolId = if ($poolEntry) { $poolEntry.id.ToString() } else { $TokenName.Trim() }
            }
            else
            {
                $result.type = 'DistributedTaskUnknown'
                Write-Warning "[New-ACLToken] TokenName '$TokenName' does not match any known DistributedTask ACL Token Patterns."
            }
            break
        }

        # Generic / pass-through for any other namespace
        default {
            Write-Warning "[New-ACLToken] SecurityNamespace '$SecurityNamespace' is not natively recognised — using generic token."
            $result.type       = 'Generic'
            $result.TokenValue = $TokenName
        }

    }

    Write-Verbose "[New-ACLToken] ACL Token: $($result | Out-String)"

    # Return the ACL Token
    return $result

}
