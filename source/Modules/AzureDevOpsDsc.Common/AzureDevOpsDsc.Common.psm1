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
# Enumerate the function files with System.IO rather than 'Get-ChildItem -Recurse -Include', which
# is several times slower over this many directories and is paid on every import - and DSC imports
# the module afresh for each resource invocation. The order is the one Get-ChildItem gave: each
# listed directory in turn, its files by name, then its subdirectories. Hidden items are skipped,
# as they were, and a file reached through two listed directories is loaded once.
function Get-ModuleFunctionFile
{
    param ([System.String]$Path)

    $compare = [System.StringComparer]::OrdinalIgnoreCase
    $hidden  = [System.IO.FileAttributes]::Hidden

    $files = [System.IO.Directory]::GetFiles($Path)
    [System.Array]::Sort($files, $compare)
    foreach ($file in $files)
    {
        if ($file.EndsWith('.ps1', [System.StringComparison]::OrdinalIgnoreCase) -and
            -not ([System.IO.File]::GetAttributes($file) -band $hidden))
        {
            [System.IO.FileInfo]::new($file)
        }
    }

    $directories = [System.IO.Directory]::GetDirectories($Path)
    [System.Array]::Sort($directories, $compare)
    foreach ($directory in $directories)
    {
        if (-not ([System.IO.File]::GetAttributes($directory) -band $hidden))
        {
            Get-ModuleFunctionFile -Path $directory
        }
    }
}

$loadedFunctionPaths = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::OrdinalIgnoreCase)
$functions = foreach ($functionSubDirectoryPath in $functionSubDirectoryPaths)
{
    # The paths above are written with '\', which PowerShell accepts on every platform but
    # System.IO only on Windows.
    $functionSubDirectoryPath = $functionSubDirectoryPath.Replace('\', [System.IO.Path]::DirectorySeparatorChar)

    if (-not [System.IO.Directory]::Exists($functionSubDirectoryPath))
    {
        # Leave a missing directory to Get-ChildItem, so it is reported as it always was.
        Get-ChildItem -Path $functionSubDirectoryPath -Recurse -Include "*.ps1"
        continue
    }

    foreach ($functionFile in (Get-ModuleFunctionFile -Path ([System.IO.Path]::GetFullPath($functionSubDirectoryPath))))
    {
        if ($loadedFunctionPaths.Add($functionFile.FullName))
        {
            $functionFile
        }
    }
}

Remove-Item -Path 'Function:\Get-ModuleFunctionFile'

# Loop through all PSModule functions and import/dot-source them. The 'Public' ones are exported
# together afterwards: one Export-ModuleMember call per function was a measurable part of the import.
$publicFunctionNames = [System.Collections.Generic.List[System.String]]::new()
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
        $publicFunctionNames.Add($function.BaseName)
    }
}

if ($publicFunctionNames.Count -gt 0)
{
    Export-ModuleMember -Function $publicFunctionNames
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
