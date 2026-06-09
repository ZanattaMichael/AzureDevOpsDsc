<#
.SYNOPSIS
Formats the descriptor type to match the expected naming conventions.

.DESCRIPTION
This function takes a descriptor type as input and returns a formatted string.
If the descriptor type is "GitRepositories", it returns "Git Repositories".
For all other descriptor types, it returns the input descriptor type unchanged.

.PARAMETER DescriptorType
The descriptor type to be formatted. This parameter is mandatory.

.OUTPUTS
System.String
The formatted descriptor type.

.EXAMPLE
PS C:\> Format-DescriptorType -DescriptorType "GitRepositories"
Git Repositories

.EXAMPLE
PS C:\> Format-DescriptorType -DescriptorType "OtherType"
OtherType
#>
Function Format-DescriptorType
{
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]$DescriptorType
    )

    # The API uses "Git Repositories" where the DSC resource uses "GitRepositories".
    if ($DescriptorType -eq 'GitRepositories') { return 'Git Repositories' }
    return $DescriptorType
}
