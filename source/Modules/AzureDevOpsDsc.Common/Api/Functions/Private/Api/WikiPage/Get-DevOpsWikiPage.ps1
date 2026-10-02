<#
.SYNOPSIS
Retrieves a wiki page and its current ETag.

.DESCRIPTION
Wraps the Wiki Pages 'Get Page' endpoint. The page content is returned in the body; the page's
current version is returned as the response's 'ETag' header, not as a body field, so this needs
Invoke-AzDevOpsApiRestMethod's -IncludeResponseHeaders switch to see it. A later update must send
that ETag back as 'If-Match' or the API answers 412 (Precondition Failed).

Requesting -RecursionLevel 'OneLevel' also populates the page's 'subPages' property one level
down, which is how the caller can tell whether removing this page would take sub-pages with it.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiIdentifier
The id or name of the wiki.

.PARAMETER Path
The full path of the wiki page, for example '/Runbooks/On-call'.

.PARAMETER IncludeContent
Include the page's Markdown content in the response.

.PARAMETER RecursionLevel
How far to recurse into sub-pages. 'None' (default) returns just this page; 'OneLevel' also
populates 'subPages' with this page's immediate children.

.EXAMPLE
Get-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -IncludeContent
#>
Function Get-DevOpsWikiPage
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$WikiIdentifier,

        [Parameter(Mandatory = $true)]
        [System.String]$Path,

        [Parameter()]
        [Switch]$IncludeContent,

        [Parameter()]
        [ValidateSet('None', 'OneLevel', 'Full')]
        [System.String]$RecursionLevel = 'None',

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pages?path={3}&includeContent={4}&recursionLevel={5}&api-version={6}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($WikiIdentifier),
        [System.Uri]::EscapeDataString($normalizedPath), $IncludeContent.IsPresent.ToString().ToLower(), $RecursionLevel, $ApiVersion

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET' -IncludeResponseHeaders

        $eTag = $null
        if ($response.Headers -and $response.Headers.ETag)
        {
            # Header values come back as string arrays; take the first so it is not stringified
            # as 'System.String[]' when it is later sent back as 'If-Match'.
            $eTag = @($response.Headers.ETag)[0]
        }

        return [PSCustomObject]@{
            Page = $response.Value
            ETag = $eTag
        }
    }
    catch
    {
        if ($_ -match '404' -or $_ -match 'does not exist' -or $_ -match 'was not found')
        {
            Write-Verbose "[Get-DevOpsWikiPage] No wiki page at '$normalizedPath' in wiki '$WikiIdentifier'."
            return $null
        }

        throw "[Get-DevOpsWikiPage] Failed to get wiki page '$normalizedPath' in wiki '$WikiIdentifier'. Error: $_"
    }
}
