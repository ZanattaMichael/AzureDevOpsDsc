<#
.SYNOPSIS
Replaces anything in a string that looks like a credential with a fixed placeholder.

.DESCRIPTION
The last line of defence before text leaves the process: every message written through the
module's Write-Verbose, Write-Warning and Write-Error proxies, and every error message that carries
text the module did not write itself (an HTTP response body, the output of a native command, an
inner exception), goes through this function first.

It does not know the live credential - it recognises the shapes a credential takes:

  - an 'Authorization' value: 'Basic <base64>' or 'Bearer <token>';
  - a JSON Web Token (three base64url segments starting 'eyJ'), which is what every Entra ID
    access token, client assertion and federated token is;
  - an Azure DevOps personal access token (the 52-character and the 84-character format);
  - a 'name = value' or '"name": "value"' pair whose name says it is a secret (client_secret,
    password, access_token, serviceprincipalkey, ...), including form-encoded request bodies.

Text that matches none of these is returned unchanged, so ordinary messages are not altered.
Pattern matching cannot recognise a secret with no recognisable shape (a short custom API key
logged without a label), so this is a safety net behind not logging secrets in the first place,
not a replacement for it.

.PARAMETER InputString
The text to redact. $null and the empty string are returned as an empty string.

.OUTPUTS
System.String

.EXAMPLE
Protect-AzDoSecretString -InputString 'Authorization: Bearer eyJhbGciOi...'

Returns 'Authorization: Bearer <redacted>'.
#>
function Protect-AzDoSecretString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $InputString
    )

    if ([System.String]::IsNullOrEmpty($InputString))
    {
        return ''
    }

    # Built once. One compiled expression with named alternatives is a single pass over the
    # message, which matters because this runs for every verbose line that is displayed or logged.
    if ($null -eq $script:AzDoSecretStringPattern)
    {
        $pattern = @(
            # Authorization header values. 20+ characters so prose such as 'Basic authentication'
            # is left alone; 'Basic realm=<path>' is an Azure Arc challenge, not a credential.
            '(?<scheme>\b(?:Basic|Bearer)[ \t]+)(?!realm=)(?<credential>[A-Za-z0-9+/_\-\.~=]{20,})'
            # JSON Web Tokens.
            '(?<jwt>\beyJ[A-Za-z0-9_\-]{5,}\.eyJ[A-Za-z0-9_\-]{5,}\.[A-Za-z0-9_\-]*)'
            # name=value / "name": "value" pairs with a secret-bearing name.
            '(?<name>["'']?\b(?:client_secret|client_assertion|access_?token|refresh_token|id_token|password|passwd|pwd|api_?token|api_?key|serviceprincipalkey|shared_?key|sas_?token|secret|private_?key|personal_?access_?token|pat)\b["'']?[ \t]*[:=][ \t]*)(?<quote>["'']?)(?<value>[^"''&\s,;}]+)'
            # Azure DevOps personal access tokens.
            '(?<pat>(?<![A-Za-z0-9])(?:[a-z2-7]{52}|[A-Za-z0-9]{76}AZDO[A-Za-z0-9]{4})(?![A-Za-z0-9]))'
        ) -join '|'

        $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                   [System.Text.RegularExpressions.RegexOptions]::CultureInvariant -bor
                   [System.Text.RegularExpressions.RegexOptions]::Compiled

        $script:AzDoSecretStringPattern = [System.Text.RegularExpressions.Regex]::new($pattern, $options)

        $script:AzDoSecretStringEvaluator = [System.Text.RegularExpressions.MatchEvaluator] {
            param ($match)

            if ($match.Groups['scheme'].Success) { return $match.Groups['scheme'].Value + '<redacted>' }
            if ($match.Groups['name'].Success)   { return $match.Groups['name'].Value + $match.Groups['quote'].Value + '<redacted>' }
            return '<redacted>'
        }
    }

    return $script:AzDoSecretStringPattern.Replace($InputString, $script:AzDoSecretStringEvaluator)
}
