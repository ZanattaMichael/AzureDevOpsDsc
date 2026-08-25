task PreLoad {

    # Add the build output folders to PSModulePath so that tasks running later in
    # the pipeline (and the Pester suites) can resolve both the built module and the
    # nested modules that ship inside it.
    #
    # The nested modules live at:
    #   output/builtModule/<ModuleName>/<Version>/Modules
    # Both the module name and the version are resolved by globbing rather than being
    # hardcoded - the version is supplied at build time via $env:ModuleVersion (from
    # the release tag), so it is not knowable here.

    $RepositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $outputDir = Join-Path -Path $RepositoryRoot -ChildPath 'output'
    $builtModuleDir = Join-Path -Path $outputDir -ChildPath 'builtModule'
    $requiredModulesDir = Join-Path -Path $outputDir -ChildPath 'RequiredModules'

    $delimiter = [System.IO.Path]::PathSeparator
    $moduleList = $env:PSModulePath -split $delimiter

    # On a clean build the built module does not exist yet, so this resolves to
    # nothing on the first pass - that is expected and not an error.
    $nestedModuleDirs = @(
        Get-ChildItem -Path (Join-Path -Path $builtModuleDir -ChildPath '*/*/Modules') -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    )

    $pathsToAdd = @($outputDir, $requiredModulesDir, $builtModuleDir) + $nestedModuleDirs

    foreach ($path in $pathsToAdd) {
        if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -Path $path)) {
            continue
        }

        if ($moduleList -notcontains $path) {
            $env:PSModulePath = '{0}{1}{2}' -f $env:PSModulePath, $delimiter, $path
            $moduleList = $env:PSModulePath -split $delimiter
            Write-Host "Adding $path to PSModulePath"
        }
    }

}
