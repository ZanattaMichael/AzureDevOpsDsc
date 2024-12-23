[CmdletBinding()]
param (
    [Parameter()]
    [Switch]
    $isClass
)
#using module AzureDevOpsDsc
# Setup/Import 'DscResource.Common' helper module
#$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
#Import-Module -Name $script:resourceHelperModulePath


$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$ModuleRoot = $PSScriptRoot

# Obtain all functions within PSModule
$functionSubDirectoryPaths = @(

    # Classes
    "$ModuleRoot\Api\Classes\",

    # Enum
    #"$ModuleRoot\Api\Enums\",

    # Data
    #"$ModuleRoot\Api\Data\",
    "$ModuleRoot\LocalizedData\",

    # Api
    "$ModuleRoot\Api\Functions\Private\Api",
    "$ModuleRoot\Api\Functions\Private\Cache",
    "$ModuleRoot\Api\Functions\Private\Helper",
    "$ModuleRoot\Api\Functions\Private\Cache\Cache Initalization"
    "$ModuleRoot\Api\Functions\Private\Authentication"

    # Connection
    "$ModuleRoot\Connection\Functions\Private",

    # Resources
    "$ModuleRoot\Resources\Functions\Public",
    "$ModuleRoot\Resources\Functions\Private",

    # Server

    # Services
    "$ModuleRoot\Services\Functions\Public"
)
$functions = Get-ChildItem -Path $functionSubDirectoryPaths -Recurse -Include "*.ps1"


# Loop through all PSModule functions and import/dot-source them (and export them if 'Public')
foreach ($function in $functions)
{
    Write-Verbose "Dot-sourcing '$($function.FullName)'..."
    . (
        [ScriptBlock]::Create(
            [Io.File]::ReadAllText($($function.FullName))
        )
    )

    if ($function.FullName -ilike "$ModuleRoot\*\Functions\Public\*")
    {
        Write-Verbose "Exporting '$($function.BaseName)'..."
        Export-ModuleMember -Function $($function.BaseName)
    }
}

#
# Static Functions that need to be exported

Export-ModuleMember -Function 'AzDoAPI_*'

Export-ModuleMember -Function 'Set-CacheObject'
Export-ModuleMember -Function 'Get-CacheItem'
Export-ModuleMember -Function 'Get-AzDoAPIGroupCache'
Export-ModuleMember -Function 'Get-AzDoAPIProjectCache'
Export-ModuleMember -Function 'Initialize-CacheObject'
Export-ModuleMember -Function 'Get-AzDoCacheObjects'
Export-ModuleMember -Function '*-AzDoProjectGroup'

# Stop processing
if ($isClass)
{
    return
}
