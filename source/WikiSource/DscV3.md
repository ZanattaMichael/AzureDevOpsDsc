# Using the module with DSC v3

Every resource in the module can be used from the DSC v3 command-line tool (`dsc`) as well as from
`Invoke-DscResource`. The module ships an adapted resource manifest for each resource, so `dsc`
finds them through its PowerShell adapter without a wrapper resource.

## Requirements

- **PowerShell 7** and the module installed where PowerShell finds it (`$env:PSModulePath`).
- **The `dsc` command-line tool, with its PowerShell adapter.** An install that has the `dsc`
  executable but not the adapter's manifest files answers `dsc --version` and then lists no
  PowerShell resources. Install the full release archive.
- **DSC 3.2 or later is recommended.** DSC 3.2.0 renamed the adapter from
  `Microsoft.DSC/PowerShell` to `Microsoft.Adapter/PowerShell`. Use the old name on an earlier
  version.
- **`AZDODSC_CACHE_DIRECTORY` set in the environment `dsc` runs in**, pointing at the folder used
  to sign in.

## Sign in first

`dsc` does not sign in for you. Run `New-AzDoAuthenticationProvider` once in PowerShell, as the
account that will run `dsc`. See [Authentication](Authentication).

```powershell
$env:AZDODSC_CACHE_DIRECTORY = Join-Path $HOME '.azuredevopsdsc'
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -useManagedIdentity
```

## Find the resources

A resource is addressed as `AzureDevOpsDscNative/<ResourceName>`.

```powershell
dsc resource list --adapter Microsoft.Adapter/PowerShell 'AzureDevOpsDscNative/*'
```

Name the adapter. `dsc resource list` on its own only reports built-in resources.

## Run one resource

```powershell
$project = '{"ProjectName":"Contoso","ProjectDescription":"Managed by DSC"}'

dsc resource get  --resource AzureDevOpsDscNative/AzDoProject --input $project
dsc resource test --resource AzureDevOpsDscNative/AzDoProject --input $project
dsc resource set  --resource AzureDevOpsDscNative/AzDoProject --input $project
```

Property names are the ones on each resource's page. Hashtable properties become JSON objects and
array properties become JSON arrays.

## Use a configuration document

A configuration document lists several resources. It needs the `$schema` line, and each resource
has a `name`, a `type` and its `properties`.

```yaml
# contoso.dsc.yaml
$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json
resources:
  - name: Contoso project
    type: AzureDevOpsDscNative/AzDoProject
    properties:
      ProjectName: Contoso
      ProjectDescription: Managed by DSC
      Visibility: Private

  - name: Contoso repository
    type: AzureDevOpsDscNative/AzDoGitRepository
    dependsOn:
      - "[resourceId('AzureDevOpsDscNative/AzDoProject', 'Contoso project')]"
    properties:
      ProjectName: Contoso
      RepositoryName: Contoso.Web
```

```powershell
dsc config test --file ./contoso.dsc.yaml
dsc config set  --file ./contoso.dsc.yaml
```

The module's own test suite drives each resource through `dsc resource get`, `test` and `set`.
Configuration documents use the same resources, but check a new document with `dsc config test`
before you apply it.

## Secrets in a document

Do not write a secret into a document. Give a secret reference instead, and the module reads the
secret on the machine that applies the configuration:

```yaml
  - name: Deployment variables
    type: AzureDevOpsDscNative/AzDoVariableGroup
    properties:
      ProjectName: Contoso
      VariableGroupName: Deployment
      Variables:
        Region: australiaeast
        API_KEY:
          SecretEnvironmentVariable: DEPLOYMENT_API_KEY
        DB_PWD:
          SecretName: DeploymentDbPassword
          SecretVault: Production
```

The environment variable has to be set for the `dsc` process, for `test` and `get` as well as
`set`. See
[Keeping secrets out of a configuration](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#keeping-secrets-out-of-a-configuration).

## Things to know

- **Every call is a new process.** The PowerShell adapter starts PowerShell for each
  `dsc resource` call. Each one imports the module, reads the stored credential, requests a token
  where the sign-in method needs one, and loads the cache files it uses. Expect each call to cost
  more than the same call through `Invoke-DscResource` in a warm session.
- **The cache is on disk.** Nothing is shared in memory between calls, so the cache folder is what
  carries state from one resource to the next. See [Caching](Caching).
- **Run as the account that signed in.** The stored credential cannot be read by another account.
- **At scale, use a runner.** [Dsc.PipelineRunner](LCMConfiguration) has a DSC v3 engine that
  drives `dsc` for a whole layered configuration.

## When it does not work

See [Troubleshooting](Troubleshooting#dsc-v3).
