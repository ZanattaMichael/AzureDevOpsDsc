# Caching

The module keeps a local copy of the parts of the organization it looks up most: projects, groups,
users, repositories and so on. Resources resolve names to ids and identities from that copy
instead of asking Azure DevOps each time. This page explains what is cached, when it changes, and
how to reset it.

## Where it lives

Everything is under the folder named by the `AZDODSC_CACHE_DIRECTORY` environment variable:

| Path | Contents |
|---|---|
| `ModuleSettings.clixml` | The organization name and the stored credential. See [Authentication](Authentication#what-is-stored-and-where). |
| `Cache/<Name>.clixml` | One file per cache, for example `LiveProjects.clixml`, `LiveGroups.clixml`, `LiveUsers.clixml`. |

The variable must be set, to the same folder, for the sign-in and for every process that runs a
resource.

## What is cached

- **Organization-wide lookups built at sign-in:** projects, groups, users, group members,
  repositories, security namespaces, service principals, identity descriptors, process templates,
  and area and iteration nodes.
- **Objects resources manage:** as a resource creates or changes something (a pipeline, a variable
  group, a team, a service connection), it records the result in the matching cache.

The cache holds no secrets. Secret variable values, service connection keys and audit stream keys
are blanked before a value is cached.

## When it is built and updated

- **Sign-in rebuilds it.** `New-AzDoAuthenticationProvider` deletes the existing cache files and
  reads the organization again. On a large organization this is the slowest step.
- **Resources load it on demand.** A resource reads only the cache files it needs, the first time
  it needs them in a process.
- **Resources keep it current.** When a resource creates, changes or removes an object, it updates
  the cache and writes the file, so the next resource sees the change.
- **Nothing expires.** There is no time limit on a cache entry. Changes made outside the module
  (in the web portal, or by another machine) are not picked up until the cache is rebuilt.

## Resetting the cache

Sign in again. This is the supported way to rebuild the cache:

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -useManagedIdentity
```

Do this when:

- a resource cannot find a project, group or user that exists in the portal;
- objects were created, renamed or deleted outside the module since the last sign-in;
- the cache folder was copied from another machine or account;
- you upgraded the module and want a clean start.

For a scheduled run, signing in at the start of each run keeps the cache in step with the
organization, at the cost of the rebuild time.

## Sharing and moving the cache

Do not share one cache folder between machines or accounts.

- On Windows each cache file is DPAPI-encrypted for the account that wrote it. Another account,
  or the same account on another machine, cannot read it, and `Import-Clixml` cannot open it.
- On Linux and macOS the files are plain CLIXML protected by owner-only permissions. Resources
  refuse to read the folder unless it is owned by the current account (or root) with no group or
  other access.

The cache maps names to identities. Anyone who can write to it can redirect a permission grant to
a different identity, so keep the folder private even though it holds no secrets.

## Performance

- Under DSC v2 (`Invoke-DscResource`) a session keeps the caches it has loaded in memory.
- Under [DSC v3](DscV3) every `dsc resource` call is a new process, so each call reads the cache
  files it needs from disk again.
- The permission resources that work on area paths, iterations and pipelines scan
  organization-level access control lists and are the slowest resources to run.

## Related settings

| Variable | Effect |
|---|---|
| `AZDODSC_CACHE_DIRECTORY` | The cache folder. Required. |
| `AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY` | Set to `1` to turn the Linux and macOS privacy check into a warning, for a mounted volume whose permissions cannot be changed. |

Contributors: how resources read and write the cache in code is covered in
[CONTRIBUTING.md](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CONTRIBUTING.md#using-the-caching-mechanism).
