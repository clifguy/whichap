# WhichAP fork development policy

Adopted by Clif Guy on 2026-10-13.

## Ownership and scope

Clif owns this fork’s policy. Development targets `clifguy/whichap`; `jpowl7/whichap` is the upstream source. Confirm live remote identity and default branch before publication. Local guide files are the policy authority. Preserve pre-existing local work; include it in a commit only when the user authorizes that scope.

## Workflow

Use the installed personal SDLC skills with their bundled base policy and review procedure; no project-specific review replacement is proposed. Resolve the actual operation with project-policy before dependent work. Use feature branches for new work. Approved implementation permits routine in-scope edits and checks; use kickoff’s concrete plan approval when required. Small, explicit, reversible edits may proceed directly. Commit, push/draft PR, review-comment publication, merge, distribution and ticket closure require their corresponding authorization. A development request does not authorize all those steps.

Use the standing skill model/effort policy, including its current-release selection and host verification. Do not claim an already-running session changed settings through prose. Independent review follows converge-review when invoked or included in an approved plan; ordinary commit uses its selected pre-commit review. Preserve the base three-round convergence allowance and escalation rules.

## SAGE ticket binding

Clif selected the hosted deployment `https://sage.cor.org`, vault `software_development`. The stable project ID is `whichap`, project name `WhichAP`, repository `https://github.com/clifguy/whichap`, owner `clif.guy@resurrection.church`. Clif authorized registration with this policy on 2026-10-13; verify the live registry record before ticket-dependent workflows. The vault inventory and schema were verified live on 2026-10-13. The installed hosted MCP connector and its transfer endpoint are configured at `https://sage.resurrection.church`; use that verified origin for tool/byte access. The registered project document is `ed17c894_whichap`; resolve its current lineage before use. Registration does not change the vault schema.

Use the verified personal SAGE skill and the installed ticket-management workflow. Before each operation, verify the selected deployment's served contract and current project record. Set both document-level `project` and typed `project_id` to `whichap`. Keep project policy in this repository; the SAGE project record supplies registry identity, not a competing policy copy.

Work-tracking default: tickets for substantive features, fixes, investigations and workflow changes. Small explicit documentation or local-setup tasks may proceed without a ticket unless Clif requests one; validation and review still apply. Default priority is `medium` and horizon `current`, unless Clif states otherwise.

Ticket types, lifecycle vocabulary and metadata come from the live vault schema. Allocate `T-NNNN` identifiers across the entire vault, all projects and lifecycle states, using the served uniqueness contract and complete enumeration; never use a project-local counter. New ticket source names follow the selected ticket skill’s convention. Preserve submitter, represented-user and original timestamp metadata. Resolve every existing matching lineage before writes. Do not infer completion from merge, or close a ticket without authorization and verified acceptance evidence.

For scheduling, inspect the actual dependency ticket’s acceptance and completion. The current vault does not mark active tickets dependency-unsatisfying, so a generic preconditions success alone cannot establish that prerequisite work is finished. Do not change the vault’s lifecycle schema to implement project scheduling.

## Explicit fork differences from inherited CLAUDE.md

- Locally signed Debug builds use `com.clifguy.whichap.debug`, no team, and ad-hoc signing as already authorized by Clif. Xcode disables hardened runtime for this signing mode. The inherited Developer ID, team, designated requirement, hardened runtime and timestamp requirements continue to apply to distribution builds, rather than local Debug builds.
- Jason’s machine paths, signing credentials, Ruckus/Jamf targets and deployment steps describe upstream operations. They are not Clif’s development environment or authorization to use that infrastructure. `docs/release-checklist.md` applies only to an explicitly authorized upstream/Granger release, not routine fork development or a local Debug launch. A fork distribution procedure must be established before releasing this fork.
- Save project continuity in repository-local notes when needed. Updating personal memory requires Clif’s explicit request; the inherited automatic-memory instruction does not grant that permission.
- Use parallel tool calls where independent; delegate to agents only where the user or applicable workflow specifically authorizes it.

Preserve inherited privacy rules, entitlements, active-time logging, Help updates for user-visible changes, stop-before-rebuild discipline, and the five-minute CPU/memory pre-commit gate. This policy does not waive that gate for documentation-only commits.

## Validation and delivery

Run the applicable procedures in `docs/checks.md`. Preserve actual Git hooks. Report no configured CI/test suite as a limitation, never as passing tests. Stop on failed required checks. Never expose real Granger BSSIDs in public artifacts.

Default publication destination is the verified fork’s origin; upstream pushes/PRs need explicit scope. An authorized push may create the skill’s configured draft PR. Merge remains separately authorized. Local build-and-run is a development check; public release, notarization, pkg installation, Jamf and hosted changes require a separately approved target and procedure.
