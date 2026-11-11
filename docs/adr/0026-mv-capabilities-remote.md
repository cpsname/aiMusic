# ADR-0026 — Video qualities come from the remote config
Status: Accepted
Date: 2026-09-29

## Context
Task item 2: the quality choices come from the backend. Contract v1.1 has only
the schema enum `quality: standard | high`; there is no capability endpoint (gap
G1).

## Decision
Read `GET /v1/app/config` `config.mv.qualities` (app_config's remote config,
fail-open, like `wav_export`). Absent or unreadable = standard only, and the hub
shows no quality choice and sends no `quality`. Unknown values are ignored;
standard is always first. The key is proposed to the platform in
backend-contract §7 (G1).
