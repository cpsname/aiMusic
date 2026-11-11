# ADR-0002 — Reuse the template's mechanisms instead of codegen / freezed / drift / Result
Status: Accepted
Date: 2026-09-24

## Context
The delivery spec locks the stack to Riverpod codegen, freezed, drift and a
`Result` type. The repository is an existing template with a working, tested
equivalent for each, plus a written contract (`CLAUDE.md`: "No code generation.
Providers are written by hand"), and the product owner instructed: "避免重复造轮子"
— analyse and reuse the existing architecture first
(`docs/analysis/existing-architecture.md`).

| Spec asks | Already in the repo | Why keep it |
| --- | --- | --- |
| `riverpod_generator` | Hand-written Riverpod 3 providers; arch_guard enforces layering on them | `custom_lint`/`riverpod_lint` cannot resolve against analyzer 12 on this toolchain (see CLAUDE.md "Why arch_guard"); `build_runner` would add a generate step to every gate for no behavioural gain. |
| freezed / json_serializable | `@immutable` domain models with `copyWith`, DTOs with `fromJson/toJson/toDomain` | Same guarantees (value semantics, explicit mapping at the data boundary) without a generated layer; 276 existing tests cover them. |
| drift | `SqliteWorkRepository` (sqflite) behind the `WorkRepository` domain port, schema via `onUpgrade` | The port is what makes the library testable; swapping the engine is a data-layer change that ADR can revisit without touching callers. |
| `Result<T, AppError>` | `ErrorHandler.handle → Failure` (sealed) + `AsyncValue` | A second error channel would split error handling in two; `Failure` already carries `errorCode` for PRD §6.5. |

## Decision
Keep the template mechanisms. New code follows them: hand-written providers in
`application/`, immutable models with `copyWith`, DTO mappers in `data/`, schema
migrations through `onUpgrade` / `StorageMigrator`, errors through `Failure`.

## Consequences
No generated sources to keep in sync. Each deviation is local to one layer, so a
later move to codegen or drift can happen package by package behind the same
ports.
