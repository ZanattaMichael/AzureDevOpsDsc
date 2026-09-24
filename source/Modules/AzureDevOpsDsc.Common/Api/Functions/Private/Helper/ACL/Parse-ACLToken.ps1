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

        'WorkItemQueryFolders' {
            switch -regex ($Token.Trim())
            {
                # The namespace root is a bare '$'. AzDoQueryPermission scans every ACL in
                # the namespace, so it meets this token on any organization - and throwing
                # here aborted the whole scan, which is what made every AzDoQueryPermission
                # integration test fail with "Token '$' is not recognized."
                $LocalizedDataAzACLTokenPatten.QueryRootPermission {
                    $result.type      = 'QueryRoot'
                    $useRegexVariable = $false
                    break
                }

                $LocalizedDataAzACLTokenPatten.QueryPermission {
                    $result.type      = 'QueryPermission'
                    $result.ProjectId = $matches.ProjectId

                    # As in New-ACLToken: the folder ids come from the remainder, because the
                    # project id is a GUID too and would otherwise be read as the first folder.
                    $remainder = $matches.Remainder
                    $result.Identifiers = @()

                    if (-not [String]::IsNullOrEmpty($remainder))
                    {
                        $folderMatches = [regex]::Matches($remainder, $LocalizedDataAzACLTokenPatten.QueryFolderIdentifier)
                        $result.Identifiers = @($folderMatches | ForEach-Object { @{ identifier = $_.Groups['identifiers'].Value } })
                    }

                    $useRegexVariable = $false
                    break
                }

                # Non-throwing, matching Project, Process, Build and Library: every
                # namespace whose resource enumerates org-wide ACLs has to tolerate a token
                # shape it does not model, or one unexpected entry fails the whole resource.
                default
                {
                    $result.type      = 'QueryUnknown'
                    $useRegexVariable = $false
                }
            }
        }

        'Project' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.ProjectPermission { $result.type = 'Project';        break }
                default                                          { $result.type = 'ProjectUnknown'        }
            }
        }

        'Tagging' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.TaggingPermission { $result.type = 'Tagging';        break }
                default                                          { $result.type = 'TaggingUnknown'        }
            }
        }

        'Analytics' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.AnalyticsPermission { $result.type = 'Analytics';        break }
                default                                            { $result.type = 'AnalyticsUnknown'        }
            }
        }

        'AnalyticsViews' {
            switch -regex ($Token.Trim())
            {
                $LocalizedDataAzACLTokenPatten.AnalyticsViewsPermission { $result.type = 'AnalyticsViews';        break }
                default                                                 { $result.type = 'AnalyticsViewsUnknown'        }
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
                $LocalizedDataAzACLTokenPatten.BuildPermission       { $result.type = 'Build';       break }
                $LocalizedDataAzACLTokenPatten.BuildFolderPermission { $result.type = 'BuildFolder'; break }
                default                                              { $result.type = 'BuildUnknown'       }
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
