# Implementer report: keywords() single-collector observation

Domain: `tests/card_text_cases.gd::card_keyword_deps_stable_ids` source-structure gate. HEAD started at `dc2e7f2`. Worktree `C:\1\magic-spire-wt-keyword-deps` only. Bunny P2 #2 closed. Bunny P2 #1 rejected by coordinator: not done.

## Change
`card_keyword_deps_stable_ids` now FileAccess-reads `res://data/card_text.gd`, slices `func keywords(` until the next `func `, strips comments (same pattern as `architecture_cases.gd::pipeline_lookup_func_body` / `pipeline_lookup_call_count`). Asserts `keyword_ids(` count==1 and the body has no `_effect_terms(`, `_buff_terms(`, `unique_face(`, `Rules.exhausts(`, `ids.append`. Existing Gherkin ids/slots/mode/projection/rename/`face_keywords` assertions kept. `Rules.SPECS[type]` follow_through_scope display read is allowed and is not treated as a second ids scan.

Production `keyword_ids` / `keywords()` semantics unchanged. `static var TERMS` unchanged (no const revert, no test seam, no TERMS inject). No `card_facts` / `game.gd` / UI change.

## Commits (no push)
- `523275a` checkpoint(implementer): observe keywords calls keyword_ids once
- (this) `spire-godot/build/implementer-report.md`

## Check
- Command: `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite card_power -TimeoutSeconds 600`
- Exit: 0
- `SUITE RESULT: card_power PASS`
- `PASS: 2297 assertions`
- Summary: `spire-godot/build/checks/20260925T071208916-32260/summary.json`
- summary.status: `passed` (before==after fingerprint; not `source_changed`)
- docs: PASS (35 docs, 2412 refs)
- Existing TERMS / COPY stayed green in the same PASS.

## Unverified
- Not run: architecture / UI / hardener mutations
- Not this slice: bunny P2 #1 TERMS writability, `docs/spec`, `card_facts` consuming `keyword_ids`, T4/T5/delta
- Not claimed clean or hardened
- Size and ESM: not in project AGENTS.md. Touched count: `tests/card_text_cases.gd` 203 lines
