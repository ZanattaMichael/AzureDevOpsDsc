<#
.SYNOPSIS
Encodes a Git ref name (a branch or tag name) into the hex/UTF-16LE form the Git Repositories
security namespace uses inside an ACL token.

.DESCRIPTION
Azure DevOps addresses a branch or tag ACL as 'repoV2/{ProjectId}/{RepoId}/refs/heads/{encoded}'
(or '.../refs/tags/{encoded}'), where each '/'-delimited segment of the ref name is separately
hex-encoded as UTF-16LE and the encoded segments are rejoined with a literal '/'. A ref name that
itself contains a '/' - such as 'release/1.0' - is therefore two encoded segments, not one; this is
also how a branch folder such as 'refs/heads/release/' is addressed, since the folder is just the
same per-segment encoding stopped one segment short.

.PARAMETER RefName
The human-readable branch or tag name, as written in the resource configuration (e.g. 'main' or
'release/1.0'). Leading 'refs/heads/' or 'refs/tags/' should already have been stripped.

.EXAMPLE
ConvertTo-GitRefToken -RefName 'main'
Returns '6d00610069006e00'.

.EXAMPLE
ConvertTo-GitRefToken -RefName 'release/1.0'
Returns '7200650066006500610073006500/310002e0030000' style two-segment encoding - the exact bytes
of each segment hex-encoded as UTF-16LE, joined with '/'.
#>
Function ConvertTo-GitRefToken
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$RefName
    )

    Process
    {
        $segments = $RefName -split '/'

        $encodedSegments = ForEach ($segment in $segments)
        {
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($segment)
            -join ($bytes | ForEach-Object { $_.ToString('x2') })
        }

        return ($encodedSegments -join '/')
    }
}
