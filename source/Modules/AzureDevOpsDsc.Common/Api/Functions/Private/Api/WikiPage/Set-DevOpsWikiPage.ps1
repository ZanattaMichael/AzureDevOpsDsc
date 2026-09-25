<#
.SYNOPSIS
Creates or updates a wiki page.

.DESCRIPTION
Wraps the Wiki Pages 'Create or Update Page' endpoint (PUT). Creating a page that does not yet
exist needs no 'If-Match' header; updating one that does needs the page's current ETag, or the API
answers 412 (Precondition Failed) rather than silently overwriting someone else's edit.

The caller supplies the ETag it just read, rather than this function reading it itself, so that a
Set can read and write inside the same operation with no gap for another edit to land in between.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiIdentifier
The id or name of the wiki.

.PARAMETER Path
The full path of the wiki page.

.PARAMETER Content
The Markdown content to write.

.PARAMETER ETag
The current page version, as read from a prior Get-DevOpsWikiPage. Omit for a new page.

.EXAMPLE
Set-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call'
#>
Function Set-DevOpsWikiPage
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

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]$Content,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]$ETag,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pages?path={3}&api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($WikiIdentifier),
        [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    $additionalHeaders = @{}
    if (-not [String]::IsNullOrWhiteSpace($ETag))
    {
        $additionalHeaders['If-Match'] = $ETag
    }

    $body = @{ content = $Content } | ConvertTo-Json -Depth 5

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PUT' -AdditionalHeaders $additionalHeaders -Body $body)
    }
    catch
    {
        if ($_ -match '412')
        {
            throw "[Set-DevOpsWikiPage] Wiki page '$normalizedPath' in wiki '$WikiIdentifier' was changed by someone else since it was last read (stale ETag). Error: $_"
        }

        throw "[Set-DevOpsWikiPage] Failed to write wiki page '$normalizedPath' in wiki '$WikiIdentifier'. Error: $_"
    }
}
