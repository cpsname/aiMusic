# ADR-0003 — go_router with hand-written typed routes and deep links
Status: Accepted
Date: 2026-09-24

## Context
The app has no router: pages are pushed with `Navigator.push`, so nothing is
deep-linkable and pages cannot be opened directly in tests. The spec asks for
go_router with typed routes. `go_router_builder` is codegen (ADR-0002).

## Decision
- Add `go_router`. Routes are declared once in `lib/ui/routing/`.
- Typed routes are hand-written value classes (`WorkRoute(workId).location`,
  `CreateRoute(panel: ...)`) with a `parse` side, so every location is built and
  read through one type; no string paths in pages.
- Shell tabs (`/create`, `/library`, `/settings`) use `StatefulShellRoute` so each
  tab keeps its stack.
- Deep links: `songlet://app/<location>` and the same paths via universal links.
  Unknown or malformed links fall back to `/create`.
- `StartupGate` and `MaintenanceGate` stay above the router, so a deep link can
  never bypass force-update or maintenance.
- Modal surfaces (paywall, region sheet, panels) are routes too, so tests and
  links can open them directly.

## Consequences
Existing `Navigator.push` call sites move to `context.go/push(Route(...).location)`.
Adding a page means adding one route class and one entry in the route table
(README checklist).

## Amendment (2026-09-24) — findings from the simulator acceptance run
- **Parameterised pages are keyed by location.** go_router keys a page by its
  route *pattern* (`/library/works/:id/preview`), so going from one work to
  another reused the first page's `State` (the new song never autoplayed; a
  loaded license would have stayed). Every page built from path parameters is
  wrapped in `KeyedSubtree(key: ValueKey(state.matchedLocation))` (`_keyed` in
  `app_router.dart`). Covered by `player_test` "moving to another work…".
- **Starting a song uses `go`, not `push`.** A pushed page does not change the
  branch's recorded URI, so the Create tab's `StatefulShellRoute` restore brought
  back a stale, empty progress page after the song had opened in Library.
  `CreateFlow.submit` now `go`es to `/create/generate`, and that route redirects
  to `/create` when nothing is in flight (go_router applies redirects to restores
  too). Back from the progress page therefore goes to the create home, not the
  form; the draft is kept, so reopening the template restores it. Covered by
  `template_form_test` "once the song opens…" and `generating_test`.
