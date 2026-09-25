# Implementer report: muse P2 independent composite expect

Domain: `tests/architecture_cases.gd::has_targets_at_parity`. Worktree only. HEAD started at `25f3c71`. Production `_visit_targets_at` unchanged. `card_facts` untouched.

## Independent composite expect
Landed. Jacket expected slot/id is derived from `jacket.components` + `Composites.definition(jacket).coverage` minus that slot's `equipment_at`. Selector does not call `targets_at` / `has_targets_at`. Walk still asserted to contain the id; `has_targets_at` true while active, false after disable. Single selector (`_composite_contact_outside_equipment`); no second picker.

Other source-isolation pins kept: hand, link, shoulder, special, connection; predicate still does not call `targets_at`.

## Commits (no push)
- `29d572a` checkpoint(implementer): derive jacket composite expect independently
- (this) `spire-godot/build/implementer-report.md`

## Check
- `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite architecture -TimeoutSeconds 600`
- Exit: 0
- `SUITE RESULT: architecture PASS`
- `PASS: 3863 assertions`
- Summary: `spire-godot/build/checks/20260925T045347985-584/summary.json`
- summary.status: `passed` (before==after; not `source_changed`)
- docs: PASS (35 docs, 2412 refs)

## Unverified
- Not run: equipment / composites / links / shoulder / torso_binding
- Not this slice: card_facts, composites 2/96, hardener 档 2 mutants, UI
- Not claimed clean or hardened
- Count file: `tests/architecture_cases.gd` 2196 lines (project AGENTS.md has no Size and ESM)
- Left unstaged: `spire-godot/build/cleaner-report.md`; untracked `*.uid` not added; no dirty `*.import`
