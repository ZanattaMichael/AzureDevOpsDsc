# Spike: Tenant-Scoped Policies (#85)

Spike for the five candidates listed in `docs/ResourceRoadmap.md` §7/§9 as "tenant-scoped
items": `AzDoPatPolicy`, `AzDoOrganizationCreationPolicy`, `AzDoBillingSettings`,
`AzDoExtensionPolicy`, `AzDoAuditLogAlert`. Filed per #59, tracked as #85.

**Build rule applied to every candidate:** build a resource only if *all* of the following
hold —

1. a documented, non-preview REST route exists for read (and, for a real resource, write);
2. the CI identity — a Project Collection Administrator-level PAT or service principal in a
   single organization, **not** a Microsoft Entra tenant admin — can at least read it;
3. the write is not a purchase, a billing change, or a tenant-wide change.

All five candidates are recorded below. **None pass.** This is a docs-only spike.

---

## 1. `AzDoPatPolicy`

**What it would manage:** the Microsoft Entra tenant-level PAT policies (maximum PAT
lifespan, restrict full-scoped PAT creation, restrict global PAT creation, automatic
revocation of leaked PATs) plus the newer org-level "restrict PAT creation" allow-list.

**API route:** portal only. `manage-pats-with-policies-for-administrators` documents five
policies but gives no REST endpoint for reading or setting any of them — they are toggles
under *Organization settings → Microsoft Entra ID* (tenant-level) or *Organization
settings → Policies* (org-level allow-list). The only PAT-related REST surface that exists
is the **Token Administration API** (`_apis/tokenadmin/personalaccesstokens/{subjectDescriptor}`,
GA, documented), which lists and revokes an individual user's *existing tokens* — it has no
operation to read or change the *policy settings themselves*.

**Documented vs undocumented:** the policy settings — undocumented (no REST route found).
The unrelated token-listing/revocation API — documented, GA.

**Stability:** N/A for the policy settings (portal-only). The "restrict PAT creation"
allow-list is explicitly called out as **preview** in the devblogs announcement.

**Required role:**
- Tenant-level policies (max lifespan, restrict full-scoped, restrict global PAT, leaked-PAT
  revocation): **Azure DevOps Administrator** (a Microsoft Entra role), not Project
  Collection Administrator.
- Org-level "restrict PAT creation" allow-list: **Project Collection Administrator** — this
  one is org-scoped, not tenant-scoped.
- The Token Administration API additionally requires a **Microsoft Entra token**; the docs
  state explicitly that service principals or managed identities cannot be used to create or
  revoke PATs through it.

**Token class fit:** `PersonalAccessToken` (002) cannot hold the Azure DevOps Administrator
role at all — a PAT authenticates as the user who issued it, and even then the tenant policy
UI is Entra-role gated, not PAT-scope gated. `ManagedIdentityToken` (003) and
`ServicePrincipalToken` (003b) carry Entra bearer tokens but the docs say they are explicitly
excluded from the Token Administration API and there is no evidence they can hold "Azure
DevOps Administrator" through an app-only (non-interactive) grant path suitable for a build
agent. None of this module's five token classes (002, 003, 003b–003e) are a good fit for the
tenant-level half.

**Verdict: unsupported** — no documented route for the policy settings; the tenant-level
half additionally needs an Entra tenant admin identity, which this module does not model and
which CI cannot hold safely.

**Follow-up:** the org-level "restrict PAT creation" allow-list is an **org-scoped**
`OrganizationPolicy`-shaped setting, not a tenant policy. Per the boundary set for this
issue, it is **not** built here — record it as a candidate property for
`AzDoOrganizationSettings` (081) once #84 lands, since that resource already owns
org-level policy toggles (`AllowPublicProjects`, `EnableOAuthAuthentication`, etc.).

**Sources:**
- https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/manage-pats-with-policies-for-administrators?view=azure-devops
- https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/manage-personal-access-tokens-via-api?view=azure-devops
- https://learn.microsoft.com/en-us/rest/api/azure/devops/tokenadmin/?view=azure-devops-rest-7.1
- https://devblogs.microsoft.com/devops/restricting-pat-creation-in-azure-devops-is-now-in-preview/
- https://devblogs.microsoft.com/devops/retirement-of-global-personal-access-tokens-in-azure-devops/

---

## 2. `AzDoOrganizationCreationPolicy`

**What it would manage:** the Microsoft Entra tenant policy that restricts which users/
groups may create new Azure DevOps organizations under the tenant, with an allow-list.

**API route:** portal only / undocumented. The dedicated Microsoft Learn page
(`azure-ad-tenant-policy-restrict-org-creation`) describes only the *Organization settings →
Microsoft Entra ID* toggle and allow-list UI. No REST endpoint is documented anywhere for
reading or setting this policy.

**Documented vs undocumented:** undocumented (no REST route).

**Stability:** GA feature, but only as a portal control; there is nothing to version as
preview/GA at the API level because there is no API.

**Required role:** **Azure DevOps Administrator** (Microsoft Entra role) to change the
policy; the page states "all other users, except for Azure DevOps administrators, are
blocked unless explicitly added to the allow list" once the policy is on, meaning even a
plain org member normally has no ability to read this setting through any org-scoped
identity.

**Token class fit:** none of the five token classes can plausibly hold this — this is a
tenant-wide Entra role, one level above anything a single-org PAT or service principal
credential can represent in this module's auth model.

**Verdict: unsupported** — no documented route, and the CI identity (single-org
PCA-level PAT/SP) cannot hold the required role by construction.

**Sources:**
- https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/azure-ad-tenant-policy-restrict-org-creation?view=azure-devops

---

## 3. `AzDoBillingSettings`

**What it would manage:** the Azure subscription linked for billing, paid Basic / Basic +
Test Plans seat counts, and purchased parallel-job quantities.

**API route:** portal only for every write. Setting up billing (linking a subscription)
and changing paid parallel-job or paid-seat quantities are both described only as
*Organization settings → Billing* portal flows (`set-up-billing-for-your-organization-vs`,
`concurrent-jobs`). There is a `Microsoft.VisualStudio/account` Azure resource provider
backing the linked-subscription relationship, but no documented Azure DevOps REST API (as
opposed to the Azure Resource Manager control plane, which is a different surface this
module does not integrate with) for reading or writing it was found.

**Documented vs undocumented:** undocumented at the Azure DevOps REST layer for both read
and write.

**Stability:** N/A (portal-only / ARM-only).

**Required role:** billing changes require **Project Collection Administrator** plus
**Owner/Contributor Azure RBAC on the linked billing subscription** — a cross-product
permission this module has never needed before.

**Token class fit:** irrelevant — this candidate fails the build rule on its own terms
regardless of role, because every write here is explicitly a **billing change or a
purchase** (linking a subscription, buying seats, buying parallel jobs), which the build
rule excludes outright. No amount of route availability would make this buildable under
these constraints.

**Verdict: unsupported** — excluded by the "no purchase/billing write" rule, independent of
API documentation status.

**Sources:**
- https://learn.microsoft.com/en-us/azure/devops/organizations/billing/set-up-billing-for-your-organization-vs?view=azure-devops
- https://learn.microsoft.com/en-us/azure/devops/pipelines/licensing/concurrent-jobs?view=azure-devops
- https://learn.microsoft.com/en-us/azure/devops/organizations/billing/billing-faq?view=azure-devops

---

## 4. `AzDoExtensionPolicy`

**What it would manage:** who may request, install, and approve marketplace extensions for
the organization (the *Organization settings → Extensions → Policies* toggles), distinct
from the already-shipped `AzDoExtension` resource, which installs/uninstalls a named
extension via the documented Extension Management API.

**API route:** the Extension Management REST API
(`_apis/extensionmanagement/installedextensions`, GA, documented) covers list/get/install/
uninstall of individual extensions — that surface is already used by the shipped
`AzDoExtension` resource. The organization-level **policy** toggles that govern who can
*request*, *install*, and *approve* extensions have no documented REST route; the only
documented workflow (`request-extensions`, `grant-permissions`) describes the portal request/
approval flow and the built-in security groups (Project Collection Administrators) that
gate it, not an API to read or set the policy.

**Documented vs undocumented:** the extension install/uninstall surface — documented, GA
(already covered by `AzDoExtension`). The extension **policy** settings themselves —
undocumented (no REST route found).

**Stability:** N/A for the policy toggles.

**Required role:** **Project Collection Administrator** with "Edit collection-level
information" to approve extension requests or change the policy — this one is genuinely
org-scoped, not tenant-scoped, unlike the issue's framing suggests. That removes the Entra
tenant-admin obstacle that blocks candidates 1–2, but the missing REST route still blocks
it.

**Token class fit:** a PCA-level `PersonalAccessToken` or `ServicePrincipalToken` could hold
the required role — this is the one candidate where the *identity* constraint would not be
the blocker.

**Verdict: unsupported (for now)** — fails on documented-route alone. If Microsoft
documents a REST route for the extension policy toggles in future, this is the strongest
re-spike candidate of the five, since the role constraint already passes.

**Sources:**
- https://learn.microsoft.com/en-us/rest/api/azure/devops/extensionmanagement/installed-extensions?view=azure-devops-rest-7.1
- https://learn.microsoft.com/en-us/azure/devops/marketplace/request-extensions?view=azure-devops
- https://learn.microsoft.com/en-us/azure/devops/marketplace/grant-permissions?view=azure-devops
- https://learn.microsoft.com/en-us/azure/devops/extend/overview?view=azure-devops

---

## 5. `AzDoAuditLogAlert`

**What it would manage:** alerting on specific audit events.

**Finding:** this is **not a distinct feature**. Azure DevOps has an Audit Log REST API
(`_apis/audit/auditlog`, documented, GA — used for direct export/query, 90-day retention)
and an Audit Streaming feature (`introducing-azure-devops-audit-stream`, documented) that
continuously forwards audit events to an external target (e.g. Azure Monitor Logs, a SIEM).
Alerting is not a native Azure DevOps capability — it is something you configure on the
*destination* once audit events are streamed there (e.g. a Log Analytics alert rule on
ingested audit events). There is no separate "audit log alert" object or API inside Azure
DevOps itself.

**Documented vs undocumented:** N/A — no such distinct feature exists to document.

**Verdict: not built — folds into `AzDoAuditStream`** (already shipped per §1 of
`docs/ResourceRoadmap.md`, tracked under #69). Any alerting need is satisfied by configuring
an alert rule on the stream target outside Azure DevOps; that is out of this module's scope
(it would be an Azure Monitor / SIEM resource, not an Azure DevOps one).

**Sources:**
- https://learn.microsoft.com/en-us/rest/api/azure/devops/audit/audit-log?view=azure-devops-rest-7.1
- https://learn.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming?view=azure-devops
- https://devblogs.microsoft.com/devops/introducing-azure-devops-audit-stream/
- https://learn.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing?view=azure-devops

---

## Summary table

| Candidate | Route | Documented? | Stability | Required role | Token class fit | Verdict |
|---|---|---|---|---|---|---|
| `AzDoPatPolicy` | Portal only (policy settings); Token Admin API exists but only for individual token list/revoke, not policy | Undocumented (policy) / Documented, GA (unrelated token admin API) | N/A / preview (allow-list) | Azure DevOps Administrator (tenant policies); PCA (org allow-list) | None of 002/003/003b–003e hold the tenant role; Entra-token-only APIs exclude SP/MI | **Unsupported.** Org-level allow-list → follow-up for `AzDoOrganizationSettings` after #84 |
| `AzDoOrganizationCreationPolicy` | Portal only | Undocumented | N/A | Azure DevOps Administrator (Entra tenant role) | None | **Unsupported** |
| `AzDoBillingSettings` | Portal only / ARM only | Undocumented at ADO REST layer | N/A | PCA + Azure RBAC (Owner/Contributor) on billing subscription | N/A — excluded by build rule regardless | **Unsupported** (billing/purchase writes excluded outright) |
| `AzDoExtensionPolicy` | Portal only for policy toggles; install/uninstall API is documented (already used by `AzDoExtension`) | Undocumented (policy toggles) | N/A | Project Collection Administrator (org-scoped, not tenant) | PCA-level PAT/SP would qualify | **Unsupported for now** — re-spike if Microsoft documents a route; role constraint already passes |
| `AzDoAuditLogAlert` | N/A — not a distinct feature | N/A | N/A | N/A | N/A | **Not built** — folds into shipped `AzDoAuditStream` (#69) |

**Net result: zero resources built.** All five candidates fail the build rule, three of
them (`AzDoPatPolicy`'s tenant half, `AzDoOrganizationCreationPolicy`) because they require
a Microsoft Entra tenant-admin identity this module cannot model or safely grant to CI, one
(`AzDoBillingSettings`) because every write is inherently a billing/purchase change, and one
(`AzDoExtensionPolicy`) purely for lack of a documented route despite an otherwise-workable
role. `AzDoAuditLogAlert` is not a distinct feature and folds into `AzDoAuditStream`. Class
prefixes `130`–`131` reserved for this issue are left unused.
