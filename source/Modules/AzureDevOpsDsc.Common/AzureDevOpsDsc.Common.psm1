[CmdletBinding()]
param (
    [Parameter()]
    [Switch]
    $isClass
)

# Import the 'DscResource.Common' helper module that ships beside this one in the built module
# (<version>\Modules\DscResource.Common). The root module's own import of it lands in the root
# module's session state, which this nested module cannot see, so without this Get-LocalizedData
# is resolved by command auto-discovery. That finds it exported by AzureDevOpsDscNative - the
# module still being loaded - and fails with "the module could not be loaded" in any process that
# has not already imported DscResource.Common globally, such as the DSC v3 adapter's pwsh.
# The source tree has no sibling copy; there the caller is expected to have loaded it.
$script:resourceHelperModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'DscResource.Common'
if (Test-Path -Path $script:resourceHelperModulePath)
{
    Import-Module -Name $script:resourceHelperModulePath
}

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
    "$ModuleRoot\Api\Functions\Private\Command\ClassificationNode",
    "$ModuleRoot\Api\Functions\Private\Cache\Cache Initalization",
    "$ModuleRoot\Api\Functions\Private\Authentication",

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
Export-ModuleMember -Function 'Test-AzDevOpsProjectName'
Export-ModuleMember -Function 'ConvertTo-Base64String'
# Called by [AzDevOpsDscResourceBase]::ExportDscResourceInstances(), which runs in the class
# module's scope and cannot see this module's unexported functions.
Export-ModuleMember -Function 'Protect-AzDoExportedSecretProperty'

# Stop processing
if ($isClass)
{
    return
}
