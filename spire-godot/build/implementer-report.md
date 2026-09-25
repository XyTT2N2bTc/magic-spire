# Implementer report: card_facts consumes has_targets_at

Domain: `core/card_effects.gd::card_facts` asks `Game.has_targets_at` before `targets_at` on declared slots. HEAD started at `6294f19`. Worktree `C:\1\magic-spire-wt-card-facts-consume` only. Predicate consumption landed.

## Predicate consumption
Landed. Declared empty slots follow the old empty-slot rules (special / shoulder / special slots `continue`; ordinary `targets=[{}]`) and do not call `targets_at`. Slots with targets still collect via `targets_at`; `occupied` only appends `{}` when a slot has targets, is not shoulder, and is not full. No copied `_visit_targets_at` filters; `has_targets_at` is not implemented as `targets_at(slot).is_empty()`. Shared walk in `core/game.gd` unchanged. Production source has no counter.

## Commits (no push)
- `2ee7bc7` checkpoint(implementer): consume has_targets_at in card_facts
- (this) `spire-godot/build/implementer-report.md`

## Check
- Command: `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite architecture -TimeoutSeconds 600`
- Exit: 0
- `SUITE RESULT: architecture PASS`
- `PASS: 4429 assertions`
- Summary: `spire-godot/build/checks/20260925T055947199-28432/summary.json`
- summary.status: `passed` (before==after fingerprint; not `source_changed`)
- docs: PASS (35 docs, 2412 refs)

First import-only attempt failed (`20260925T055704112-5024`, font `.fontdata` missing in a fresh worktree `.godot`). After engine import, `*.import` restored and two untracked `*.uid` files deleted; they were not committed.

## Gherkin
`tests/architecture_cases.gd::card_facts_consumes_has_targets_at` (registered in `run`): `TargetsAtCountingGame.new(42)` battle empty; one-sided palm/fingers (`occupied=false`, piece id in facts); live link covering empty `equipment_at`; dead link; active glove composite; disabled composite; jacket contacts outside `equipment_at`; disabled jacket; linked torso-binding connections (practice factory, same as `has_targets_at_parity`). Cards: `strain` and `slip` (no `target_slots`). Oracle=`card_facts_union_slot_oracle` via `targets_at`. Empty slots absent from `targets_at_slots`; occupied slots still counted; snapshot/rng frozen. `card_facts_declared_slots` stayed in the same architecture PASS.

## Unverified
- Not run: equipment / composites / links / torso_binding suites; hardener mutations
- Not this slice: `docs/spec` dependency write, T4/T5/delta/TERMS/UI
- Not claimed clean or hardened
- Size and ESM: not in project AGENTS.md. Touched counts: `core/card_effects.gd` 1456 lines; `tests/architecture_cases.gd` 2211 lines
