Function Parse-ACLToken {
    param(
        [Parameter(Mandatory)]
        [String]$Token
    )

    $result = @{}

    Write-Verbose "[Parse-ACLToken] Started."
    Write-Verbose "[Parse-ACLToken] Token: $Token"

    # Match the Token with the Regex Patterns
    switch -regex ($Token.Trim()) {
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

    # Get all Capture Groups and add them into a hashtable
    $matches.keys | Where-Object { $_.Length -gt 1 } | ForEach-Object {
        $result."$_" = $matches."$_"
    }

    $result._token = $Token

    return $result
}