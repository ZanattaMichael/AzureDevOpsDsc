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
# Purge artifact feed recycle bins BEFORE removing projects (project-level API requires project to exist)
if ($ClearAll -or $ClearProjects)
{
    Write-Verbose "[Teardown] Purging org-level artifact feed recycle bin..."
    $recycleBinFeeds = List-DevOpsArtifactFeedRecycleBin -OrganizationName $OrganizationName
    foreach ($feed in $recycleBinFeeds)
    {
        Write-Verbose "[Teardown] Purging feed '$($feed.name)' ($($feed.id)) from org recycle bin."
        Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $OrganizationName -FeedId $feed.id
    }

    Write-Verbose "[Teardown] Purging project-level artifact feed recycle bins..."
    $projects = List-DevOpsProjects -OrganizationName $OrganizationName | Where-Object { $_.Name -notin $TestFrameworkConfiguration.excludedProjectsFromTeardown }
    foreach ($project in $projects)
    {
        $projectFeeds = List-DevOpsArtifactFeedRecycleBin -OrganizationName $OrganizationName -ProjectName $project.Name
        foreach ($feed in $projectFeeds)
        {
            Write-Verbose "[Teardown] Purging feed '$($feed.name)' ($($feed.id)) from project '$($project.Name)' recycle bin."
            Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $OrganizationName -ProjectName $project.Name -FeedId $feed.id
        }
    }
}

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
    # Project deletion is async — wait for projects to be fully removed before purging feeds.
    Write-Host "[Teardown] Waiting for project deletions to complete (wellFormed state)..."
    $maxWait = 180
    $waited  = 0
    do {
        Start-Sleep -Seconds 5
        $waited += 5
        $remaining = List-DevOpsProjects -OrganizationName $OrganizationName | Where-Object { $_.Name -notin $TestFrameworkConfiguration.excludedProjectsFromTeardown }
    } while ($remaining.Count -gt 0 -and $waited -lt $maxWait)

    # Also wait for any projects still in 'deleting' state (name is reserved while deleting)
    Write-Host "[Teardown] Waiting for projects in 'deleting' state to clear..."
    $waited = 0
    do {
        Start-Sleep -Seconds 5
        $waited += 5
        $deleting = List-DevOpsProjects -OrganizationName $OrganizationName -StateFilter deleting | Where-Object { $_.Name -notin $TestFrameworkConfiguration.excludedProjectsFromTeardown }
        if ($deleting) { Write-Host "[Teardown] Still deleting: $(($deleting | ForEach-Object { $_.Name }) -join ', ')" }
    } while ($deleting.Count -gt 0 -and $waited -lt $maxWait)

    # Permanently purge any soft-deleted projects so their names are freed immediately
    Write-Host "[Teardown] Purging soft-deleted projects from recycle bin..."
    $deletedProjects = List-DevOpsProjects -OrganizationName $OrganizationName -StateFilter deleted | Where-Object { $_.Name -notin $TestFrameworkConfiguration.excludedProjectsFromTeardown }
    foreach ($proj in $deletedProjects)
    {
        Write-Host "[Teardown] Permanently deleting project '$($proj.Name)' ($($proj.id)) from recycle bin."
        Remove-DevOpsProject -ProjectId $proj.id -Organization $OrganizationName
    }
    if ($deletedProjects.Count -gt 0)
    {
        Start-Sleep -Seconds 10
    }

    Write-Host "[Teardown] Projects cleared (waited ${waited}s). Purging org-level artifact feed recycle bin..."
    $recycleBinFeeds = List-DevOpsArtifactFeedRecycleBin -OrganizationName $OrganizationName
    foreach ($feed in $recycleBinFeeds)
    {
        Write-Verbose "[Teardown] Purging feed '$($feed.name)' ($($feed.id)) from org recycle bin."
        Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $OrganizationName -FeedId $feed.id
    }
    Write-Host "[Teardown] Post-deletion recycle bin purge complete."
}

#
# Remove Organization Groups
if ($ClearAll -or $ClearOrganizationGroups)
{
    Write-Host "[Teardown] Listing organization groups..."
    $allGroups = List-DevOpsGroups -Organization $OrganizationName
    $testGroups = $allGroups | Where-Object {
        ($_.DisplayName -notlike "Project*") -and ($_.DisplayName -notlike "Security*") -and ($_.DisplayName -notlike "Service*") -and ($_.DisplayName -notlike "Team*") -and ($_.DisplayName -notlike "Enterprise*")
    }
    Write-Host "[Teardown] Removing $($testGroups.Count) non-system groups..."
    $testGroups | ForEach-Object {
        Write-Verbose "[Teardown] Removing group '$($_.displayName)'"
        Remove-DevOpsGroup -GroupDescriptor $_.descriptor -OrganizationName $OrganizationName
    }
    Write-Host "[Teardown] Group removal complete."
}

#
# Remove Test Agent Pools (non-hosted pools whose names start with TEST_)
if ($ClearAll -or $ClearAgentPools)
{
    Write-Host "[Teardown] Listing agent pools..."
    $testPools = List-DevOpsAgentPools -OrganizationName $OrganizationName | Where-Object {
        (-not $_.isHosted) -and ($_.name -like 'TEST_*')
    }
    Write-Host "[Teardown] Removing $($testPools.Count) test agent pools..."
    $testPools | ForEach-Object {
        Write-Verbose "[Teardown] Removing agent pool '$($_.name)' ($($_.id))"
        Remove-DevOpsAgentPool -OrganizationName $OrganizationName -PoolId $_.id
    }
    Write-Host "[Teardown] Agent pool removal complete."
}
