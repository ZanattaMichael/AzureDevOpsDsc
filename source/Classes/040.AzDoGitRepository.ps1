<#
.SYNOPSIS
    This class represents an Azure DevOps Git repository.

.DESCRIPTION
    The AzDoGitRepository class is a DSC resource that allows you to manage Azure DevOps Git repositories.
    It inherits from the AzDevOpsDscResourceBase class.

    Seeding a new repository from another Git source is create-time only: 'SourceRepository',
    'SourceType' and 'ImportServiceConnectionName' are only ever read by New() and are listed in
    'GetDscResourcePropertyNamesWithNoSetSupport()'. An existing repository is never re-imported by
    Set(), and diverging from whatever it was originally seeded with is not reported as drift by
    Test() - only 'IsDisabled' is compared/enforced on an existing repository.

.NOTES
    Author: Michael Zanatta
    Date: 2025-01-06

.LINK
    GitHub Repository: <link to the GitHub repository>

.LINK
    Import Requests - Create: https://learn.microsoft.com/en-us/rest/api/azure/devops/git/import-requests/create

.LINK
    Repositories - Create (parentRepository / forking): https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories/create

.PARAMETER ProjectName
    The name of the Azure DevOps project where the Git repository is located.

.PARAMETER RepositoryName
    The name of the Git repository. This is the key property for the resource.

.PARAMETER SourceRepository
    Optional. Seeds the repository at creation time. Its meaning depends on 'SourceType':
    a Git URL (for example 'https://github.com/MyUser/MyRepository.git') for an import, or
    'Project/Repo' (or just 'Repo' for a repository in the same project) for a fork. When omitted,
    an empty repository is created. Ignored on an existing repository - never re-applied by Set().

.PARAMETER SourceType
    Optional. Selects how 'SourceRepository' is used: 'Import' requests an import from an external
    Git URL, 'Fork' creates the repository as a fork of an existing Azure DevOps repository. When
    omitted and 'SourceRepository' is set, it defaults to 'Import' if the value looks like a URL
    (or an SSH remote, e.g. 'git@host:owner/repo.git'), and to 'Fork' otherwise.

.PARAMETER ImportServiceConnectionName
    Optional. The name of a generic Git service connection (in the same project) that holds the
    credentials needed to import from a private 'SourceRepository' URL. Only used when
    'SourceType' is 'Import'. Omit it for a public source.

.PARAMETER IsDisabled
    Optional. Disables or enables the repository. Unlike the source properties above, this is a
    plain repository property the API can update at any time, so it is compared and enforced on
    every Test()/Set() - not just at creation. Defaults to $false.

.EXAMPLE
    This example creates an empty Git repository.

    Configuration Example {
        Import-DscResource -ModuleName AzDoGitRepository

        AzDoGitRepository MyGitRepository {
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            Ensure         = 'Present'
        }
    }

.EXAMPLE
    This example imports the contents of a public GitHub repository at creation time.

    Configuration Example {
        Import-DscResource -ModuleName AzDoGitRepository

        AzDoGitRepository MyGitRepository {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            SourceRepository = 'https://github.com/MyUser/MyRepository.git'
            Ensure           = 'Present'
        }
    }

.EXAMPLE
    This example imports from a private Git URL using the credentials held by the
    'GitHub-Import' service connection.

    Configuration Example {
        Import-DscResource -ModuleName AzDoGitRepository

        AzDoGitRepository MyGitRepository {
            ProjectName                 = 'MyProject'
            RepositoryName               = 'MyRepository'
            SourceRepository             = 'https://github.com/MyOrg/PrivateRepository.git'
            ImportServiceConnectionName = 'GitHub-Import'
            Ensure                       = 'Present'
        }
    }

.EXAMPLE
    This example forks 'MyRepository' from 'UpstreamRepository' in the 'UpstreamProject' project.

    Configuration Example {
        Import-DscResource -ModuleName AzDoGitRepository

        AzDoGitRepository MyGitRepository {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            SourceRepository = 'UpstreamProject/UpstreamRepository'
            SourceType       = 'Fork'
            Ensure           = 'Present'
        }
    }

.INPUTS
    None

.OUTPUTS
    None
#>

[DscResource()]
class AzDoGitRepository : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [Alias('Repository')]
    [System.String]$RepositoryName

    [DscProperty()]
    [Alias('Source')]
    [System.String]$SourceRepository

    [DscProperty()]
    [Alias('SourceKind')]
    [ValidateSet('', 'Import', 'Fork')]
    [System.String]$SourceType

    [DscProperty()]
    [Alias('ServiceConnection')]
    [System.String]$ImportServiceConnectionName

    [DscProperty()]
    [System.Boolean]$IsDisabled = $false

    AzDoGitRepository()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoGitRepository] Get()
    {
        return [AzDoGitRepository]$($this.GetDscCurrentStateProperties())
    }

    <#
        .NOTES
            Discovered by the DSC v3 PowerShell adapter (Microsoft.Adapter/PowerShell) by
            reflection on this static, parameterless method - see docs/USAGE.md, "Onboarding an
            existing organization with export". Delegates to the shared base-class helper, which
            calls Export-AzDoGitRepository and converts each returned hashtable into an
            [AzDoGitRepository].
    #>
    static [AzDoGitRepository[]] Export()
    {
        return [AzDoGitRepository[]]([AzDevOpsDscResourceBase]::ExportDscResourceInstances([AzDoGitRepository]))
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        # SourceRepository/SourceType/ImportServiceConnectionName seed a repository only when it is
        # created (New()). They are deliberately excluded from Set()'s parameters so an existing
        # repository is never re-imported/re-forked. 'ProjectName'/'RepositoryName' are identity
        # properties and must never be listed here - Set() needs them to know which repository to
        # update.
        return @('SourceRepository', 'SourceType', 'ImportServiceConnectionName')
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName                 = $CurrentResourceObject.ProjectName
        $properties.RepositoryName               = $CurrentResourceObject.RepositoryName
        $properties.SourceRepository             = $CurrentResourceObject.SourceRepository
        $properties.SourceType                   = $CurrentResourceObject.SourceType
        $properties.ImportServiceConnectionName  = $CurrentResourceObject.ImportServiceConnectionName
        $properties.IsDisabled                   = $CurrentResourceObject.IsDisabled
        $properties.Ensure                       = $CurrentResourceObject.Ensure
        $properties.LookupResult                 = $CurrentResourceObject.LookupResult

        Write-Verbose "[AzDoProjectGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
