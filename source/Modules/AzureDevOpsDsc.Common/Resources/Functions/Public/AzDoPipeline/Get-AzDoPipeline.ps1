<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps YAML pipeline.

.DESCRIPTION
Looks the pipeline up by name, then reads its classic build definition to compare the repository
(name, type, default branch, and - for an external repository - the connected service id) and any
managed variables against the desired state. The Pipelines API alone cannot drive this comparison:
it does not return an external repository's type or connected service, and has no concept of
variables at all.

Secret variable values are write-only - the API never returns one - so a secret is compared only
on its presence and its 'IsSecret'/'AllowOverride' flags, never its value.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER PipelineName
The name of the pipeline.

.PARAMETER RepositoryName
The repository that contains the YAML file. An Azure Repos repository name, or 'owner/repo' for
GitHub/GitHub Enterprise/Bitbucket.

.PARAMETER YamlPath
The path to the YAML pipeline definition file.

.PARAMETER FolderPath
The folder path under which the pipeline is organised.

.PARAMETER DefaultBranch
The default branch for the pipeline.

.PARAMETER RepositoryType
The type of repository backing the pipeline. 'TfsGit', 'GitHub', 'GitHubEnterprise' or
'Bitbucket'.

.PARAMETER ServiceConnectionName
The service connection used to reach the repository. Required when 'RepositoryType' is not
'TfsGit'.

.PARAMETER Variables
Pipeline variables to manage, as an array of hashtables shaped
'@{ Name; Value; IsSecret; AllowOverride }'.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoPipeline -ProjectName 'Contoso' -PipelineName 'CI' -RepositoryName 'Contoso' -YamlPath 'azure-pipelines.yml'
#>
Function Get-AzDoPipeline
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$PipelineName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$YamlPath,
        [Parameter()][string]$FolderPath = '\',
        [Parameter()][string]$DefaultBranch = 'main',
        [Parameter()][ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')][string]$RepositoryType = 'TfsGit',
        [Parameter()][string]$ServiceConnectionName,
        [Parameter()][Hashtable[]]$Variables,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoPipeline] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $PipelineName
    $pipeline = Get-CacheItem -Key $cacheKey -Type 'LivePipelines'

    if (-not $pipeline)
    {
        Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' not in cache — falling back to live API lookup."
        $OrgName      = Get-AzDoOrganizationName
        $allPipelines = List-DevOpsPipelines -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $pipeline     = $allPipelines | Where-Object { $_.name -eq $PipelineName } | Select-Object -First 1
        if ($pipeline) { Add-CacheItem -Key $cacheKey -Value $pipeline -Type 'LivePipelines' }
    }

    if (-not $pipeline)
    {
        Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' found."
    $result.liveCache = $pipeline
    $result.Ensure    = [Ensure]::Present

    # A GitHub/GitHub Enterprise/Bitbucket pipeline needs a service connection to resolve to an
    # endpoint id. This check is repeated in New-/Set-AzDoPipeline, since 'Error' here still calls
    # 'Set' (see AzDevOpsDscResourceBase.GetDscRequiredAction()).
    if ($RepositoryType -ne 'TfsGit' -and [String]::IsNullOrWhiteSpace($ServiceConnectionName))
    {
        Write-Error "[Get-AzDoPipeline] 'ServiceConnectionName' is required when 'RepositoryType' is '$RepositoryType'."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason  = 'ServiceConnectionNameRequired'
        return $result
    }

    $OrgName = Get-AzDoOrganizationName
    $ApiUri  = "https://dev.azure.com/$OrgName"

    try
    {
        $definition = Get-DevOpsBuildDefinition -ApiUri $ApiUri -ProjectName $ProjectName -DefinitionId $pipeline.id
    }
    catch
    {
        Write-Error "[Get-AzDoPipeline] Failed to read the build definition for pipeline '$PipelineName': $_"
        $result.status = [DSCGetSummaryState]::Error
        $result.reason  = 'BuildDefinitionLookupFailed'
        return $result
    }

    if ($null -eq $definition)
    {
        Write-Error "[Get-AzDoPipeline] Build definition for pipeline '$PipelineName' returned nothing."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason  = 'BuildDefinitionLookupFailed'
        return $result
    }

    $result.buildDefinition = $definition

    $serviceConnectionId = $null

    if ($RepositoryType -ne 'TfsGit')
    {
        $connection = Resolve-AzDoServiceConnection -ProjectName $ProjectName -ConnectionName $ServiceConnectionName
        if (-not $connection)
        {
            Write-Error "[Get-AzDoPipeline] Service connection '$ServiceConnectionName' not found in project '$ProjectName'."
            $result.status = [DSCGetSummaryState]::Error
            $result.reason  = 'ServiceConnectionNotFound'
            return $result
        }
        $serviceConnectionId = $connection.id
        $result.serviceConnectionId = $serviceConnectionId
    }

    $propertiesChanged = @()

    if ("$($definition.repository.name)" -ne "$RepositoryName")
    {
        Write-Verbose "[Get-AzDoPipeline] RepositoryName differs for pipeline '$PipelineName'."
        $propertiesChanged += 'RepositoryName'
    }

    $currentYaml = "$($definition.process.yamlFilename)".TrimStart('/')
    if ($currentYaml -ne "$YamlPath".TrimStart('/'))
    {
        Write-Verbose "[Get-AzDoPipeline] YamlPath differs for pipeline '$PipelineName'."
        $propertiesChanged += 'YamlPath'
    }

    if ((Format-AzDoPipelineFolderPath -Path $definition.path) -ne (Format-AzDoPipelineFolderPath -Path $FolderPath))
    {
        Write-Verbose "[Get-AzDoPipeline] FolderPath differs for pipeline '$PipelineName'."
        $propertiesChanged += 'FolderPath'
    }

    $currentBranch = "$($definition.repository.defaultBranch)" -replace '^refs/heads/', ''
    if ($currentBranch -ne "$DefaultBranch")
    {
        Write-Verbose "[Get-AzDoPipeline] DefaultBranch differs for pipeline '$PipelineName'."
        $propertiesChanged += 'DefaultBranch'
    }

    if ("$($definition.repository.type)" -ne "$RepositoryType")
    {
        Write-Verbose "[Get-AzDoPipeline] RepositoryType differs for pipeline '$PipelineName'."
        $propertiesChanged += 'RepositoryType'
    }

    if ($RepositoryType -ne 'TfsGit')
    {
        $currentConnectionId = "$($definition.repository.properties.connectedServiceId)"
        if ($currentConnectionId -ne "$serviceConnectionId")
        {
            Write-Verbose "[Get-AzDoPipeline] ServiceConnectionName differs for pipeline '$PipelineName'."
            $propertiesChanged += 'ServiceConnectionName'
        }
    }

    if ($PSBoundParameters.ContainsKey('Variables') -and $Variables)
    {
        $liveVariables = $definition.variables

        foreach ($variable in $Variables)
        {
            $name = [string]$variable.Name
            $desiredIsSecret = if ($variable.ContainsKey('IsSecret')) { [bool]$variable.IsSecret } else { $false }
            $desiredAllowOverride = if ($variable.ContainsKey('AllowOverride')) { [bool]$variable.AllowOverride } else { $false }

            $liveVariableProperty = if ($liveVariables) { $liveVariables.PSObject.Properties[$name] } else { $null }

            if (-not $liveVariableProperty)
            {
                Write-Verbose "[Get-AzDoPipeline] Variable '$name' is missing on pipeline '$PipelineName'."
                $propertiesChanged += 'Variables'
                continue
            }

            $liveVariable = $liveVariableProperty.Value

            if ([bool]$liveVariable.isSecret -ne $desiredIsSecret)
            {
                Write-Verbose "[Get-AzDoPipeline] Variable '$name' IsSecret differs for pipeline '$PipelineName'."
                $propertiesChanged += 'Variables'
                continue
            }

            if ([bool]$liveVariable.allowOverride -ne $desiredAllowOverride)
            {
                Write-Verbose "[Get-AzDoPipeline] Variable '$name' AllowOverride differs for pipeline '$PipelineName'."
                $propertiesChanged += 'Variables'
                continue
            }

            # Secret values are write-only - the API never returns one, so only presence and the
            # IsSecret/AllowOverride flags can be compared here. A secret value changed only on the
            # live pipeline (or in the configuration) is never detected as drift.
            if (-not $desiredIsSecret)
            {
                $desiredValue = if ($null -eq $variable.Value) { '' } else { [string]$variable.Value }
                if ("$($liveVariable.value)" -ne $desiredValue)
                {
                    Write-Verbose "[Get-AzDoPipeline] Variable '$name' Value differs for pipeline '$PipelineName'."
                    $propertiesChanged += 'Variables'
                }
            }
        }
    }

    $result.propertiesChanged = @($propertiesChanged | Select-Object -Unique)
    $result.status = if ($result.propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' status: $($result.status)."

    return $result
}
