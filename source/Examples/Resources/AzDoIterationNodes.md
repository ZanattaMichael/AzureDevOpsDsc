# AzDoIterationNodes Resource

## Syntax

```PowerShell
AzDoIterationNodes [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    [ IterationAttributes = [HashTable[]]$IterationAttributes ]
}
```

### IterationAttributesHashTable Syntax

``` PowerShell
{
    Path = [String]$Path #Path seperated by '/'. e.g Parent Path/Sub Path
    [StartDate = [DateTime]$StartDate] # Preferred format 'yyyy-MM-dd'
    [EndDate = [DateTime]$EndDate] # Preferred format 'yyyy-MM-dd'
}
```

### Properties

- **ProjectName** *(Key, Mandatory)*:  
  The name of the Azure DevOps project where the iteration nodes are managed. It serves as the key property of this resource.

- **IterationAttributes** *(Optional)*:  
  A hashtable array that specifies attributes for the iteration nodes. These attributes can be used to define specific properties or settings for each iteration node.

## Additional Notes

None

# Examples

## Example 1 - Initial Usage 

Here is an example of how you might use the `AzDoIterationNodes` resource in a DSC configuration script:

```PowerShell
Configuration ExampleConfig
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost
    {
        AzDoIterationNodes 'ManageIterationNodes'
        {
            ProjectName          = 'SampleProject'
            IterationAttributes  = @(
                @{
                    Path = 'Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }
            )
        }
    }
}

ExampleConfig
Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoIterationPermission
# Ensure is not required
$properties = @{
    Ensure               = 'Present'
    ProjectName          = 'Test Project'
    IterationAttributes  = @(
        @{
            Path = 'Iteration\Sub Iteration'
            StartDate = '2023-01-01'
            EndDate = '2023-01-31'
        }
    )
}

Invoke-DSCResource -Name 'AzDoIterationNodes' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: SampleProject
}

resources:

  - name: Sample IterationPath
    type: AzureDevOpsDsc/AzDoIterationNodes
    properties:
      projectName: $ProjectName
      IterationAttributes:
        - Path: 'Iteration\Sub Iteration'
          StartDate: '2023-01-01'
          EndDate: '2023-01-31'
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
