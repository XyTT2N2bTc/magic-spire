# Implementer report: bunny P2 source isolation

Domain: `tests/architecture_cases.gd::has_targets_at_parity`. Worktree only. HEAD started at `01726ed`. Production `_visit_targets_at` unchanged.

## Source isolation
Landed. Public-query true/ID assertions (not the shared-walk oracle alone):
- Hand: one-sided palm/fingers id in `targets_at`; `occupied` stays false
- Link: slot with empty `equipment_at` and nonempty `links_at`; live true; dead that slot false
- Composite: jacket contact id not in `equipment_at(slot)` but in `targets_at`; `has_targets_at` true; disable follows composite
- Shoulder: `has_targets_at("shoulder")` true, `equipment_at` empty, hit `Equipment.is_shoulder`
- Special: slot true; id in `state.special_equipment` / `links_at`
- Connection: `Binding.connections` id in `targets_at`, not in host `equipment_at`

Existing parity kept (predicate does not call `targets_at`; bool equals precomputed oracle; snapshot/rng/order; live/scope/fallback).

## Commits (no push)
- `f35dfc8` checkpoint(implementer): isolate has_targets_at source assertions
- (this) `spire-godot/build/implementer-report.md`

## Check
- `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite architecture -TimeoutSeconds 600`
- Exit: 0
- `SUITE RESULT: architecture PASS`
- `PASS: 3863 assertions`
- Summary: `spire-godot/build/checks/20260925T044053270-7484/summary.json`
- summary.status: `passed` (before==after; not `source_changed`)
- docs: PASS (35 docs, 2412 refs)

## Unverified
- Not run: equipment / composites / links / shoulder / torso_binding
- Not this slice: card_facts, composites 2/96, hardener 档 2 mutants, UI
- Not claimed clean or hardened
- Count file: `tests/architecture_cases.gd` 2195 lines
