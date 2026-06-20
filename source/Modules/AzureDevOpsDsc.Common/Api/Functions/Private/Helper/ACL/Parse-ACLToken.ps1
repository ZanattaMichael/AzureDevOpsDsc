Function Parse-ACLToken
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$Token,

        [Parameter(Mandatory = $true)]
        [String]$SecurityNamespace
    )

    $result = @{}
    $useRegexVariable = $true

    Write-Verbose "[Parse-ACLToken] Started."
    Write-Verbose "[Parse-ACLToken] Token: $Token"
    Write-Verbose "[Parse-ACLToken] Security Namespace: $SecurityNamespace"

    # Helper: extract named capture group 'identifiers' from all regex matches for complex patterns.
    $extractIdentifiers = {
        param([string]$tok, [string]$pattern)
        $m = [regex]::Matches($tok, $pattern)
        if ($m.Count -eq 0) { throw "Token '$tok' is not recognized." }
        @($m | ForEach-Object { @{ identifier = $_.Groups['identifiers'].Value } })
    }

    switch ($SecurityNamespace)
    {
        'Git Repositories' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.OrganizationGit { $result.type = 'OrganizationGit'; break }
                $LocalizedDataAzACLTokenPatten.GitProject      { $result.type = 'GitProject';      break }
                $LocalizedDataAzACLTokenPatten.GitRepository   { $result.type = 'GitRepository';   break }
                $LocalizedDataAzACLTokenPatten.GitBranch       { $result.type = 'GitBranch';       break }
                default { throw "Token '$Token' is not recognized." }
            }
        }

        'Identity' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.ResourcePermission { $result.type = 'ResourcePermission'; break }
                $LocalizedDataAzACLTokenPatten.GroupPermission    { $result.type = 'GroupPermission';    break }
                default { throw "Token '$Token' is not recognized." }
            }
        }

        'CSS' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.AreaPathPermission {
                    $result.type        = 'AreaPathPermission'
                    $result.Identifiers = & $extractIdentifiers $Token $LocalizedDataAzACLTokenPatten.AreaPathPermission
                    $useRegexVariable   = $false
                    break
                }
                default { throw "Token '$Token' is not recognized." }
            }
        }

        'Iteration' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.IterationPathPermission {
                    $result.type        = 'IterationPathPermission'
                    $result.Identifiers = & $extractIdentifiers $Token $LocalizedDataAzACLTokenPatten.IterationPathPermission
                    $useRegexVariable   = $false
                    break
                }
                default { throw "Token '$Token' is not recognized." }
            }
        }

        'Project' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.ProjectPermission { $result.type = 'Project';        break }
                default                                          { $result.type = 'ProjectUnknown'        }
            }
        }

        'Process' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.ProcessRootPermission { $result.type = 'ProcessRoot'; break }
                $LocalizedDataAzACLTokenPatten.ProcessPermission     { $result.type = 'Process';     break }
                default                                              { $result.type = 'ProcessUnknown'     }
            }
        }

        'Build' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.BuildPermission { $result.type = 'Build';        break }
                default                                        { $result.type = 'BuildUnknown'        }
            }
        }

        'Library' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.LibraryPermission { $result.type = 'Library';        break }
                default                                          { $result.type = 'LibraryUnknown'        }
            }
        }

        'ServiceEndpoints' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.ServiceEndpointPermission { $result.type = 'ServiceEndpoints';        break }
                default                                                   { $result.type = 'ServiceEndpointsUnknown'       }
            }
        }

        'AgentPool' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.AgentPoolPermission {
                    $result.type   = 'AgentPool'
                    $result.PoolId = $Token.Trim()
                    break
                }
                default { $result.type = 'AgentPoolUnknown' }
            }
        }

        'DistributedTask' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.EnvironmentPermission { $result.type = 'Environment'; break }
                $LocalizedDataAzACLTokenPatten.AgentPoolPermission   { $result.type = 'AgentPool';   break }
                default                                              { $result.type = 'DistributedTaskUnknown' }
            }
        }

        default {
            # Generic / pass-through for any namespace not explicitly handled above.
            Write-Warning "[Parse-ACLToken] Security Namespace '$SecurityNamespace' is not natively recognised — using generic token."
            $result.type       = 'Generic'
            $result.TokenValue = $Token
        }
    }

    # Populate result with named capture groups from the automatic $Matches variable.
    if ($useRegexVariable) {
        $Matches.Keys | Where-Object { $_.Length -gt 1 } | ForEach-Object {
            $result."$_" = $Matches."$_"
        }
    }

    $result._token = $Token

    return $result
}
