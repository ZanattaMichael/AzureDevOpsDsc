<#
.SYNOPSIS
Tests whether a URI points at a host the module's credential may be sent to.

.DESCRIPTION
Invoke-AzDevOpsApiRestMethod attaches the Azure DevOps credential to every request it sends. A
URI is text, and some of it comes from configuration, cache files and API responses, so before a
credential is attached the host is checked against the hosts Azure DevOps Services is served from:

  - dev.azure.com and its service hosts (vssps., vsrm., vsaex., feeds., auditservice.,
    extmgmt., ... .dev.azure.com);
  - the legacy <organization>.visualstudio.com hosts.

Azure DevOps Server (on-premises) hosts are not known in advance. Name them, comma separated, in
the AZDODSC_ALLOWED_API_HOSTS environment variable (host names only, matched exactly).

A URI carrying user information ('https://dev.azure.com@example.org/') is always refused: the
part before the '@' is not the host.

.PARAMETER Uri
The absolute URI the request is about to be sent to.

.OUTPUTS
System.Boolean
#>
function Test-AzDoApiHost
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Uri]
        $Uri
    )

    if (($null -eq $Uri) -or (-not $Uri.IsAbsoluteUri))
    {
        return $false
    }

    if (-not [System.String]::IsNullOrEmpty($Uri.UserInfo))
    {
        return $false
    }

    $hostName = $Uri.DnsSafeHost.ToLowerInvariant().TrimEnd('.')

    if ([System.String]::IsNullOrEmpty($hostName))
    {
        return $false
    }

    if (($hostName -eq 'dev.azure.com') -or
        $hostName.EndsWith('.dev.azure.com', [System.StringComparison]::Ordinal) -or
        $hostName.EndsWith('.visualstudio.com', [System.StringComparison]::Ordinal))
    {
        return $true
    }

    foreach ($allowedHost in ([System.String]$env:AZDODSC_ALLOWED_API_HOSTS -split '[,;]'))
    {
        $allowedHost = $allowedHost.Trim().ToLowerInvariant().TrimEnd('.')

        if ((-not [System.String]::IsNullOrEmpty($allowedHost)) -and ($hostName -eq $allowedHost))
        {
            return $true
        }
    }

    return $false
}
