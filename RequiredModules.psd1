@{
    # Every module below is pinned to an exact version. The build runs these modules in the
    # job that holds the PowerShell Gallery API key, so a new upstream release must not be
    # picked up without anyone looking at it. To update one, change its version in a pull
    # request - the 'List restored build modules' step of the Build workflow shows what was
    # restored. See 'Pinned build dependencies' in CONTRIBUTING.md.
    PSDependOptions                = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = 'PSGallery'
        }
    }

    InvokeBuild                    = '5.14.23'
    PSScriptAnalyzer               = '1.25.0'
    Pester                         = '4.10.1'
    Plaster                        = '2.1.5'
    ModuleBuilder                  = '3.2.18'
    ChangelogManagement            = '3.1.0'
    Sampler                        = '0.120.1'
    'Sampler.GitHubTasks'          = '0.5.0'
    MarkdownLinkCheck              = '0.2.0'
    'DscResource.Test'             = '0.20.0'
    xDscResourceDesigner           = '1.13.0.0'
    'DscResource.Common'           = '0.24.5'

    # The two prerelease pins need AllowPrerelease, or the restore refuses the version.
    'DscResource.AnalyzerRules'    = @{
        Version    = '0.3.0-preview0003'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    'Indented.ScriptAnalyzerRules' = '1.1.0'

    # Prerequisite modules for documentation.
    'DscResource.DocGenerator'     = '0.13.0'
    PlatyPS                        = '0.14.2'

    # Prerequisite module for generating DSC v3 adapted resource manifests.
    'DscResource.Authoring'        = @{
        Version    = '0.2.0-preview0006'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    # Prerequisites modules needed for examples or integration tests
    PSDscResources                 = '2.12.0.0'

    # Dependencies of the modules above (ModuleBuilder needs Configuration and Metadata,
    # Sampler.GitHubTasks needs PowerShellForGitHub). Listed so they are pinned too, rather
    # than resolved to whatever is newest when the build runs.
    Configuration                  = '1.6.0'
    Metadata                       = '1.5.7'
    PowerShellForGitHub            = '0.17.0'
}
