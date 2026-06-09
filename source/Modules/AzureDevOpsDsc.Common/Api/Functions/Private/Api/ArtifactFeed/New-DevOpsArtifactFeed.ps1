Function New-DevOpsArtifactFeed
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][string]$Description,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][bool]$BadgesEnabled = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri, $ProjectName } else { $ApiUri }
    $params = @{
        Uri         = '{0}/_apis/packaging/feeds?api-version={1}' -f $baseUri, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name                        = $FeedName
            description                 = $Description
            hideDeletedPackageVersions  = $HideDeletedPackageVersions
            badgesEnabled               = $BadgesEnabled
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsArtifactFeed] Failed to create artifact feed '$FeedName': $_" }
}
