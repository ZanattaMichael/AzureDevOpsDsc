# DSC AzDoDeploymentGroup Resource

## Syntax

```PowerShell
AzDoDeploymentGroup [string] #ResourceName
{
    ProjectName           = [String]$ProjectName
    DeploymentGroupName   = [String]$DeploymentGroupName
    [ Description         = [String]$Description ]
    [ Tags                = [String[]]$Tags ]
    [ Ensure              = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **DeploymentGroupName**: The name of the deployment group. This is a key property.
- **Description**: An optional description for the deployment group.
- **Tags**: An array of tag strings to associate with the deployment group for filtering and targeting.
- **Ensure**: Specifies whether the deployment group should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages Azure DevOps deployment groups, which are collections of physical or virtual machines used as deployment targets for classic release pipelines. Agents installed on these machines register with the deployment group to receive deployments.

## Examples

## Example 1: Sample Configuration using AzDoDeploymentGroup Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoDeploymentGroup AddDeploymentGroup {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            Description         = 'Deployment group for production web servers'
            Tags                = @('Production', 'Windows', 'IIS')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoDeploymentGroup
$properties = @{
    ProjectName         = 'MyProject'
    DeploymentGroupName = 'ProductionServers'
}

Invoke-DscResource -Name 'AzDoDeploymentGroup' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  DeploymentGroupName: ProductionServers
}

resources:
- name: Production Servers Deployment Group
  type: AzureDevOpsDsc/AzDoDeploymentGroup
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    DeploymentGroupName: $DeploymentGroupName
    Description: Deployment group for production web servers
    Tags:
      - Production
      - Windows
      - IIS
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
