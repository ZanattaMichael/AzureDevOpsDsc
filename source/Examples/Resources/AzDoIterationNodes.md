# DSC AzDoIterationNodes Resource

## Syntax

```PowerShell
AzDoIterationNodes [string] #ResourceName
{
    ProjectName              = [String]$ProjectName
    [ IterationAttributes    = [HashTable[]]$IterationAttributes ]
    [ Ensure                 = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **IterationAttributes**: An array of hashtables defining iterations (sprints). Each hashtable can include `Name`, `StartDate`, and `FinishDate`.
- **Ensure**: Specifies whether the iteration nodes should exist. Valid values are `Present` and `Absent`.

### IterationAttributes Syntax

``` PowerShell
AzDoIterationNodes/IterationAttributes
{
    Name       = [String]$IterationName
    StartDate  = [String]$StartDate    # Format: 'yyyy-MM-dd'
    FinishDate = [String]$FinishDate   # Format: 'yyyy-MM-dd'
}
```

## Additional Information

This resource manages the iteration (sprint) hierarchy within an Azure DevOps project. Iterations define time-boxed development cycles and can be configured with start and end dates to support sprint planning.

## Examples

## Example 1: Sample Configuration using AzDoIterationNodes Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoIterationNodes AddAzDoIterationNodes {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            IterationAttributes = @(
                @{
                    Name       = 'Sprint 1'
                    StartDate  = '2024-01-01'
                    FinishDate = '2024-01-14'
                }
                @{
                    Name       = 'Sprint 2'
                    StartDate  = '2024-01-15'
                    FinishDate = '2024-01-28'
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoIterationNodes
$properties = @{
    ProjectName         = 'MyProject'
    IterationAttributes = @(
        @{
            Name       = 'Sprint 1'
            StartDate  = '2024-01-01'
            FinishDate = '2024-01-14'
        }
    )
}

Invoke-DscResource -Name 'AzDoIterationNodes' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: MyProject Iteration Nodes
  type: AzureDevOpsDsc/AzDoIterationNodes
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    IterationAttributes:
      - Name: Sprint 1
        StartDate: '2024-01-01'
        FinishDate: '2024-01-14'
      - Name: Sprint 2
        StartDate: '2024-01-15'
        FinishDate: '2024-01-28'
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
