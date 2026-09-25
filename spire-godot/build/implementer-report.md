# Implementer report: bunny P2 all independent jacket composite expects

Domain: `tests/architecture_cases.gd::has_targets_at_parity` / `_composite_contact_outside_equipment`. Worktree only. HEAD started at `029ac58`. Production `_visit_targets_at` unchanged. `card_facts` untouched.

## All-contact pins
Landed. Single selector `_composite_contact_outside_equipment` still derives from `jacket.components` + `Composites.definition(jacket).coverage` minus each slot's `equipment_at`; it returns every independent slot/id pair, not the first sentinel. Selector does not call `targets_at` / `has_targets_at`. Sleeves and hem are each pinned in the expect set from `jacket.components` by part. Walk must contain every returned id on that slot; missing either component (or any coverage-slot pair) goes red. After body durability 0, those slots follow the composite as false.

Other source-isolation pins kept: hand, link, shoulder, special, connection; predicate still does not call `targets_at`.

## Commits (no push)
- `8970595` checkpoint(implementer): pin all independent jacket composite expects
- (this) `spire-godot/build/implementer-report.md`

## Check
- `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite architecture -TimeoutSeconds 600`
- Exit: 0
- `SUITE RESULT: architecture PASS`
- `PASS: 3883 assertions`
- Summary: `spire-godot/build/checks/20260925T051002316-30156/summary.json`
- summary.status: `passed` (before==after; not `source_changed`)
- docs: PASS (35 docs, 2412 refs)

## Unverified
- Not run: equipment / composites / links / shoulder / torso_binding
- Not this slice: card_facts, composites 2/96, hardener 档 2 mutants, UI
- Not claimed clean or hardened
- Count file: `tests/architecture_cases.gd` 2201 lines (project AGENTS.md has no Size and ESM)
- Left untracked: `spire-godot/ui/command_router.gd.uid`, `spire-godot/ui/command_routes.gd.uid` (not added); no dirty `*.import`
