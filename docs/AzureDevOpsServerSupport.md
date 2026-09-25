# Azure DevOps Server support — plan

Tracks [#91](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/91): whether and how
this module supports on-premise Azure DevOps Server (TFS's successor) in addition to the
cloud service, Azure DevOps Services.

## Status

**Pending a repository-owner decision.** The README currently states support for "Azure
DevOps and Azure DevOps Server," and `CONTRIBUTING.md` keeps a `Server` resource category.
Whether the module is actually built out to run against a Server collection, or whether
that claim should instead be narrowed, is a decision for the repository owner — not
something this plan makes on their behalf. Everything below is written to be useful either
way: each increment is either infrastructure any caller benefits from (increment 1), or
work that is cheap to abandon if the answer turns out to be "narrow the README instead."

Today, every private API function reaches Azure DevOps Services by building a request URL
against one of a handful of hardcoded `dev.azure.com` subdomains. None of that reaches a
Server collection, which addresses every service through the same collection URL
(`https://<server>/<collection>`) rather than per-service subdomains.

## Increments

1. **This PR — `Get-AzDoApiUri` (foundation).** A single private helper that resolves the
   base URL for a named service (`Core`, `Identity`, `Entitlements`, `Feeds`, `Audit`,
   `Release`), given either a cloud organization name or an on-premise `-ServerUrl`. Not
   wired into any call site yet, and no auth path changes. Useful on its own: it is one
   place, instead of dozens of literals, to reason about service URLs, and it establishes
   the Server-vs-cloud shape (`Entitlements` and `Audit` have no Server equivalent and
   `Get-AzDoApiUri` already refuses them) before any call site depends on it.

2. **Persist `-ServerUrl`.** Add a collection-URL setting alongside the existing
   organization name, threaded through `New-AzDoAuthenticationProvider`, `Construct()` and
   `ModuleSettings.clixml`. Needs its own review because it touches the shared auth path
   every resource depends on, and because Azure DevOps Server only supports Personal
   Access Token authentication — Managed Identity, Service Principal, Azure CLI and
   Workload Identity Federation tokens are all cloud-only (they authenticate against
   Microsoft Entra ID, which an on-premise collection does not use) and must be rejected
   with a clear error when `-ServerUrl` is set with anything other than
   `PersonalAccessToken`.

3. **Mechanical per-subsystem replacement.** Replace the roughly 344 inlined
   `dev.azure.com` (and `vssps.`/`vsaex.`/`feeds.`/`auditservice.`/`vsrm.dev.azure.com`)
   literals across the private API layer with calls to `Get-AzDoApiUri`, one subsystem's
   worth of call sites per pull request so each is reviewable and bisectable. This PR
   deliberately leaves every existing literal in place — several other pull requests are
   adding new literals concurrently, and touching them all here would conflict with every
   one of those.

4. **API version negotiation.** Azure DevOps Server pins specific `api-version` values per
   release and does not support every version the cloud service does. Query
   `_apis/connectionData` (or the per-collection API version list) once per session and
   pick the highest mutually supported version per endpoint, instead of hardcoding the
   cloud's latest.

5. **Feature gating.** Some services have no Server equivalent at all (increment 1 already
   encodes this for `Entitlements` and `Audit`); others exist on Server but with a reduced
   feature set (for example, some Marketplace-backed extension behavior). Each such gap
   needs a resource-level decision: refuse cleanly with a clear error, or degrade
   gracefully. Enumerate the gaps against the current 65-resource surface before deciding
   case by case.

6. **Literal-count unit gate.** Once increment 3 finishes replacing the inlined literals,
   add a unit test that fails if a new `dev.azure.com`-family literal is introduced outside
   `Get-AzDoApiUri` — the mechanical replacement is only durable if new call sites cannot
   silently regress it. Not added before then: with increment 3 unstarted and other pull
   requests still adding literals, a count gate today would fail on `main` as those merge.

7. **A documented run against a real Server instance.** Everything above is developed and
   unit-tested against the Services API shape. Before any support claim is strengthened,
   run the integration suite (or a meaningful subset) against an actual Azure DevOps
   Server collection and document the result — including anything that needed a Server-
   specific fix that the increments above did not anticipate.

## What this PR does and does not do

- Adds `Get-AzDoApiUri` (source and unit tests) and an integration test that exercises it
  against the live cloud organization used by CI, for every `Services` value.
- Does **not** touch `New-AzDoAuthenticationProvider`, `Construct()`, or
  `ModuleSettings.clixml` (increment 2).
- Does **not** replace any existing inlined URL literal, and does **not** add a
  literal-count gate (increment 3 and 6).
- Does **not** change the README's support claim or remove `CONTRIBUTING.md`'s `Server`
  category — that call belongs to the repository owner.
