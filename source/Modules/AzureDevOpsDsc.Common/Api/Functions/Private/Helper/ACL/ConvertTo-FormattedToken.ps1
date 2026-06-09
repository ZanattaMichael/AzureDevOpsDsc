<#
.SYNOPSIS
Formats the token based on its type.

.DESCRIPTION
The ConvertTo-FormattedToken function is used to format a token based on its type. It takes a token as input and returns the formatted token string.

.PARAMETER Token
The token to format. This parameter is mandatory and accepts an array of objects.

.EXAMPLE
$token = @{
    type = 'GitProject'
    projectId = 'myProject'
    repositoryId = 'myRepo'
}
ConvertTo-FormattedToken -Token $token
# Output: "repoV2/myProject/myRepo"

.NOTES
This function assumes that the token type is either 'GitOrganization', 'GitProject', or 'GitRepository'. If the token type is not one of these, the function will not format the token and will return an empty string.
#>

Function ConvertTo-FormattedToken {
    [CmdletBinding()]
    param (
        # Define a mandatory parameter named 'Token' of type Object array
        [Parameter(Mandatory = $true)]
        [Object[]]$Token
    )

    # Output verbose message indicating the function has started
    Write-Verbose "[ConvertTo-FormattedToken] Started."

    # Initialize variable to store formatted token string
    $string = ""

    # Determine the type of the token and format accordingly
    switch ($Token)
    {
        # If the token type is 'GitOrganization'
        {$_.type -eq 'GitOrganization'} {
            $string = 'repoV2'
            break
        }
        # If the token type is 'GitProject'
        {$_.type -eq 'GitProject'} {
            $string = 'repoV2/{0}' -f $Token.projectId
            break
        }
        # If the token type is 'GitRepository'
        {$_.type -eq 'GitRepository'} {
            $string = 'repoV2/{0}/{1}' -f $Token.projectId, $Token.RepoId
            break
        }
        # If the token type is 'CSS'
        {$_.type -eq 'CSS'} {
            $string = $(($Token.Identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_.identifier }) -join ':')
            break
        }
        # If the token type is 'Iteration'
        {$_.type -eq 'Iteration'} {
            $string = $(($Token.Identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_.identifier }) -join ':')
            break
        }
        # Project-level permissions
        {$_.type -eq 'Project'} {
            $string = '$PROJECT:vstfs:///Classification/TeamProject/{0}' -f $Token.ProjectId
            break
        }
        # Build (Pipeline) permissions
        {$_.type -eq 'Build'} {
            $string = if ($Token.PipelineId) { '{0}/{1}' -f $Token.ProjectId, $Token.PipelineId }
                      else                   { $Token.ProjectId }
            break
        }
        # Library (VariableGroup) permissions
        {$_.type -eq 'Library'} {
            $string = if ($Token.VariableGroupId) { 'Library/Project/{0}/VariableGroup/{1}' -f $Token.ProjectId, $Token.VariableGroupId }
                      else                        { 'Library/Project/{0}' -f $Token.ProjectId }
            break
        }
        # ServiceEndpoints permissions
        {$_.type -eq 'ServiceEndpoints'} {
            $string = if ($Token.EndpointId) { 'endpoints/Project/{0}/endpoint/{1}' -f $Token.ProjectId, $Token.EndpointId }
                      else                   { 'endpoints/Project/{0}' -f $Token.ProjectId }
            break
        }
        # DistributedTask — AgentPool
        {$_.type -eq 'AgentPool'} {
            $string = '{0}' -f $Token.PoolId
            break
        }
        # DistributedTask — Environment
        {$_.type -eq 'Environment'} {
            $string = if ($Token.EnvironmentId) { 'Environments/{0}/{1}' -f $Token.ProjectId, $Token.EnvironmentId }
                      else                      { 'Environments/{0}' -f $Token.ProjectId }
            break
        }
        # Generic / passthrough — token stored verbatim
        {$_.type -eq 'Generic'} {
            $string = $Token.TokenValue
            break
        }
    }

    # Output verbose message with the token value
    Write-Verbose "[ConvertTo-FormattedToken] Token: $string"

    # Return the formatted token string
    return $string
}
