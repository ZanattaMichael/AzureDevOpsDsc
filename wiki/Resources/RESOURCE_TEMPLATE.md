# Resource Documentation Template

Use this template to create documentation for AzureDevOpsDscNative resources. Copy this file and replace `[ResourceName]` with the actual resource name.

---

# [ResourceName] Resource

## Description

The `[ResourceName]` DSC resource is used to [describe what this resource does]. [Add any additional context about the resource's purpose and capabilities].

## Syntax

```powershell
[ResourceName] [string] #ResourceName
{
    KeyProperty1 = [Type] $KeyProperty1
    [ KeyProperty2 = [Type] $KeyProperty2 ]
    [ OptionalProperty1 = [Type] $OptionalProperty1 ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **KeyProperty1** [Type] - Description of the key property. [Additional details].

- **KeyProperty2** [Type] - [Optional second key property description].

### Optional Properties

- **OptionalProperty1** [Type] - [Description]. [Valid values if applicable].

- **OptionalProperty2** [Type] - [Description]. [Default value if applicable].

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Resource should exist
  - `'Absent'` - Resource should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **PropertyName1** - [Description]
- **PropertyName2** - [Description]
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: [Basic Use Case]

```powershell
Configuration [ExampleName] {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        [ResourceName] '[ResourceInstance]' {
            KeyProperty1 = 'value1'
            OptionalProperty1 = 'value2'
            Ensure = 'Present'
        }
    }
}

[ExampleName]
Start-DscConfiguration -Path ./[ExampleName] -Wait -Verbose
```

### Example 2: [Advanced Use Case]

```powershell
Configuration [ExampleName2] {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        [ResourceName] '[ResourceInstance]' {
            KeyProperty1     = 'value1'
            OptionalProperty1 = 'value2'
            OptionalProperty2 = 'value3'
            Ensure            = 'Present'
            DependsOn         = '[OtherResource]OtherInstance'
        }
    }
}

[ExampleName2]
Start-DscConfiguration -Path ./[ExampleName2] -Wait -Verbose
```

### Example 3: Using Invoke-DscResource

```powershell
# Get the current state
$properties = @{
    KeyProperty1 = 'value1'
}

$result = Invoke-DscResource -Name '[ResourceName]' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object KeyProperty1, OptionalProperty1, Ensure
```

## Important Notes

### [Section Title - e.g., "Immutable Properties"]

- [Point 1]
- [Point 2]

### [Section Title - e.g., "Prerequisites"]

- [Prerequisite 1]
- [Prerequisite 2]

## Troubleshooting

### Issue: "[Error Message]"

**Cause**: [Explanation of what causes this error]

**Solution**: [How to resolve this issue]

```powershell
# Example troubleshooting code
```

## Related Resources

- [RelatedResource1](RelatedResource1.md) - [Brief description]
- [RelatedResource2](RelatedResource2.md) - [Brief description]

## See Also

- [Azure DevOps Documentation Link](https://docs.microsoft.com/)
- [AzureDevOpsDscNative Home](../Home.md)
