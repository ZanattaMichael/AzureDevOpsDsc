@{
    RootModule           = 'AzureDevOpsDscNative.psm1'

    # Version number of this module.
    moduleVersion      = '0.0.2'

    # ID used to uniquely identify this module
    GUID                 = 'e7eb078e-5e97-42be-ae8f-decb140fc38e'

    # Author of this module
    Author               = 'ZanattaMichael'

    # Company or vendor of this module
    CompanyName          = 'ZanattaMichael'

    # Copyright statement for this module
    Copyright            = 'Copyright the DSC Community contributors and ZanattaMichael. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'A fork of the DSC Community AzureDevOpsDsc module with native DSC v3 support: every resource is discoverable and invokable by dsc.exe via the Microsoft.Adapter/PowerShell adapter, using generated adapted resource manifests, without requiring a wrapper resource.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion  = '7.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion           = '4.0'

    # Functions to export from this module
    #FunctionsToExport    = @()

    # Cmdlets to export from this module
    #CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # Import all the 'DSCClassResource', modules as part of this module
    NestedModules        = @()

    DscResourcesToExport = @(
      'AzDevOpsProject',
      'AzDoGroupPermission',
      'AzDoOrganizationGroup',
      'AzDoProject',
      'AzDoProjectServices',
      'AzDoProjectGroup',
      'AzDoGroupMember',
      'AzDoGitRepository',
      'AzDoGitPermission',
      'AzDoAreaPermission',
      'AzDoIterationPermission',
      'AzDoWIPTags',
      'AzDoAreaNodes',
      'AzDoIterationNodes',
      'AzDoBranchPolicy',
      'AzDoVariableGroup',
      'AzDoServiceConnection',
      'AzDoPipelineEnvironment',
      'AzDoAgentPool',
      'AzDoAgentQueue',
      'AzDoTeam',
      'AzDoTeamMember',
      'AzDoPipeline',
      'AzDoPipelinePermission',
      'AzDoEnvironmentApproval',
      'AzDoVariableGroupPermission',
      'AzDoServiceConnectionPermission',
      'AzDoAgentPoolPermission',
      'AzDoSecurityNamespacePermission',
      'AzDoArtifactFeed',
      'AzDoArtifactFeedPermission',
      'AzDoDeploymentGroup',
      'AzDoTaskGroup',
      'AzDoOrganizationSettings',
      'AzDoExtension',
      'AzDoAuditStream',
      'AzDoProjectPermission',
      'AzDoEnvironmentPermission',
      'AzDoWiki',
      'AzDoNotificationSubscription',
      'AzDoRepositorySettings',
      'AzDoCheckConfiguration',
      'AzDoTeamSettings',
      'AzDoArtifactFeedSettings',
      'AzDoArtifactFeedView',
      'AzDoProcess',
      'AzDoProcessPermission'
      'AzDoUserEntitlement',
      'AzDoServiceHook',
      'AzDoPipelineSettings'
    )

    RequiredAssemblies   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource', 'DSCv3', 'AzureDevOps')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/ZanattaMichael/AzureDevOpsDsc'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
