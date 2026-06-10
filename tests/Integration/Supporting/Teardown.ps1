[CmdletBinding()]
param (
    [Parameter()]
    [Switch]
    $ClearAll,

    [Parameter()]
    [Switch]
    $ClearOrganizationGroups,

    [Parameter()]
    [Switch]
    $ClearProjects,

    [Parameter()]
    [Switch]
    $ClearAgentPools,

    [Parameter()]
    [String]
    $OrganizationName,

    [Parameter()]
    [Object]
    $TestFrameworkConfiguration

)

$Global:DSCAZDO_AuthenticationToken = Get-MIToken -OrganizationName $OrganizationName

#
# Remove Projects
if ($ClearAll -or $ClearProjects)
{
    Write-Verbose "[Teardown] Removing test projects..."
    # List all projects and remove them (except excluded ones)
    List-DevOpsProjects -OrganizationName $OrganizationName | Where-Object { $_.Name -notin $TestFrameworkConfiguration.excludedProjectsFromTeardown } | ForEach-Object {
        Write-Verbose "[Teardown] Removing project '$($_.Name)' ($($_.id))"
        Remove-DevOpsProject -ProjectId $_.id -Organization $OrganizationName
    }
}

#
# Remove Organization Groups
if ($ClearAll -or $ClearOrganizationGroups)
{
    Write-Verbose "[Teardown] Removing test organization groups..."
    # Remove all non-system groups (system groups start with Project/, Security/, Service/, Team/, Enterprise/)
    List-DevOpsGroups -Organization $OrganizationName | Where-Object {
        ($_.DisplayName -notlike "Project*") -and ($_.DisplayName -notlike "Security*") -and ($_.DisplayName -notlike "Service*") -and ($_.DisplayName -notlike "Team*") -and ($_.DisplayName -notlike "Enterprise*")
    } | ForEach-Object {
        Write-Verbose "[Teardown] Removing group '$($_.displayName)'"
        Remove-DevOpsGroup -GroupDescriptor $_.descriptor -OrganizationName $OrganizationName
    }
}

#
# Purge artifact feed recycle bin (org-level) to prevent "name reserved" errors on re-run
if ($ClearAll -or $ClearProjects)
{
    Write-Verbose "[Teardown] Purging artifact feed recycle bin..."
    $recycleBinFeeds = List-DevOpsArtifactFeedRecycleBin -OrganizationName $OrganizationName
    foreach ($feed in $recycleBinFeeds)
    {
        Write-Verbose "[Teardown] Purging feed '$($feed.name)' ($($feed.id)) from recycle bin."
        Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $OrganizationName -FeedId $feed.id
    }
}

#
# Remove Test Agent Pools (non-hosted pools whose names start with TEST_)
if ($ClearAll -or $ClearAgentPools)
{
    Write-Verbose "[Teardown] Removing test agent pools..."
    List-DevOpsAgentPools -OrganizationName $OrganizationName | Where-Object {
        (-not $_.isHosted) -and ($_.name -like 'TEST_*')
    } | ForEach-Object {
        Write-Verbose "[Teardown] Removing agent pool '$($_.name)' ($($_.id))"
        Remove-DevOpsAgentPool -OrganizationName $OrganizationName -PoolId $_.id
    }
}
