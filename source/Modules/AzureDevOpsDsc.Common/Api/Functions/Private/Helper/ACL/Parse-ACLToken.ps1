Function Parse-ACLToken
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$Token,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Identity', 'Git Repositories')]
        [String]$SecurityNamespace
    )

    $result = @{}
    $useRegexVariable = $true

    Write-Verbose "[Parse-ACLToken] Started."
    Write-Verbose "[Parse-ACLToken] Token: $Token"
    Write-Verbose "[Parse-ACLToken] Security Namespace: $SecurityNamespace"

    #
    # Git Repositories
    if ($SecurityNamespace -eq 'Git Repositories')
    {
        # Match the Token with the Regex Patterns
        switch -regex ($Token.Trim())
        {
            $LocalizedDataAzACLTokenPatten.OrganizationGit {
                $result.type = 'OrganizationGit'
                break;
            }

            $LocalizedDataAzACLTokenPatten.GitProject {
                $result.type = 'GitProject'
                break;
            }

            $LocalizedDataAzACLTokenPatten.GitRepository {
                $result.type = 'GitRepository'
                break;
            }

            $LocalizedDataAzACLTokenPatten.GitBranch {
                $result.type = 'GitBranch'
                break;
            }

            default {
                throw "Token '$Token' is not recognized."
            }
        }

    #
    # Identity
    }
    elseif ($SecurityNamespace -eq 'Identity')
    {

        # Match the Token with the Regex Patterns
        switch -regex ($Token.Trim())
        {

            $LocalizedDataAzACLTokenPatten.ResourcePermission {
                $result.type = 'ResourcePermission'
                break;
            }

            $LocalizedDataAzACLTokenPatten.GroupPermission {
                $result.type = 'GroupPermission'
                break;
            }

            default {
                throw "Token '$Token' is not recognized."
            }
        }
    }
    elseif ($SecurityNamespace -eq 'CSS') # AreaPath's
    {
        # Match the Token with the Regex Patterns
        switch -regex ($Token.Trim())
        {
            $LocalizedDataAzACLTokenPatten.AreaPathPermission {

                $result.type = 'AreaPathPermission'

                # Use custom logic to extract the AreaPath from the token.
                # We cant use the regex variable as it it's a complex regex pattern.
                $regexMatches = [regex]::Matches($Token, $LocalizedDataAzACLTokenPatten.AreaPathPermission)

                # Check if the match was successful
                if ($regexMatches.Count -eq 0)
                {
                    throw "Token '$Token' is not recognized."
                }

                $result.Identifiers = @()

                # Construct the token structure
                foreach ($match in $regexMatches) {
                    $result.Identifiers += @{
                        identifier = $match.groups['identifiers'].value
                    }
                }

                # Bypass the regex variable as it is a complex regex pattern.
                $useRegexVariable = $false

                break;

            }

            default {
                throw "Token '$Token' is not recognized."
            }
        }
    }
    else
    {
        throw "Security Namespace '$SecurityNamespace' is not recognized."
    }

    # Get the Regex Pattern for the Token by using the regex variable to extract the token structure.
    if ($useRegexVariable) {
        # Get all Capture Groups and add them into a hashtable
        $matches.keys | Where-Object { $_.Length -gt 1 } | ForEach-Object {
            $result."$_" = $matches."$_"
        }

    }

    $result._token = $Token

    return $result
}
