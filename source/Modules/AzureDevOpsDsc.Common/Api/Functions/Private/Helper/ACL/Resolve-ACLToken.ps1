Function Resolve-ACLToken {

    param(
        [Parameter(Mandatory)]
        [String]$Token
    )

    $result = @{}

    # Match the Token with the Regex Patterns
    switch -regex ($Token.Trim()) {
        $LocalizedDataAzTokenPatten.OrganizationGit {
            $result.type = 'OrganizationGit'
            break;
        }

        $LocalizedDataAzTokenPatten.ProjectGit {
            $result.type = 'ProjectGit'
            break;
        }

        $LocalizedDataAzTokenPatten.GitRepository {
            $result.type = 'GitRepository'
            break;
        }

        $LocalizedDataAzTokenPatten.GitBranch {
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

    return $result

}
