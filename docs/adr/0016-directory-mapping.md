# ADR-0016 — Where the spec's directories live in this workspace
Status: Accepted
Date: 2026-09-24

## Context
The spec names `lib/core/` (tokens, theme, errors, logging), `lib/ui/components/`
and `tool/mock_server`. The repository is a pub workspace with enforced package
layering (CLAUDE.md, arch_guard).

## Decision
| Spec path | Location here | Reason |
| --- | --- | --- |
| `lib/core/` tokens + theme | `packages/ui_kit/lib/src/tokens/`, `theme.dart` | ADR-0004; one theme system. |
| `lib/core/` error model | `infra_core` `Failure` / `ApiError` + songlet_kit `SongletErrorCode` (exhaustive enum of PRD §6.5) | ADR-0002. |
| `lib/core/` logging | `infra_core` observability (`TelemetrySink`, redacting, no third-party SDK) | Already in place. |
| `lib/core/` routing | `lib/ui/routing/` | ADR-0003; routing is app-level. |
| `lib/ui/components/` | `packages/ui_kit/lib/src/components/` | Pure presentation, reusable, golden-tested in the package. |
| `tool/mock_server` | `mock_server/` (Dart package, excluded from the Flutter test run) | Existing, wired into `make mock` / `make acceptance`. |

## Consequences
Each spec concept maps to exactly one place.
