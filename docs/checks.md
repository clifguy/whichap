# WhichAP checks

Adopted with the fork policy on 2026-10-13.

## Every candidate

Run `git diff --check`. Inspect all intended tracked/untracked files and preserve unrelated work. Check applicable existing hooks and any newly introduced CI requirements.

## Build and signing changes, Swift code, resources or entitlements

Use Xcode with macOS support. Build Debug with the same arguments as `scripts/local-build.sh`; that script also stops any existing WhichAP process, verifies the app signature and launches it. Verify the built identifier is `com.clifguy.whichap.debug` and signature is ad-hoc. Confirm app-sandbox, user-selected-file read access, outgoing network and location entitlements survive. The Debug debugger entitlement is expected.

For project-file changes run `plutil -lint WhichAP.xcodeproj/project.pbxproj`. For shell-script changes run `bash -n` on the changed scripts. Exercise meaningful success/failure behavior where affected. Do not treat a syntax check as build/runtime acceptance.

Check launch and the affected UI behavior. Confirm Location Services and Wi-Fi display when relevant; do not grant privacy permissions silently. Ad-hoc signing can prompt again after rebuilds. Inspect connection history/preferences only when needed for the requested behavior.

## Before every commit

Retain the upstream five-minute CPU/memory check on the running candidate:

```sh
top -l 30 -s 10 -pid <verified-WhichAP-PID> -stats pid,cpu,mem,threads,time
```

Pass: sustained CPU at or below 0.1%, stable RSS, no thread growth. Record actual observed result and candidate; a single sample is insufficient. Do not commit if this gate cannot be completed without an owner-approved exception.

For documentation-only changes, review accuracy and links, run whitespace validation, and retain the above pre-commit gate. Focused menu bar checks are available via `bash scripts/test-menu-bar.sh` (macOS with Xcode). They compile the production display model and icon renderer and check defaults, persistence, status precedence, fixed image size, template rendering, caching, and accessibility descriptions. They do not replace live UI checks. No CI workflow or full application test suite is configured.
