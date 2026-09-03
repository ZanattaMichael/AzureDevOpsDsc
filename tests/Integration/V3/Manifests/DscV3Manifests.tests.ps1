<#
    .SYNOPSIS
        Integration tests for the DSC v3 adapted resource manifests.

    .DESCRIPTION
        `build.ps1 -Tasks dscv3` emits one *.dsc.adaptedResource.json per [DscResource()]
        class plus a combined <Module>.dsc.manifests.json list. Those manifests are what a
        DSC v3 host reads to discover this module's resources and validate configuration
        against them, so a manifest that is missing, misnamed or wrongly typed breaks v3
        consumers without breaking anything the v2 tests exercise.

        The failure mode these tests exist for is silent. DscResource.Authoring derives each
        property's JSON schema type from the AST TypeName, which yields the fully-qualified
        name ("System.Boolean") for this module's convention rather than the short alias
        ("bool") its type map expects - so the property falls back to "string" and nothing
        errors. Fix_DscAdaptedResourceManifestTypes repairs that after generation. Nothing
        was checking the repair actually happened: if the task stops running, stops matching,
        or the upstream tool changes shape, every numeric and boolean property silently
        becomes a string again and the build still goes green.

        Runs against the built module, so `build.ps1 -Tasks build` and `-Tasks dscv3` must
        have run first. The CLI context at the end additionally needs `dsc` on PATH with a
        working PowerShell adapter.
#>

BeforeDiscovery {
    $moduleName = 'AzureDevOpsDscNative'

    $builtModule = Get-Module -Name $moduleName -ListAvailable |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if (-not $builtModule)
    {
        throw "[V3] Module '$moduleName' is not resolvable on PSModulePath. Run 'build.ps1 -Tasks build' first."
    }

    $moduleBase    = $builtModule.ModuleBase
    $moduleVersion = $builtModule.Version.ToString()
    $manifestList  = Join-Path -Path $moduleBase -ChildPath "$moduleName.dsc.manifests.json"

    $manifestFiles = @(Get-ChildItem -Path $moduleBase -Filter '*.dsc.adaptedResource.json' -File)

    if ($manifestFiles.Count -eq 0)
    {
        throw ("[V3] No *.dsc.adaptedResource.json manifests found under '$moduleBase'. " +
               "Run 'build.ps1 -Tasks dscv3' before this suite.")
    }

    #
    # Index every [DscResource()] class in the built module, with each property's declared
    # PowerShell type and whether it is a key. Read from the AST rather than from
    # Get-DscResource so this does not depend on a DSC host being able to load the module,
    # and so inherited properties (Ensure, declared on AzDevOpsDscResourceBase) are seen.

    $builtModulePsm1 = Join-Path -Path $moduleBase -ChildPath "$moduleName.psm1"
    $parseErrors = $null
    $moduleAst = [System.Management.Automation.Language.Parser]::ParseFile($builtModulePsm1, [ref] $null, [ref] $parseErrors)

    # Parse errors are deliberately NOT fatal. PowerShell resolves the types named in a
    # class declaration at parse time, so a file whose classes reference a type this
    # process cannot load reports errors while still producing a complete, walkable AST.
    # Treating that as "the module is broken" would fail the whole suite over something
    # this test does not depend on - the class shapes below come out of the AST either way.
    $classAsts = $moduleAst.FindAll(
        { $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] -and $args[0].IsClass },
        $true
    )

    if ($classAsts.Count -eq 0)
    {
        throw ("[V3] No class definitions found in '$builtModulePsm1'. The manifests cannot be " +
               "checked against the classes they describe." +
               $(if ($parseErrors) { " Parse errors: $($parseErrors -join '; ')" }))
    }

    $classByName = @{}
    foreach ($classAst in $classAsts)
    {
        $classByName[$classAst.Name] = $classAst
    }

    # Declared PowerShell type -> the JSON schema type a correct manifest must carry.
    # Deliberately partial: enums, hashtables, arrays and class-typed properties are left
    # out because the correct emission for them is the generator's business, and asserting
    # a guess would make this suite fail on shapes it cannot actually judge. Everything
    # listed here is a type whose mapping is unambiguous - and the boolean/integer rows are
    # exactly the ones the generator gets wrong on its own.
    $jsonTypeByPsType = @{
        'system.string'  = 'string';  'string'  = 'string'
        'system.boolean' = 'boolean'; 'boolean' = 'boolean'; 'bool' = 'boolean'
        'system.int16'   = 'integer'; 'int16'   = 'integer'
        'system.int32'   = 'integer'; 'int32'   = 'integer'; 'int'  = 'integer'
        'system.int64'   = 'integer'; 'int64'   = 'integer'; 'long' = 'integer'
        'system.uint16'  = 'integer'; 'uint16'  = 'integer'
        'system.uint32'  = 'integer'; 'uint32'  = 'integer'
        'system.uint64'  = 'integer'; 'uint64'  = 'integer'
        'system.byte'    = 'integer'; 'byte'    = 'integer'
        'system.single'  = 'number';  'single'  = 'number'
        'system.double'  = 'number';  'double'  = 'number'
        'system.decimal' = 'number';  'decimal' = 'number'
    }

    function Get-DscClassPropertyInfo
    {
        <#
            Walks a class and its base classes, returning one entry per [DscProperty()],
            with the expected JSON schema type (or $null where this suite does not judge).
        #>
        param ($ClassAst, $ClassIndex, $TypeMap)

        $result  = @{}
        $current = $ClassAst

        while ($null -ne $current)
        {
            foreach ($member in $current.Members)
            {
                if ($member -isnot [System.Management.Automation.Language.PropertyMemberAst]) { continue }
                if ($member.IsHidden) { continue }

                $dscAttribute = $member.Attributes |
                    Where-Object { $_.TypeName.Name -in @('DscProperty', 'DscPropertyAttribute') } |
                    Select-Object -First 1

                if (-not $dscAttribute) { continue }
                # A derived class redeclaring a base property wins; it is seen first.
                if ($result.ContainsKey($member.Name)) { continue }

                $rawTypeName = if ($member.PropertyType) { $member.PropertyType.TypeName.Name } else { '' }
                $isArray     = $rawTypeName.EndsWith('[]')

                $expectedJsonType = $null
                if (-not $isArray)
                {
                    $expectedJsonType = $TypeMap[$rawTypeName.ToLowerInvariant()]
                }

                $result[$member.Name] = @{
                    Name             = $member.Name
                    PsType           = $rawTypeName
                    IsArray          = $isArray
                    ExpectedJsonType = $expectedJsonType
                    IsKey            = [bool] ($dscAttribute.NamedArguments |
                                          Where-Object { $_.ArgumentName -eq 'Key' })
                    IsNotConfigurable = [bool] ($dscAttribute.NamedArguments |
                                          Where-Object { $_.ArgumentName -eq 'NotConfigurable' })
                }
            }

            $baseTypeName = $current.BaseTypes |
                Select-Object -First 1 -ExpandProperty TypeName |
                Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue

            $current = if ($baseTypeName -and $ClassIndex.ContainsKey($baseTypeName)) { $ClassIndex[$baseTypeName] } else { $null }
        }

        return $result
    }

    $dscResourceClassNames = @(
        $classAsts |
            Where-Object {
                $_.Attributes | Where-Object { $_.TypeName.Name -in @('DscResource', 'DscResourceAttribute') }
            } |
            Select-Object -ExpandProperty Name |
            Sort-Object
    )

    # One test case per manifest file, carrying everything the It blocks need. Building the
    # cases here rather than looping inside a single It means a broken manifest is named in
    # the failure and the other 48 still report.
    $manifestCases = @(
        foreach ($file in $manifestFiles)
        {
            # Build the pattern into a variable first. Inline, the comma in the -replace
            # argument list binds tighter than '+', so '\.', '' would be parsed as an array,
            # string-joined into the pattern and the replacement argument silently dropped.
            $prefixPattern = '^' + [regex]::Escape($moduleName) + '\.'
            $className = ($file.Name -replace $prefixPattern, '') -replace '\.dsc\.adaptedResource\.json$', ''

            @{
                FileName      = $file.Name
                FilePath      = $file.FullName
                ClassName     = $className
                ExpectedType  = "$moduleName/$className"
                ModuleName    = $moduleName
                ModuleBase    = $moduleBase
                ModuleVersion = $moduleVersion
                Properties    = if ($classByName.ContainsKey($className))
                                {
                                    Get-DscClassPropertyInfo -ClassAst $classByName[$className] -ClassIndex $classByName -TypeMap $jsonTypeByPsType
                                }
                                else { @{} }
            }
        }
    )

    $classCoverageCases = @(
        foreach ($className in $dscResourceClassNames)
        {
            @{
                ClassName    = $className
                ExpectedFile = Join-Path -Path $moduleBase -ChildPath "$moduleName.$className.dsc.adaptedResource.json"
            }
        }
    )
}

Describe 'DSC v3 adapted resource manifests' {

    # Discovery-phase variables happen to survive into the run phase through the container's
    # script scope, but that is incidental. Resolve them again here so the run phase depends
    # on nothing but BeforeAll.
    BeforeAll {
        $moduleName = 'AzureDevOpsDscNative'

        $builtModule = Get-Module -Name $moduleName -ListAvailable |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1

        $moduleBase = $builtModule.ModuleBase
        $listPath   = Join-Path -Path $moduleBase -ChildPath "$moduleName.dsc.manifests.json"
    }

    Context 'Coverage' {

        It 'generates an adapted resource manifest for the [DscResource()] class <ClassName>' -ForEach $classCoverageCases {
            # A class added without its manifest is invisible to every DSC v3 host, and
            # nothing else in the build fails when that happens.
            Test-Path -LiteralPath $ExpectedFile | Should -BeTrue -Because "'$ExpectedFile' should have been generated by 'build.ps1 -Tasks dscv3'"
        }

        It 'generates the combined manifest list' {
            Test-Path -LiteralPath $listPath | Should -BeTrue -Because "'$listPath' is what a host reads to enumerate the module's resources"
        }
    }

    Context 'Manifest <FileName>' -ForEach $manifestCases {

        BeforeAll {
            $manifest = Get-Content -Raw -LiteralPath $FilePath | ConvertFrom-Json
        }

        It 'is valid JSON carrying the fields a DSC v3 host reads' {
            $manifest              | Should -Not -BeNullOrEmpty
            $manifest.type         | Should -Not -BeNullOrEmpty
            $manifest.version      | Should -Not -BeNullOrEmpty
            $manifest.'$schema'    | Should -Not -BeNullOrEmpty
        }

        It 'declares the resource type <ExpectedType>' {
            # The type is the address a configuration uses. A mismatch between the type and
            # the file it lives in means a configuration that names one resolves another,
            # or nothing at all.
            $manifest.type | Should -BeExactly $ExpectedType
        }

        It 'declares the built module version' {
            $manifest.version | Should -BeExactly $ModuleVersion -Because 'a stale version in the manifest points a host at a module build it did not come from'
        }

        It 'corresponds to a class in the built module' {
            $Properties.Keys.Count | Should -BeGreaterThan 0 -Because "manifest '$FileName' should map to a [DscResource()] class named '$ClassName' in the built module"
        }

        It 'gives every property a JSON schema type matching its declared PowerShell type' {
            $embedded = $manifest.schema.embedded
            $embedded | Should -Not -BeNullOrEmpty -Because 'the embedded schema is what a host validates configuration against'

            $schemaProperties = $embedded.properties
            $schemaProperties | Should -Not -BeNullOrEmpty

            # This is the regression guard. Without Fix_DscAdaptedResourceManifestTypes every
            # boolean and numeric property here reads as "string", which a host accepts and
            # then hands the resource the wrong shape.
            $mismatches = foreach ($propertyName in @($schemaProperties.PSObject.Properties.Name))
            {
                if (-not $Properties.ContainsKey($propertyName)) { continue }

                $expected = $Properties[$propertyName].ExpectedJsonType
                if ($null -eq $expected) { continue }   # a type this suite does not judge

                $actual = $schemaProperties.$propertyName.type

                if ($actual -ne $expected)
                {
                    "{0} is [{1}] so the schema type should be '{2}', but the manifest says '{3}'" -f
                        $propertyName, $Properties[$propertyName].PsType, $expected, $actual
                }
            }

            $mismatches | Should -BeNullOrEmpty -Because "manifest '$FileName' must describe its properties with the types the class actually declares"
        }

        It 'exposes every configurable [DscProperty()] of the class' {
            $schemaProperties = $manifest.schema.embedded.properties
            $schemaProperties | Should -Not -BeNullOrEmpty

            $schemaNames = @($schemaProperties.PSObject.Properties.Name)

            # NotConfigurable properties are outputs, so a host is not required to see them.
            $missing = @(
                $Properties.Values |
                    Where-Object { -not $_.IsNotConfigurable -and $_.Name -notin $schemaNames } |
                    Select-Object -ExpandProperty Name
            )

            $missing | Should -BeNullOrEmpty -Because "a property absent from the manifest cannot be set through DSC v3, even though the class declares it"
        }
    }

    Context 'Combined manifest list' {

        BeforeAll {
            $list = if (Test-Path -LiteralPath $listPath) { Get-Content -Raw -LiteralPath $listPath | ConvertFrom-Json } else { $null }

            $individual = @{}
            foreach ($file in (Get-ChildItem -Path $moduleBase -Filter '*.dsc.adaptedResource.json' -File))
            {
                $m = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
                $individual[$m.type] = $m
            }
        }

        It 'lists exactly the resources the individual manifests describe' {
            $list | Should -Not -BeNullOrEmpty

            $listed = @($list.adaptedResources.type | Sort-Object)
            $files  = @($individual.Keys | Sort-Object)

            $listed | Should -Be $files -Because 'a host that reads the list and a host that reads the files must see the same set of resources'
        }

        It 'agrees with each individual manifest on every property type' {
            # Create_DscResourceManifestsList regenerates its own copies rather than reading
            # the files, so the two are patched separately and can drift apart silently -
            # one correct, one still claiming everything is a string.
            $disagreements = foreach ($listed in $list.adaptedResources)
            {
                if (-not $individual.ContainsKey($listed.type)) { continue }

                $fileProperties   = $individual[$listed.type].schema.embedded.properties
                $listedProperties = $listed.schema.embedded.properties

                if ($null -eq $fileProperties -or $null -eq $listedProperties) { continue }

                foreach ($propertyName in @($fileProperties.PSObject.Properties.Name))
                {
                    $fromFile = $fileProperties.$propertyName.type
                    $fromList = $listedProperties.$propertyName.type

                    if ($fromFile -ne $fromList)
                    {
                        "{0}.{1}: file says '{2}', list says '{3}'" -f $listed.type, $propertyName, $fromFile, $fromList
                    }
                }
            }

            $disagreements | Should -BeNullOrEmpty
        }
    }
}

Describe 'DSC v3 adapted resource manifests (via the dsc CLI)' {

    BeforeAll {
        # Dot-source the helpers here rather than relying on the runner's dot-source:
        # Pester runs test files in their own session state, so functions defined in the
        # runner's script scope are not guaranteed to resolve from inside a test.
        . (Join-Path -Path $PSScriptRoot -ChildPath '..\Supporting\V3TestHelpers.ps1')

        Assert-DscV3Available

        $moduleName = 'AzureDevOpsDscNative'
        $moduleBase = (Get-Module -Name $moduleName -ListAvailable |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1).ModuleBase

        $adapter = Resolve-DscV3PowerShellAdapter

        # An adapter has to be named: `dsc resource list` on its own reports the built-in
        # resources only, and adapted resources - everything this module ships - are
        # enumerated by invoking the adapter, which happens only when one is given.
        # PSModulePath is pinned to the single built module, so the result is bounded.
        $discoveredTypes = @(Get-DscV3ResourceType -Adapter $adapter)

        $moduleTypes = @($discoveredTypes | Where-Object { $_ -like 'AzureDevOpsDscNative/*' } | Sort-Object -Unique)
    }

    It 'surfaces this module''s resources to the dsc CLI' {
        # Well-formed manifests on disk are not the same as a host being able to find the
        # resources through them: the adapter reads them, and a manifest whose path or
        # requireAdapter is wrong is discovered by neither.
        $moduleTypes | Should -Not -BeNullOrEmpty -Because "the adapter should discover AzureDevOpsDscNative resources; it saw: $($discoveredTypes -join ', ')"
    }

    It 'surfaces one resource per generated manifest' {
        # Anything on disk the adapter will not surface is dead weight to a v3 host, and
        # anything surfaced without a manifest cannot be validated against a schema.
        $manifestTypes = @(
            Get-ChildItem -Path $moduleBase -Filter '*.dsc.adaptedResource.json' -File |
                ForEach-Object { (Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json).type } |
                Sort-Object -Unique
        )

        $missing = @($manifestTypes | Where-Object { $_ -notin $moduleTypes })

        $missing | Should -BeNullOrEmpty -Because 'every generated manifest should resolve to a resource the adapter can see'
    }

    It 'surfaces <_>' -ForEach @('AzureDevOpsDscNative/AzDoProject', 'AzureDevOpsDscNative/AzDoGitRepository', 'AzureDevOpsDscNative/AzDoProjectGroup') {
        # The three resources the lifecycle tests drive - if one of these is not discoverable
        # the failures over there are a manifest problem, not a resource problem.
        $moduleTypes | Should -Contain $_
    }
}
