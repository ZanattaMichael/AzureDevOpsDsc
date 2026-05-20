# DSC AzDoArtifactFeedPermission Resource

## Syntax

```PowerShell
AzDoArtifactFeedPermission [string] #ResourceName
{
    ProjectName         = [String]$ProjectName
    FeedName            = [String]$FeedName
    Permissions         = [HashTable[]]$Permissions
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoArtifactFeedPermission/Permissions
{
    identity = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\UserName@email.com'
    #   EXAMPLE:    '[SampleOrganizationName]\Project Collection Administrators'
    role     = [String]$Role # See 'Permission List'
}
```

## Permission List

> Azure Artifacts Feed permissions use a role-based access control model. Assign one of the roles below to each identity.

| Role | Description | Note |
| ---- | ----------- | ---- |
| Reader | Can list and download packages | |
| Collaborator | Can list, download, and save packages from upstream sources | |
| Contributor | Can push, list, and download packages | |
| Administrator | Full control including managing feed settings and permissions | Not recommended. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **FeedName**: The name of the artifact feed. This is a key property.
- **Permissions**: An array of permission hashtables specifying role-based access for identities. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages role-based permissions on Azure Artifacts feeds, controlling which users or groups can read, publish, or administer packages. Unlike other permission resources, Artifact Feed permissions use a role model (Reader, Contributor, Collaborator, Administrator) rather than individual permission bits.

## Examples

## Example 1: Sample Configuration using AzDoArtifactFeedPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeedPermission AddArtifactFeedPermission {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
            Permissions = @(
                @{ identity = '[MyProject]\Contributors'; role = 'Contributor' }
                @{ identity = '[MyProject]\Readers';      role = 'Reader' }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoArtifactFeedPermission
$properties = @{
    ProjectName = 'MyProject'
    FeedName    = 'MyFeed'
    Permissions = @(
        @{ identity = '[MyProject]\Contributors'; role = 'Contributor' }
    )
}

Invoke-DscResource -Name 'AzDoArtifactFeedPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  FeedName: MyFeed
}

resources:
- name: Artifact Feed Permissions
  type: AzureDevOpsDsc/AzDoArtifactFeedPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoArtifactFeed/MyFeed
  properties:
    ProjectName: $ProjectName
    FeedName: $FeedName
    Permissions:
      - identity: '[$ProjectName]\Contributors'
        role: Contributor
      - identity: '[$ProjectName]\Readers'
        role: Reader
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
