# Best Practices

Recommendations for running AzureDevOpsDscNative safely and predictably. Each links to the page
with the detail.

## Identity and credentials

- **Prefer an identity with no stored secret.** Managed identity on Azure machines and workload
  identity federation in CI leave nothing to rotate or leak. Use a personal access token for
  local work only. See [Authentication](Authentication).
- **Use a dedicated identity.** A token belonging to a person stops working when they leave and
  makes the audit log read as if they made every change.
- **Grant what the configuration needs.** An identity in Project Collection Administrators can
  change anything. If a configuration only manages a few projects, make the identity a Project
  Administrator there.
- **Treat the cache folder as credential storage.** Keep `AZDODSC_CACHE_DIRECTORY` on a private,
  local path, and run DSC as the account that signed in. See [Caching](Caching).

## Secrets

- **Never write a secret into a configuration.** A configuration is a file that is committed,
  copied and compiled. Use a secret reference so the secret is read on the machine applying it.
  See
  [Keeping secrets out of a configuration](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#keeping-secrets-out-of-a-configuration).
- **Make referenced secrets available to every run.** `Get` and `Test` need the secret as well as
  `Set`.
- **Treat logs as sensitive.** Secrets are redacted, but logs still name projects, identities and
  URLs. Turn verbose file logging off when you are not troubleshooting.
- **Review exported configuration before committing it.** Export replaces secret properties with a
  placeholder that has to be filled in by hand, preferably with a secret reference.

## Writing configurations

- **State only what you want managed.** Resources compare the properties a configuration states
  and leave the rest alone. Listing a property you do not care about means DSC will reset it.
- **Order dependent resources.** A repository needs its project, and a permission needs its group.
  Use `dependsOn` so they run in order.
- **Know what cannot be changed.** Some properties are fixed at creation, such as a project's
  source control type. Each resource page says which.
- **Be deliberate with `Ensure = 'Absent'`.** Removing a project or repository is not reversible
  from DSC. Some resources need an extra property before they delete anything with contents.
- **Keep configurations in source control** and change them through review, like any other code.
- **Start from what exists.** For an organization that is already in use, generate a starting
  configuration with
  [export](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#onboarding-an-existing-organization-with-export)
  instead of writing it by hand.

## Permissions

- **Manage permissions through groups,** not individual users. Put users in groups with
  `AzDoGroupMember` and grant to the group.
- **Remember that Deny wins** over Allow, including an Allow inherited from a parent.
- **Read [Permissions & ACLs](Permissions)** before using the permission resources. It covers the
  identity syntax and the permission names for each resource.

## Running

- **Test before you set.** Run `Test` (or the runner's `Test` mode) first and read what would
  change.
- **Try changes against a test organization** before production, especially permission changes
  and anything with `Ensure = 'Absent'`.
- **Sign in once per run.** Sign-in rebuilds the cache, which keeps it in step with changes made
  in the portal. Do not sign in before every resource.
- **Run one configuration at a time per cache folder.** Two runs sharing a folder write the same
  cache files.
- **Expect permission resources to be slowest.** Area, iteration and pipeline permissions scan
  organization-level access control lists.
- **Pin the module version** in automation and upgrade deliberately. Read the
  [change log](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CHANGELOG.md) first.
  Major versions can contain breaking changes: see [Upgrading to 2.0](Upgrading-to-2.0).

## Choosing how to run

| Situation | Use |
|---|---|
| One-off or exploratory changes | `Invoke-DscResource` |
| A handful of resources, any platform | A [DSC v3](DscV3) configuration document |
| Many projects sharing policy | [Dsc.PipelineRunner](LCMConfiguration) |

## Checklist

- [ ] The identity is dedicated to automation and has only the access it needs.
- [ ] No long-lived secret is stored where a managed identity or federation would do.
- [ ] The cache folder is private, local, and owned by the account that runs DSC.
- [ ] No secret is written into a configuration.
- [ ] Configurations are in source control and reviewed.
- [ ] Changes are tested before they are applied.
- [ ] The module version is pinned.
