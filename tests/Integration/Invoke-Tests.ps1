#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
param(
    [Parameter(Mandatory = $true)]
    [String]$TestFrameworkConfigurationPath
)

#
# Dot Source the Supporting Functions

$CurrentLocation = Get-Location

Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\Functions" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

#
# Load API helpers (needed for teardown)

Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\API" -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\APICalls" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

#
# Firstly Initialize the test environment
. "$($CurrentLocation.Path)\Supporting\Initalize-TestFramework.ps1" -TestFrameworkConfigurationPath $TestFrameworkConfigurationPath

# Populate globals used by the shared REST helper aliases in SupportingFunctions.ps1
$Global:TestOrg        = $GLOBAL:DSCAZDO_OrganizationName
$Global:TestAuthHeader = New-TestAuthHeader

#
# Pre-run teardown: ensure a clean slate before tests start
# This removes any resources left over from a previous (possibly failed) test run.

Write-Host "[Invoke-Tests] Running pre-run teardown to ensure a clean environment..."
. "$($CurrentLocation.Path)\Supporting\Teardown.ps1" -ClearAll -OrganizationName $GLOBAL:DSCAZDO_OrganizationName -TestFrameworkConfiguration $TestFrameworkConfiguration
Write-Host "[Invoke-Tests] Pre-run teardown complete."

#
# Clear project-scoped module cache files so DSC Get() calls re-fetch live state after teardown.
# The DSC resources (especially the cache-first *Permission resources) resolve resource IDs and ACL
# descriptors from these caches; leaving them stale after teardown makes Set succeed but the following
# Test() compare against dead object IDs and return $false. Org-wide caches (LiveProcesses, LiveUsers,
# LiveServicePrinciples, SecurityNamespaces, LivePolicyTypes) are static and must NOT be cleared.

$cacheDir = Join-Path $env:AZDODSC_CACHE_DIRECTORY 'Cache'
if (Test-Path $cacheDir)
{
    Write-Host "[Invoke-Tests] Clearing project-scoped cache files after teardown..."
    $cacheFilesToClear = @(
        'LiveProjects', 'LiveGroups', 'LiveGroupMembers', 'LiveRepositories',
        'LiveTeams', 'LiveTeamMembers', 'LiveArtifactFeeds', 'LiveAgentPools',
        'LiveAgentQueues', 'LiveAreaNodes', 'LiveIterations', 'LiveACLList',
        'Group', 'SecurityDescriptor', 'IdentityDescriptorIndex'
    )
    foreach ($cacheFile in $cacheFilesToClear)
    {
        $filePath = Join-Path $cacheDir "$cacheFile.clixml"
        if (Test-Path $filePath)
        {
            Write-Host "[Invoke-Tests] Removing stale cache: $cacheFile"
            Remove-Item -Path $filePath -Force
        }
    }
}

# Azure DevOps project deletions are asynchronous. Wait for them to settle before the tests try to
# re-create the same projects; otherwise BeforeAll can hit 400 "project name in use" / TF200016.
Write-Host "[Invoke-Tests] Waiting 90 seconds for Azure DevOps to complete async project deletions..."
Start-Sleep -Seconds 90

#
# Trigger the Tests

$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path           = "$PSScriptRoot\Resources"
$pesterConfig.Output.Verbosity   = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath   = 'C:\Temp\integration-test-results.xml'
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

Invoke-Pester -Configuration $pesterConfig

#
# Post-run teardown: clean up all resources created during the test run

Write-Host "[Invoke-Tests] Running post-run teardown..."
. "$($CurrentLocation.Path)\Supporting\Teardown.ps1" -ClearAll -OrganizationName $GLOBAL:DSCAZDO_OrganizationName -TestFrameworkConfiguration $TestFrameworkConfiguration
Write-Host "[Invoke-Tests] Post-run teardown complete."
