<#
.SYNOPSIS
    DSC resource for managing Azure DevOps pipeline authorization on protected resources.

.DESCRIPTION
    Controls which pipeline definitions are allowed to use a protected resource - a service
    connection, agent queue, variable group, secure file, environment or repository - through the
    pipelinePermissions REST API (the "Pipeline permissions" tab shown against the resource in the
    Azure DevOps portal). This is distinct from the resource's security-namespace ACLs (see
    AzDoServiceConnectionPermission, AzDoVariableGroupPermission, AzDoEnvironmentPermission, etc.),
    which control who may *administer* the resource, not which pipelines may *use* it, and it is
    also distinct from AzDoCheckConfiguration, which gates a pipeline run with an approval or other
    check rather than deciding whether the pipeline may reach the resource at all.

    AzDoPipelineSettings.DisableClassicPipelineCreation and the per-resource AllowAllPipelines /
    AuthorizeAllPipelines / AllowAccess flags on AzDoServiceConnection, AzDoVariableGroup and
    similar resources overlap in intent with AllPipelines below - they are older, narrower controls
    that this module keeps for backward compatibility. AzDoPipelineAuthorization is the modern,
    authoritative control because it reads and writes the real pipelinePermissions API; a
    configuration should manage a given resource's open-access setting through one owner, not both.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This is the key property.

.PARAMETER ResourceType
    The type of protected resource. One of: endpoint (service connection), queue (agent queue),
    variablegroup, securefile, environment, repository.

.PARAMETER ResourceName
    The name of the protected resource, resolved via the matching Live* cache for ResourceType
    (falling back to a live API lookup on a cache miss). For 'repository' the underlying API id is
    composed as "{projectId}.{repositoryId}" - the pipelinePermissions API's own convention.

.PARAMETER AuthorizedPipelines
    Pipeline paths authorized to use the resource, e.g. '\Platform\deploy-infra'. A root pipeline
    may be given as just its name. Unresolvable paths are reported as drift/an error rather than
    silently skipped.

.PARAMETER AllPipelines
    Whether all pipelines in the project are authorized to use the resource (maps to
    allPipelines.authorized on the API). Defaults to $false - "open access off".

.PARAMETER ExclusiveList
    When $true, a pipeline currently authorized on the resource but absent from
    AuthorizedPipelines is revoked. When $false (the default), AuthorizedPipelines is additive
    only - other pipelines already authorized in the portal are left alone.

.EXAMPLE
    [AzDoPipelineAuthorization]@{
        ProjectName         = 'MyProject'
        ResourceType        = 'variablegroup'
        ResourceName        = 'Prod Secrets'
        AllPipelines        = $false
        AuthorizedPipelines = @('\Platform\deploy-infra')
        ExclusiveList       = $true
        Ensure              = 'Present'
    }
#>
[DscResource()]
class AzDoPipelineAuthorization : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [ValidateSet('endpoint', 'queue', 'variablegroup', 'securefile', 'environment', 'repository')]
    [System.String]$ResourceType

    [DscProperty(Mandatory)]
    [System.String]$ResourceName

    [DscProperty()]
    [System.String[]]$AuthorizedPipelines

    [DscProperty()]
    [System.Boolean]$AllPipelines = $false

    [DscProperty()]
    [System.Boolean]$ExclusiveList = $false

    AzDoPipelineAuthorization()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoPipelineAuthorization] Get()
    {
        return [AzDoPipelineAuthorization]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.ResourceType         = $CurrentResourceObject.ResourceType
        $properties.ResourceName         = $CurrentResourceObject.ResourceName
        $properties.AuthorizedPipelines  = $CurrentResourceObject.AuthorizedPipelines
        $properties.AllPipelines         = $CurrentResourceObject.AllPipelines
        $properties.ExclusiveList        = $CurrentResourceObject.ExclusiveList
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure
        return $properties
    }
}
