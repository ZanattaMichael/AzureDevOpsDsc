# Troubleshooting

Find the error message you are seeing, or the nearest symptom. Messages are quoted as the module
writes them, with `...` where a path or name appears.

Start with verbose output. It names the function that failed and the request it was making:

```powershell
Invoke-DscResource -Name AzDoProject -ModuleName AzureDevOpsDscNative -Method Get `
    -Property @{ ProjectName = 'Contoso' } -Verbose
```

To capture it to a file, set `AZDO_VERBOSELOGGING_FILEPATH` (and `AZDO_WARNINGLOGGING_FILEPATH`,
`AZDO_ERRORLOGGING_FILEPATH`) to a file path. Verbose file logging slows the module down, so
unset it afterwards. Secrets are redacted from these files, but treat them as sensitive: they name
projects, identities and URLs.

## Sign-in and credentials

### `A parameter cannot be found that matches parameter name 'PersonalAccessToken'`

The plain-text `-PersonalAccessToken`, `-PAT` and `-ClientSecret` parameters were removed in 2.0.
Pass `-SecureStringPersonalAccessToken` or `-SecureStringClientSecret`. See
[Upgrading to 2.0](Upgrading-to-2.0#1-replace-the-removed-plain-text-parameters). If the call is
made by a tool such as Dsc.PipelineRunner, that tool needs updating.

### `The Environment Variable 'AZDODSC_CACHE_DIRECTORY' is not set`

Set it before signing in and for every process that runs a resource. A variable set in one
PowerShell session is not visible to a service, a scheduled task or a pipeline job unless it is
set there too.

```powershell
$env:AZDODSC_CACHE_DIRECTORY = Join-Path $HOME '.azuredevopsdsc'
```

### `'...' is not a valid Azure DevOps organization name`

Pass the name only. For `https://dev.azure.com/contoso` that is `contoso`.

### `Could not restrict the permissions on '...', so nothing has been written to it`

Sign-in refuses to store the credential in a folder it cannot make private. Point
`AZDODSC_CACHE_DIRECTORY` at a folder the current account owns, on a local file system that
supports permissions. Network shares and some mounted volumes do not.

### `The cache directory '...' is not private`

Linux and macOS only. Resources refuse to read the stored credential from a folder that another
account could write to. The message says which check failed:

- **`its permissions are '...'`**: run `chmod 700` on the folder as its owner.
- **`it is owned by '...'`**: the account running DSC is not the one that signed in. Sign in
  again as the account that runs DSC.

For a mounted volume whose permissions cannot be changed, `AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY=1`
turns the failure into a warning.

### `The ModuleSettings.clixml file does not exist in the Cache Directory`

Nobody has signed in with this cache folder, or the process is looking at a different folder.
Check the value of `AZDODSC_CACHE_DIRECTORY` in the failing process, then run
`New-AzDoAuthenticationProvider`.

### `The Token information does not exist in the Cache Directory`

The stored settings hold no usable credential. The usual cause on Windows is running DSC as a
different account from the one that signed in: the stored credential is encrypted for the account
that wrote it. Sign in again as the account that runs DSC.

### Sign-in succeeds but resources get `401` or `403`

- A personal access token is not checked at sign-in. Confirm it has not expired or been revoked.
- For a service principal or managed identity, confirm it has been added to the organization and
  the organization is connected to the identity's Microsoft Entra tenant.
- `403` means the identity signed in but may not do what the resource asked. See
  [Give the identity access](Authentication#give-the-identity-access-in-azure-devops).

### The token has expired

- **Personal access token:** create a new token and sign in again with it.
- **Client secret or certificate:** renew it in Microsoft Entra ID and sign in again.
- **Azure CLI:** run `az login` again.
- **A manually supplied federated token:** sign in again with a fresh token.
- Managed identity and file or GitHub Actions federation request a new token on each run and need
  no action.

## Secret references

A secret reference that cannot be resolved fails the resource. It never stores an empty secret.
The secret is needed for `Get` and `Test` as well as `Set`.

| Message | Fix |
|---|---|
| `The environment variable '...' named by a secret reference is not set for the process running DSC` | Set the variable for the process that runs DSC, not only for your own session. |
| `The secret reference '...' needs the Microsoft.PowerShell.SecretManagement module, which is not installed` | Install the module for the account that runs DSC. |
| `The secret '...' could not be read from the secret vault` | Check the secret and vault names, and that the vault is registered and unlocked for the account that runs DSC. |
| `The secret '...' is empty or is not a text secret` | Store the value as a string or `SecureString`. |
| `A secret reference names either SecretEnvironmentVariable, or SecretName ..., not both` | Use one form per reference. |

## Requests

### `Refusing to send the Azure DevOps credential to '...'`

The module only sends its credential to Azure DevOps Services hosts. A URL taken from
configuration or from an API response pointed somewhere else. If the host is one you operate,
name it in `AZDODSC_ALLOWED_API_HOSTS`. Every host named there receives the credential.

### `Refusing to send a request over '...'`

Only `https` is allowed.

### A request times out

Every request has a 300 second timeout. To allow longer on a slow link or a very large
organization, set `AZDODSC_REQUEST_TIMEOUT_SECONDS`.

### `The response did not end after 10000 pages`

A listing was abandoned because it would not end. If the organization really is that large, raise
the limit with `AZDODSC_MAX_RESPONSE_PAGES`.

### `The response repeated the continuation token of the previous page`

The service returned a page that pointed at itself. Run again. If it persists, report it with the
verbose output.

### Slow runs and throttling (`429`)

The module reads the rate-limit headers Azure DevOps returns and waits when it is told to, so a
throttled run slows down instead of failing. If runs are slow:

- sign in once per run, not once per resource: sign-in rebuilds the whole cache;
- expect the area, iteration and pipeline permission resources to take longest;
- turn off verbose file logging;
- under DSC v3, expect each `dsc resource` call to start a new PowerShell process.

## Resources

### A project, group or user "does not exist" but is in the portal

The cache does not pick up changes made outside the module. Sign in again to rebuild it. See
[Caching](Caching#resetting-the-cache).

### A resource reports drift on every run

Compare what the configuration states with what `Get` returns:

```powershell
Invoke-DscResource -Name <Resource> -ModuleName AzureDevOpsDscNative -Method Get -Property $properties -Verbose
```

Check the resource's page for properties that cannot be changed after creation and for values
Azure DevOps rewrites. If the two match and `Test` still returns false, report it as a bug.

### A property set in the portal is being cleared

Resources only compare properties the configuration states. Remove a property from the
configuration to stop managing it.

### A resource cannot be found by DSC

```powershell
Get-Module -ListAvailable -Name AzureDevOpsDscNative
Get-DscResource -Module AzureDevOpsDscNative
```

The module needs PowerShell 7. If more than one version is installed, the newest is used.

## DSC v3

### `dsc resource list` shows no `AzureDevOpsDscNative` resources

- Name the adapter: `dsc resource list --adapter Microsoft.Adapter/PowerShell 'AzureDevOpsDscNative/*'`.
  Before DSC 3.2.0 the adapter is `Microsoft.DSC/PowerShell`.
- Confirm the `dsc` install includes the PowerShell adapter, not only the executable.
- Confirm the module is on `PSModulePath` for the account running `dsc`.

### A resource works in PowerShell but fails under `dsc`

`dsc` starts its own PowerShell process. Check that `AZDODSC_CACHE_DIRECTORY`, and any environment
variable a secret reference names, are set in the environment `dsc` runs in, and that `dsc` runs
as the account that signed in.

## Reporting a problem

Open an [issue](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues) with the module version,
the PowerShell version, the operating system, the sign-in method, the resource and its properties
(without secrets), and the verbose output.

Report a suspected security problem privately, as the
[security policy](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/SECURITY.md#reporting-a-vulnerability)
describes, not in a public issue.
