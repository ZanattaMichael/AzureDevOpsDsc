#
# Shared REST API helpers for integration test setup (BeforeAll blocks).
# These functions are dot-sourced by Invoke-Tests.ps1 and are available to all test files.
#
# Organization and AuthHeader parameters are optional in all New-Test* functions.
# When omitted they resolve from $Global:TestOrg / $Global:TestAuthHeader (set by
# Invoke-Tests.ps1) and fall back to reading ModuleSettings.clixml directly, so
# test files need no per-file auth/org boilerplate.
#

function New-TestAuthHeader
{
    $cfg  = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
    $tok  = $cfg.Token
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok.access_token)
    try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1')
    {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
        return @{ Authorization = "Basic $encoded" }
    }
    else
    {
        return @{ Authorization = "Bearer $plain" }
    }
}

function Get-TestOrganizationName
{
    return (Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')).OrganizationName
}

# ---------------------------------------------------------------------------
# Internal helpers — resolve effective org/auth from globals or clixml.
# ---------------------------------------------------------------------------

function Resolve-TestOrg        { if ($Global:TestOrg)        { $Global:TestOrg }        else { Get-TestOrganizationName } }
function Resolve-TestAuthHeader { if ($Global:TestAuthHeader) { $Global:TestAuthHeader } else { New-TestAuthHeader } }

# ---------------------------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------------------------

function New-TestProject
{
    param(
        [string]$Organization,
        [Parameter(Mandatory)][string]$ProjectName,
        [hashtable]$AuthHeader,
        [string]$ProcessTemplate = 'Agile',
        [int]$TimeoutSeconds     = 120
    )

    if (-not $Organization) { $Organization = Resolve-TestOrg }
    if (-not $AuthHeader)   { $AuthHeader   = Resolve-TestAuthHeader }

    # Idempotent — return immediately if already wellFormed
    try
    {
        $existing = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/_apis/projects/$ProjectName`?api-version=7.1-preview.4" -Headers $AuthHeader -ErrorAction Stop
        if ($existing.state -eq 'wellFormed') { return }
    }
    catch { }

    # Resolve process template ID
    $templateId = (Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/_apis/process/processes?api-version=7.1-preview.1" -Headers $AuthHeader).value |
        Where-Object { $_.name -eq $ProcessTemplate } | Select-Object -First 1 -ExpandProperty id
    if (-not $templateId) { throw "[New-TestProject] Process template '$ProcessTemplate' not found in org '$Organization'." }

    $body = @{
        name       = $ProjectName
        visibility = 'private'
        capabilities = @{
            versioncontrol  = @{ sourceControlType = 'Git' }
            processTemplate = @{ templateTypeId = $templateId }
        }
    } | ConvertTo-Json -Depth 5

    $null = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.0" `
        -Method Post -Headers $AuthHeader -Body $body -ContentType 'application/json'

    # Poll until wellFormed
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $state    = $null
    do
    {
        Start-Sleep -Seconds 3
        try { $state = (Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/_apis/projects/$ProjectName`?api-version=7.1-preview.4" -Headers $AuthHeader).state }
        catch { $state = $null }
    }
    while ($state -ne 'wellFormed' -and (Get-Date) -lt $deadline)

    if ($state -ne 'wellFormed')
    {
        throw "[New-TestProject] Project '$ProjectName' did not reach wellFormed within ${TimeoutSeconds}s (last state: $state)."
    }
}

function New-TestGitRepository
{
    param(
        [string]$Organization,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$RepositoryName,
        [hashtable]$AuthHeader
    )

    if (-not $Organization) { $Organization = Resolve-TestOrg }
    if (-not $AuthHeader)   { $AuthHeader   = Resolve-TestAuthHeader }

    $body = @{ name = $RepositoryName; project = @{ name = $ProjectName } } | ConvertTo-Json
    try
    {
        $null = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/$ProjectName/_apis/git/repositories?api-version=7.1-preview.1" `
            -Method Post -Headers $AuthHeader -Body $body -ContentType 'application/json'
    }
    catch
    {
        if ("$_" -notmatch '409|already exist') { throw "[New-TestGitRepository] Failed to create repository '$RepositoryName': $_" }
    }
}

function New-TestGroup
{
    param(
        [string]$Organization,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$GroupName,
        [hashtable]$AuthHeader
    )

    if (-not $Organization) { $Organization = Resolve-TestOrg }
    if (-not $AuthHeader)   { $AuthHeader   = Resolve-TestAuthHeader }

    # Get the project's graph scope descriptor so the group is project-scoped
    $proj = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/_apis/projects/$ProjectName`?api-version=7.1-preview.4" -Headers $AuthHeader
    $desc = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/descriptors/$($proj.id)?api-version=7.1-preview.1" -Headers $AuthHeader

    $body = @{ displayName = $GroupName } | ConvertTo-Json
    try
    {
        $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?scopeDescriptor=$($desc.value)&api-version=7.1-preview.1" `
            -Method Post -Headers $AuthHeader -Body $body -ContentType 'application/json'
    }
    catch
    {
        if ("$_" -notmatch '409|already exist') { throw "[New-TestGroup] Failed to create group '$GroupName' in '$ProjectName': $_" }
    }
}

function New-TestPipelineEnvironment
{
    param(
        [string]$Organization,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$EnvironmentName,
        [hashtable]$AuthHeader,
        [string]$Description = ''
    )

    if (-not $Organization) { $Organization = Resolve-TestOrg }
    if (-not $AuthHeader)   { $AuthHeader   = Resolve-TestAuthHeader }

    $body = @{ name = $EnvironmentName; description = $Description } | ConvertTo-Json
    try
    {
        $null = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/$ProjectName/_apis/distributedtask/environments?api-version=7.1-preview.1" `
            -Method Post -Headers $AuthHeader -Body $body -ContentType 'application/json'
    }
    catch
    {
        if ("$_" -notmatch '409|already exist') { throw "[New-TestPipelineEnvironment] Failed to create environment '$EnvironmentName': $_" }
    }
}

function New-TestArtifactFeed
{
    param(
        [string]$Organization,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [hashtable]$AuthHeader,
        [string]$Description = ''
    )

    if (-not $Organization) { $Organization = Resolve-TestOrg }
    if (-not $AuthHeader)   { $AuthHeader   = Resolve-TestAuthHeader }

    $body = @{ name = $FeedName; description = $Description } | ConvertTo-Json
    try
    {
        $null = Invoke-RestMethod -Uri "https://feeds.dev.azure.com/$Organization/$ProjectName/_apis/packaging/feeds?api-version=7.1-preview.1" `
            -Method Post -Headers $AuthHeader -Body $body -ContentType 'application/json'
    }
    catch
    {
        if ("$_" -notmatch '409|already exist') { throw "[New-TestArtifactFeed] Failed to create feed '$FeedName': $_" }
    }
}

function New-TestAgentPool
{
    param(
        [string]$Organization,
        [Parameter(Mandatory)][string]$PoolName,
        [hashtable]$AuthHeader,
        [string]$PoolType = 'automation'
    )

    if (-not $Organization) { $Organization = Resolve-TestOrg }
    if (-not $AuthHeader)   { $AuthHeader   = Resolve-TestAuthHeader }

    $body = @{ name = $PoolName; poolType = $PoolType; autoProvision = $false } | ConvertTo-Json
    try
    {
        $null = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/_apis/distributedtask/pools?api-version=7.1" `
            -Method Post -Headers $AuthHeader -Body $body -ContentType 'application/json'
    }
    catch
    {
        if ("$_" -notmatch '409|already exist') { throw "[New-TestAgentPool] Failed to create agent pool '$PoolName': $_" }
    }
}

# ---------------------------------------------------------------------------
# Legacy aliases — kept for the 27 test files that call New-Project etc.
# ---------------------------------------------------------------------------

function New-Project
{
    param([string]$ProjectName)
    New-TestProject -Organization (Resolve-TestOrg) -ProjectName $ProjectName -AuthHeader (Resolve-TestAuthHeader)
}

function New-Repository
{
    param([string]$ProjectName, [string]$RepositoryName)
    New-TestGitRepository -Organization (Resolve-TestOrg) -ProjectName $ProjectName -RepositoryName $RepositoryName -AuthHeader (Resolve-TestAuthHeader)
}

function New-Group
{
    param([string]$ProjectName, [string]$GroupName)
    New-TestGroup -Organization (Resolve-TestOrg) -ProjectName $ProjectName -GroupName $GroupName -AuthHeader (Resolve-TestAuthHeader)
}
