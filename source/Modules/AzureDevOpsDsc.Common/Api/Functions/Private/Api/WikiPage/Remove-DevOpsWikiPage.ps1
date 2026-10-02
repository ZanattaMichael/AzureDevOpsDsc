<#
.SYNOPSIS
Deletes a wiki page.

.DESCRIPTION
Wraps the Wiki Pages 'Delete Page' endpoint. Deleting a page deletes every sub-page beneath it -
the caller is responsible for the AllowRecursiveDelete guard before calling this.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiIdentifier
The id or name of the wiki.

.PARAMETER Path
The full path of the wiki page.

.EXAMPLE
Remove-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call'
#>
Function Remove-DevOpsWikiPage
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
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pages?path={3}&api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($WikiIdentifier),
        [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        if ($_ -match '404' -or $_ -match 'does not exist' -or $_ -match 'was not found')
        {
            Write-Verbose "[Remove-DevOpsWikiPage] Wiki page '$normalizedPath' in wiki '$WikiIdentifier' does not exist. Nothing to remove."
            return $null
        }

        throw "[Remove-DevOpsWikiPage] Failed to remove wiki page '$normalizedPath' in wiki '$WikiIdentifier'. Error: $_"
    }
}
