<#
.SYNOPSIS
Reorders a wiki page among its siblings.

.DESCRIPTION
Wraps the Wiki Page Moves 'Create' endpoint. This resource only ever reorders a page - it never
relocates one to a different parent, so 'newPath' is always sent as the page's own current path
and only 'newOrder' changes.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiIdentifier
The id or name of the wiki.

.PARAMETER Path
The full, current path of the wiki page.

.PARAMETER NewOrder
The page's desired position among its siblings.

.EXAMPLE
Move-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -NewOrder 2
#>
Function Move-DevOpsWikiPage
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
        [System.Int32]$NewOrder,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pagemoves?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($WikiIdentifier), $ApiVersion

    $body = @{
        path     = $normalizedPath
        newPath  = $normalizedPath
        newOrder = $NewOrder
    } | ConvertTo-Json -Depth 5

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body $body)
    }
    catch
    {
        throw "[Move-DevOpsWikiPage] Failed to reorder wiki page '$normalizedPath' in wiki '$WikiIdentifier' to position $NewOrder. Error: $_"
    }
}
