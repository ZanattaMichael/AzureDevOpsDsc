# AzDoAreaNodes Resource

## Syntax

```PowerShell
AzDoAreaNodes [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    [ AreaPaths = [String[]]$AreaPaths ]
}
```

### Properties

- **ProjectName** *(Key, Mandatory)*:  
  The name of the Azure DevOps project where the Area nodes are managed. It serves as the key property of this resource.

- **AreaPaths** *(Optional)*:  
  A string array that contains the Project Area Paths.

## Additional Notes

None

# Examples

## Example 1 - Initial Usage 

Here is an example of how you might use the `AzDoAreaNodes` resource in a DSC configuration script:

```PowerShell
Configuration ExampleConfig
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost
    {
        AzDoAreaNodes 'ManageAreaNodes'
        {
            ProjectName          = 'SampleProject'
            AreaPaths  = @(
                'AreaPath\SubPath\'
                'SecondaryPath\'
            )
        }
    }
}

ExampleConfig
Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoAreaPermission
# Ensure is not required
$properties = @{
    Ensure               = 'Present'
    ProjectName          = 'Test Project'
    AreaPaths            = @(
                                'AreaPath\SubPath\'
                                'SecondaryPath\'
                            )
}

Invoke-DSCResource -Name 'AzDoAreaNodes' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: SampleProject
}

resources:

  - name: Sample AreaPath
    type: AzureDevOpsDsc/AzDoAreaNodes
    properties:
      projectName: $ProjectName
      AreaPaths:
      - 'Sample\Path\'
      - 'Secondary\Path\'
      
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
