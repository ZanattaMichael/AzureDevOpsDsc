<#
.SYNOPSIS
    Dot-sources all Enums and Classes into the caller's scope.

.DESCRIPTION
    Pester v5 rebinds each test/block's session state for scope isolation, which can leave
    PowerShell classes loaded into a different scope (e.g. by the top-level orchestrator)
    unresolvable from inside some It/BeforeAll blocks - surfacing as intermittent
    "Could not find type [X]" failures. Unlike the Common module's Helper/Cache/Public
    functions (resolved via normal command discovery, unaffected by this), classes must be
    reloaded into each test file's own scope to guarantee visibility.

    This script only loads Enums and Classes (cheap, ~0.5s) and must be dot-sourced - not
    called - so the definitions land in the caller's scope rather than this script's own.

.PARAMETER RepositoryRoot
    The repository root path.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $RepositoryRoot
)

$EnumsDirectory = "$RepositoryRoot\source\Enum"
$ClassesDirectory = "$RepositoryRoot\source\Classes"

# Load all the Enums
Get-ChildItem -LiteralPath $EnumsDirectory -File | ForEach-Object {
    . $_.FullName
}

# Load all the Classes
Get-ChildItem -LiteralPath $ClassesDirectory -File | ForEach-Object {
    # Read the file and remove [DscResource()] attribute
    $file = Get-Command $_.FullName
    $content = $file.ScriptContents -replace '\[DscResource\(\)\]', ''
    # Convert the string array into ScriptBlock and dot source it
    $scriptBlock = [ScriptBlock]::Create($content)
    . $scriptBlock
}
