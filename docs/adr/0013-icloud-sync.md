# ADR-0013 — Opt-in iCloud library sync through the CloudKit private database
Status: Suspended (2026-10-04) — the app ships without the iCloud capability; the
native `CloudSyncService` and its registration are removed, the settings toggle and
the library's sync status are gone, and `songlet/cloud_sync` has no handler (the
Dart gateway reads `unavailable`). Restoring it = the iCloud capability + container
in the provisioning profile, the entitlements, and the service from git history.
Date: 2026-09-24

## Context
F10: the library is local, with iCloud sync off by default and optional. P12
shows a sync status in the header. There are no accounts, so the sync store
must belong to the user's Apple ID.

## Decision
- CloudKit **private** database, container `iCloud.com.songlet.ios`, record
  type `Work` (metadata fields + audio `CKAsset` + cover `CKAsset`).
- Native `songlet/cloud_sync` channel (`status`, `push(work)`, `delete(id)`,
  `pull(since)`), outside the fixed Pigeon interface (same reasoning as
  ADR-0006). The Dart side is a `CloudSyncGateway` port and a
  `LibrarySyncService` in songlet_kit's library feature.
- Off by default; the toggle lives in Settings. On enable: push every local
  work, then pull. Conflict rule: last `updatedAt` wins; deletes are
  tombstoned.
- No iCloud account, or restricted → toggle disabled with the reason; the
  library keeps working locally.

## Consequences
The data never reaches the Songlet backend (PRD §10 privacy). Simulator runs
without an iCloud account exercise the unavailable path; the service is
covered by tests against a fake gateway.
